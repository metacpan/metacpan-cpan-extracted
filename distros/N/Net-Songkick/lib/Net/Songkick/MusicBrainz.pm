=head1 NAME

Net::Songkick::City - Models a MusicBrainz identifier in the Songkick API

=cut

package Net::Songkick::MusicBrainz;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

coerce 'Net::Songkick::MusicBrainz',
  from 'HashRef',
  via { Net::Songkick::MusicBrainz->new($_) };

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw[href mbid];

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