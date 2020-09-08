=head1 NAME

Net::Songkick::Artist - Models an artist in the Songkick API

=cut

package Net::Songkick::Artist;

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Moose;

use Net::Songkick::MusicBrainz;
use Net::Songkick::Types;

coerce 'Net::Songkick::Artist',
  from 'HashRef',
  via { Net::Songkick::Artist->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[id displayName uri];

has identifier => (
    is => 'ro',
    isa => 'ArrayRef[Net::Songkick::MusicBrainz]',
);

has onTourUntil => (
    is => 'ro',
    isa => 'Net::Songkick::DateTime',
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

    if (exists $args{identifier}) {
      foreach (@{$args{identifier}}) {
        if (ref $_ ne 'Net::Songkick::MusicBrainz') {
          $_ = Net::Songkick::MusicBrainz->new($_);
        }
      }
    }
    
    if (exists $args{onTourUntil}) {
      $args{onTourUntil} = { date => $args{onTourUntil} };
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
