=head1 NAME

Net::Songkick::Location - Models a location in the Songkick API

=cut

package Net::Songkick::Location;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

coerce 'Net::Songkick::Location',
  from 'HashRef',
  via { Net::Songkick::Location->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[lng lat city];

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
