package PAX::ProfileStore;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    return bless {
        threshold => $args{threshold} // 2,
        regions => {},
    }, $class;
}

sub record_dispatch {
    my ($self, $event) = @_;
    my $region = $event->{region_name} // $event->{region_id} // 'unknown';
    my $slot = $self->{regions}{$region} ||= {
        dispatches => 0,
        native => 0,
        fallback => 0,
        deopt => 0,
        osr_promotions => 0,
        osr_retirements => 0,
    };
    $slot->{dispatches}++;
    if (($event->{status} // '') eq 'native') {
        $slot->{native}++;
    } elsif (($event->{status} // '') eq 'deopt') {
        $slot->{deopt}++;
        $slot->{fallback}++;
    } else {
        $slot->{fallback}++;
    }
    $slot->{osr_promotions}++ if ($event->{osr_event} // '') eq 'promote';
    $slot->{osr_retirements}++ if ($event->{osr_event} // '') eq 'retire';
    return $slot;
}

sub report {
    my ($self) = @_;
    my @regions;
    for my $name (sort keys %{ $self->{regions} }) {
        my $stats = $self->{regions}{$name};
        push @regions, {
            region => $name,
            %$stats,
            hot => $stats->{dispatches} >= $self->{threshold} ? JSON::PP::true() : JSON::PP::false(),
        };
    }
    return {
        threshold => $self->{threshold},
        regions => \@regions,
    };
}

1;

=pod

=head1 NAME

PAX::ProfileStore - profile persistence layer

=head1 SYNOPSIS

  use PAX::ProfileStore;

  my $obj = PAX::ProfileStore->new(...);
  my $result = $obj->record_dispatch(...);

=head1 DESCRIPTION

Stores and merges lightweight region profiles so build and runtime promotion decisions can reuse earlier observations.

=head1 METHODS

=head2 new, record_dispatch, report

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the profile persistence layer logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs profile persistence layer. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects profile persistence layer, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover profile persistence layer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::ProfileStore -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
