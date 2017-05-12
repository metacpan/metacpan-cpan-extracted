=head1 NAME

Net::Songkick::Artist - Models an artist in the Songkick API

=cut

package Net::Songkick::Artist;

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Moose;

coerce 'Net::Songkick::Artist',
  from 'HashRef',
  via { Net::Songkick::Artist->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[id displayName];

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
