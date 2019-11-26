package MsgPack::Raw::Bool;
$MsgPack::Raw::Bool::VERSION = '0.05';
use strict;
use warnings;
use MsgPack::Raw;
use overload
	'bool' => sub { ${$_[0]} },
	'0+'   => sub { ${$_[0]} },
	'""'   => sub { ${$_[0]} ? 'true' : 'false' },
    fallback => 1;

=head1 NAME

MsgPack::Raw::Bool - msgpack boolean class

=head1 VERSION

version 0.05

=head1 DESCRIPTION

MessagePack boolean class

=head1 SYNOPSIS

	use MsgPack::Raw;

=head1 METHODS

=head2 true ( )

=cut

sub true
{
	my $value = 1;
	return bless \$value, 'MsgPack::Raw::Bool';
}

=head2 false ( )

=cut

sub false
{
	my $value = 0;
	return bless \$value, 'MsgPack::Raw::Bool';
}

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MsgPack::Raw::Bool
