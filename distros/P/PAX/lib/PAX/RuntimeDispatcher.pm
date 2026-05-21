package PAX::RuntimeDispatcher;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();
use PAX::Capture;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::GuardManager;
use PAX::HotRegionJIT;
use PAX::InlineCache;
use PAX::OSR;
use PAX::ProfileGuidedAOT;
use PAX::ProfileStore;
use PAX::Tier1;
use PAX::NativeRunner;

sub new {
    my ($class, %args) = @_;
    return bless {
        mode => $args{mode} // 'live',
        profile_store => $args{profile_store} // PAX::ProfileStore->new(threshold => $args{threshold} // 2),
        inline_cache => $args{inline_cache} // PAX::InlineCache->new,
        hot_region_jit => $args{hot_region_jit} // PAX::HotRegionJIT->new(threshold => $args{threshold} // 2),
        osr => $args{osr} // PAX::OSR->new(threshold => $args{threshold} // 2),
        aot => $args{aot} // PAX::ProfileGuidedAOT->new(threshold => $args{threshold} // 2),
    }, $class;
}

sub dispatch_i64 {
    my ($self, %args) = @_;
    my $entrypoint = $args{entrypoint};
    my $region_name = $args{region_name};
    my $left = defined $args{left} ? $args{left} : 0;
    my $right = defined $args{right} ? $args{right} : 0;
    my $cache_site = $args{cache_site} // 'main-dispatch';

    my $capture = PAX::Capture->new(mode => $self->{mode})->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    my $guard_manager = PAX::GuardManager->new(epochs => $manifest->{runtime_epochs});
    my @attempts;

    my @candidate_units = defined $region_name
        ? grep { ($_->{region_name} // '') eq $region_name || ($_->{region_name} // '') eq "main::$region_name" } @$ssa
        : @$ssa;
    my $profile_by_region = _profile_by_region($self->{profile_store}->report);
    my $aot_plan = $self->{aot}->plan(
        manifest => $manifest,
        ssa_units => $ssa,
        profile => $profile_by_region,
    );

    if (defined $region_name && !@candidate_units) {
        my $event = {
            status => 'fallback',
            region_name => $region_name,
            entrypoint => $entrypoint,
            args => [$left + 0, $right + 0],
            reason => "requested region not found: $region_name",
            attempts => [],
            baseline_match => $manifest->{runtime}{baseline_match},
        };
        $self->{profile_store}->record_dispatch($event);
        return $event;
    }

    for my $unit (@candidate_units) {
        my $method = $unit->{region_name} // $region_name // $unit->{region_id};
        my $cache_lookup = $self->{inline_cache}->lookup(
            site => $cache_site,
            class_key => 'main',
            method => $method,
        );
        my $jit = $self->{hot_region_jit}->decision(
            ssa_unit => $unit,
            profile => $profile_by_region->{$method} // {},
        );
        my $osr = $self->{osr}->evaluate(
            ssa_unit => $unit,
            profile => $profile_by_region->{$method} // {},
        );
        my $guard = $guard_manager->validate_or_deopt($unit);
        if ($guard->{status} ne 'native_allowed') {
            my $retirement = $self->{osr}->retirement(
                reason => $guard->{fallback}{reason},
                safepoint => $unit->{deopt}{safepoint},
            );
            push @attempts, {
                region_id => $unit->{region_id},
                region_name => $unit->{region_name},
                status => 'deopt',
                guard => $guard,
                osr => $retirement,
                inline_cache => $cache_lookup,
            };
            $self->{profile_store}->record_dispatch({
                region_id => $unit->{region_id},
                region_name => $unit->{region_name},
                status => 'deopt',
                osr_event => $retirement->{osr_event},
            });
            next;
        }

        my $artifact = PAX::Tier1->new->compile($unit);
        if (($artifact->{entry_kind} // '') !~ /\Anative_i64_(?:leaf|loop)\z/ || !$artifact->{executable_path}) {
            my $cache_update = $self->{inline_cache}->update(
                site => $cache_site,
                class_key => 'main',
                method => $method,
                target_region_id => $unit->{region_id},
                target_region_name => $unit->{region_name},
            );
            push @attempts, {
                region_id => $unit->{region_id},
                region_name => $unit->{region_name},
                status => 'fallback',
                reason => $artifact->{reason},
                artifact => $artifact,
                jit => $jit,
                osr => $osr,
                inline_cache => {
                    lookup => $cache_lookup,
                    update => $cache_update,
                },
            };
            $self->{profile_store}->record_dispatch({
                region_id => $unit->{region_id},
                region_name => $unit->{region_name},
                status => 'fallback',
                osr_event => $osr->{osr_event},
            });
            next;
        }

        my $result = PAX::NativeRunner->new->run_i64_binary(
            path => $artifact->{executable_path},
            left => $left,
            right => $right,
        );

        my $cache_update = $self->{inline_cache}->update(
            site => $cache_site,
            class_key => 'main',
            method => $method,
            target_region_id => $unit->{region_id},
            target_region_name => $unit->{region_name},
        );
        my $event = {
            status => $result->{status} eq 'ok' ? 'native' : 'fallback',
            entrypoint => $entrypoint,
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            args => [$left + 0, $right + 0],
            requested_region => $region_name,
            result => $result,
            artifact => $artifact,
            attempts => \@attempts,
            baseline_match => $manifest->{runtime}{baseline_match},
            jit => $jit,
            osr => $osr,
            inline_cache => {
                lookup => $cache_lookup,
                update => $cache_update,
            },
            aot_plan => $aot_plan,
        };
        $self->{profile_store}->record_dispatch({
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            status => $event->{status},
            osr_event => $osr->{osr_event},
        });
        $event->{aot_plan} = $self->{aot}->plan(
            manifest => $manifest,
            ssa_units => $ssa,
            profile => _profile_by_region($self->{profile_store}->report),
        );
        return $event;
    }

    my $event = {
        status => 'fallback',
        entrypoint => $entrypoint,
        args => [$left + 0, $right + 0],
        requested_region => $region_name,
        reason => 'no native i64 dispatch candidate succeeded',
        attempts => \@attempts,
        baseline_match => $manifest->{runtime}{baseline_match},
        aot_plan => $aot_plan,
    };
    return $event;
}

sub profile_report {
    my ($self) = @_;
    return $self->{profile_store}->report;
}

sub inline_cache_report {
    my ($self) = @_;
    return $self->{inline_cache}->report;
}

sub _profile_by_region {
    my ($report) = @_;
    my %profile;
    for my $region (@{ $report->{regions} // [] }) {
        $profile{$region->{region}} = $region;
    }
    return \%profile;
}

1;

=pod

=head1 NAME

PAX::RuntimeDispatcher - runtime dispatch coordinator

=head1 SYNOPSIS

  use PAX::RuntimeDispatcher;

  my $obj = PAX::RuntimeDispatcher->new(...);
  my $result = $obj->dispatch_i64(...);

=head1 DESCRIPTION

Routes execution between compiled regions, guarded fallbacks, and pure-Perl execution at runtime.

=head1 METHODS

=head2 new, dispatch_i64, profile_report, inline_cache_report

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the runtime dispatch coordinator logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs runtime dispatch coordinator. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects runtime dispatch coordinator, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover runtime dispatch coordinator.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::RuntimeDispatcher -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
