=head1 NAME

Net::Songkick::Event - Models a metropolitan area in the Songkick API

=cut

package Net::Songkick::MetroArea;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Net::Songkick::Country;

coerce 'Net::Songkick::MetroArea',
  from 'HashRef',
  via { Net::Songkick::MetroArea->new($_) };


has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[id displayName];

has 'country' => (
    is => 'ro',
    isa => 'Net::Songkick::Country',
    coerce => 1,
);

=head1 AUTHOR

Dave Cross <dave@mag-sol.com>

=head1 SEE ALSO

perl(1), L<http://www.songkick.com/>, L<http://developer.songkick.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

1;
