package MsgPack::Raw::Unpacker;
$MsgPack::Raw::Unpacker::VERSION = '0.05';
use strict;
use warnings;
use MsgPack::Raw;

=head1 NAME

MsgPack::Raw::Unpacker - msgpack Unpacker class

=head1 VERSION

version 0.05

=head1 DESCRIPTION

MessagePack Unpacker

=head1 SYNOPSIS

	use MsgPack::Raw;

	my $unpacker = MsgPack::Raw::Unpacker->new;
	$unpacker->feed ($packed);

	my $unpacked = $unpacker->next();

=head1 METHODS

=head2 new( )

Create a new unpacker.

=head2 feed( $data )

Feed C<$data> into the unpacker.

=head2 next( )

Retrieve the next available, unpacked data. If there are no parsed
messages left, this method will return C<undef>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MsgPack::Raw::Unpacker
