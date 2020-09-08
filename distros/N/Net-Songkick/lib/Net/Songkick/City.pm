=head1 NAME

Net::Songkick::City - Models a city in the Songkick API

=cut

package Net::Songkick::City;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

use Net::Songkick::Country;

coerce 'Net::Songkick::City',
  from 'HashRef',
  via { Net::Songkick::City->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[displayName id uri];

has country => (
    is => 'ro',
    isa => 'Net::Songkick::Country',
    coerce => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1), L<http://www.songkick.com/>, L<http://developer.songkick.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;