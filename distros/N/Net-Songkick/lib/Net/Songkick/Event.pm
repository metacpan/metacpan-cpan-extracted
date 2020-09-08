=head1 NAME

Net::Songkick::Event - Models an event in the Songkick API

=cut

package Net::Songkick::Event;

use strict;
use warnings;

use Moose;
use DateTime;

use Net::Songkick::Types;
use Net::Songkick::Location;
use Net::Songkick::Performance;
use Net::Songkick::Venue;

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw(type status uri displayName popularity id ageRestriction);

has location => (
    is => 'ro',
    isa => 'Net::Songkick::Location',
    coerce => 1,
);

has performance => (
    is => 'ro',
    isa => 'ArrayRef[Net::Songkick::Performance]',
);

has start => (
    is => 'ro',
    isa => 'Net::Songkick::DateTime',
    coerce => 1,
);

has end => (
    is => 'ro',
    isa => 'Net::Songkick::DateTime',
    coerce => 1,
);

has venue => (
    is => 'ro',
    isa => 'Net::Songkick::Venue',
    coerce => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %args;

    if (@_ == 1) {
        %args = %{$_[0]};
    } else {
        %args = @_;
    }

    if (exists $args{start} and not $args{start}) {
        $args{start} = DateTime->new_from_epoch(epoch => 0);
    }

    if (exists $args{performance}) {
      foreach (@{$args{performance}}) {
        if (ref $_ ne 'Net::Songkick::Performance') {
          $_ = Net::Songkick::Performance->new($_);
        }
      }
    }
    
    $class->$orig(\%args);
};

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1), L<http://www.songkick.com/>, L<http://developer.songkick.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
