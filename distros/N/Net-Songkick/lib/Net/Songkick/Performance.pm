=head1 NAME

Net::Songkick::Performance - Models a performance in the Songkick API

=cut

package Net::Songkick::Performance;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

use Net::Songkick::Artist;

coerce 'Net::Songkick::Performance',
  from 'HashRef',
  via { Net::Songkick::Performance->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[displayName billing billingIndex id];

has artist => (
    is => 'ro',
    isa => 'Net::Songkick::Artist',
    coerce => 1,
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
