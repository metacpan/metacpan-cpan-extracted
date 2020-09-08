=head1 NAME

Net::Songkick::Venue - Models a venue in the Songkick API

=cut

package Net::Songkick::Venue;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Net::Songkick::City;
use Net::Songkick::MetroArea;

coerce 'Net::Songkick::Venue',
  from 'HashRef',
  via { Net::Songkick::Venue->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[uri lat id lng displayName street zip phone website capacity description];

has city => (
    is => 'ro',
    isa => 'Net::Songkick::City',
    coerce => 1,
);

has metroArea => (
    is => 'ro',
    isa => 'Net::Songkick::MetroArea',
    coerce => 1,
);

# Backwards compatibility
sub metro_area { return $_[0]->metroArea }

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
