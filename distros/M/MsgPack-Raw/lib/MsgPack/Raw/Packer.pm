package MsgPack::Raw::Packer;
$MsgPack::Raw::Packer::VERSION = '0.05';
use strict;
use warnings;
use MsgPack::Raw;

=head1 NAME

MsgPack::Raw::Packer - msgpack Packer class

=head1 VERSION

version 0.05

=head1 DESCRIPTION

MessagePack packer

=head1 SYNOPSIS

	use MsgPack::Raw;

	my $packer = MsgPack::Raw::Packer->new;
	my $string = $packer->pack ({ a => 'b', c => [undef, 1, 2, '3']});

=head1 METHODS

=head2 new ( )

Create a new packer.

=head2 pack ( $data )

Pack C<$data> into a msgpack string. Objects other than C<MsgPack::Raw::Bool>
and C<MsgPack::Raw::Ext> cannot be packed.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MsgPack::Raw::Packer
