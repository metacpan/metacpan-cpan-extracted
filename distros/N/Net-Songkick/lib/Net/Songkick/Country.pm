=head1 NAME

Net::Songkick::Country - Models a country in the Songkick API

=cut

package Net::Songkick::Country;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

coerce 'Net::Songkick::Country',
  from 'HashRef',
  via { Net::Songkick::Country->new($_) };

has displayName => (
    is => 'ro',
    isa => 'Str',
);

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
