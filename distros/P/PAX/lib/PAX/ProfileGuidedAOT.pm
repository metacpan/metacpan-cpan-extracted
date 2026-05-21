package PAX::ProfileGuidedAOT;

our $VERSION = '0.031';

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    return bless {
        threshold => $args{threshold} // 2,
    }, $class;
}

sub plan {
    my ($self, %args) = @_;
    my $manifest = $args{manifest} // {};
    my $ssa_units = $args{ssa_units} // [];
    my $profile = $args{profile} // {};
    my @artifacts;

    for my $unit (@$ssa_units) {
        my $name = $unit->{region_name} // $unit->{region_id};
        my $stats = $profile->{$name} // {};
        next if ($stats->{dispatches} // 0) < $self->{threshold};
        next if !$unit->{native_shape} && !$unit->{source}{native_shape};
        push @artifacts, {
            region_id => $unit->{region_id},
            region_name => $unit->{region_name},
            tier => 'tier-1',
            profile_dispatches => $stats->{dispatches},
            cache_key => sha256_hex(join "\0",
                $manifest->{runtime}{pax_abi_stamp} // '',
                $manifest->{source_entrypoint} // '',
                $unit->{region_id} // '',
                $stats->{dispatches} // 0,
            ),
        };
    }

    return {
        status => @artifacts ? 'planned' : 'no_hot_native_regions',
        threshold => $self->{threshold},
        artifacts => \@artifacts,
        provenance => {
            source_entrypoint => $manifest->{source_entrypoint},
            perl_abi_stamp => $manifest->{runtime}{pax_abi_stamp},
            capture_manifest_hash => sha256_hex(JSON::PP->new->canonical(1)->encode($manifest)),
        },
    };
}

1;

=pod

=head1 NAME

PAX::ProfileGuidedAOT - profile-guided ahead-of-time planning helper

=head1 SYNOPSIS

  use PAX::ProfileGuidedAOT;

  my $obj = PAX::ProfileGuidedAOT->new(...);
  my $result = $obj->plan(...);

=head1 DESCRIPTION

Uses stored profiling information to decide which regions deserve ahead-of-time native artifacts during a build.

=head1 METHODS

=head2 new, plan

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the profile-guided ahead-of-time planning helper logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs profile-guided ahead-of-time planning helper. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects profile-guided ahead-of-time planning helper, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover profile-guided ahead-of-time planning helper.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::ProfileGuidedAOT -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
