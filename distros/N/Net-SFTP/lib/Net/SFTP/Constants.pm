# $Id: Constants.pm,v 1.5 2001/05/15 22:29:16 btrott Exp $

package Net::SFTP::Constants;
use strict;

use vars qw( %CONSTANTS );
%CONSTANTS = (
    'SSH2_FXP_INIT' => 1,
    'SSH2_FXP_VERSION' => 2,
    'SSH2_FXP_OPEN' => 3,
    'SSH2_FXP_CLOSE' => 4,
    'SSH2_FXP_READ' => 5,
    'SSH2_FXP_WRITE' => 6,
    'SSH2_FXP_LSTAT' => 7,
    'SSH2_FXP_FSTAT' => 8,
    'SSH2_FXP_SETSTAT' => 9,
    'SSH2_FXP_FSETSTAT' => 10,
    'SSH2_FXP_OPENDIR' => 11,
    'SSH2_FXP_READDIR' => 12,
    'SSH2_FXP_REMOVE' => 13,
    'SSH2_FXP_MKDIR' => 14,
    'SSH2_FXP_RMDIR' => 15,
    'SSH2_FXP_REALPATH' => 16,
    'SSH2_FXP_STAT' => 17,
    'SSH2_FXP_RENAME' => 18,
    'SSH2_FXP_STATUS' => 101,
    'SSH2_FXP_HANDLE' => 102,
    'SSH2_FXP_DATA' => 103,
    'SSH2_FXP_NAME' => 104,
    'SSH2_FXP_ATTRS' => 105,

    'SSH2_FXF_READ' => 0x01,
    'SSH2_FXF_WRITE' => 0x02,
    'SSH2_FXF_APPEND' => 0x04,
    'SSH2_FXF_CREAT' => 0x08,
    'SSH2_FXF_TRUNC' => 0x10,
    'SSH2_FXF_EXCL' => 0x20,

    'SSH2_FX_OK' => 0,
    'SSH2_FX_EOF' => 1,
    'SSH2_FX_NO_SUCH_FILE' => 2,
    'SSH2_FX_PERMISSION_DENIED' => 3,
    'SSH2_FX_FAILURE' => 4,
    'SSH2_FX_BAD_MESSAGE' => 5,
    'SSH2_FX_NO_CONNECTION' => 6,
    'SSH2_FX_CONNECTION_LOST' => 7,
    'SSH2_FX_OP_UNSUPPORTED' => 8,

    'SSH2_FILEXFER_ATTR_SIZE' => 0x01,
    'SSH2_FILEXFER_ATTR_UIDGID' => 0x02,
    'SSH2_FILEXFER_ATTR_PERMISSIONS' => 0x04,
    'SSH2_FILEXFER_ATTR_ACMODTIME' => 0x08,
    'SSH2_FILEXFER_ATTR_EXTENDED' => 0x80000000,

    'SSH2_FILEXFER_VERSION' => 3,
);

use vars qw( %TAGS );
my %RULES = (
    '^SSH2_FXP'    => 'fxp',
    '^SSH2_FXF'    => 'flags',
    '^SSH2_FILEXFER_ATTR' => 'att',
    '^SSH2_FX_' => 'status',
);

for my $re (keys %RULES) {
    @{ $TAGS{ $RULES{$re} } } = grep /$re/, keys %CONSTANTS;
}

sub import {
    my $class = shift;

    my @to_export;
    my @args = @_;
    for my $item (@args) {
        push @to_export,
            $item =~ s/^:// ? @{ $TAGS{$item} } : $item;
    }

    no strict 'refs';
    my $pkg = caller;
    for my $con (@to_export) {
        warn __PACKAGE__, " does not export the constant '$con'"
            unless exists $CONSTANTS{$con};
        *{"${pkg}::$con"} = sub () { $CONSTANTS{$con} }
    }
}

1;
__END__

=head1 NAME

Net::SFTP::Constants - Exportable SFTP constants

=head1 SYNOPSIS

    use Net::SFTP::Constants qw( :tag CONSTANT );
    print "Constant value is ", CONSTANT;

=head1 DESCRIPTION

I<Net::SFTP::Constants> provides a list of exportable SFTP
constants: for SFTP messages and commands, for file-open flags,
for status messages, etc. Constants can be exported individually,
or in sets identified by tag names.

I<Net::SFTP::Constants> provides values for all of the constants
listed in the SFTP protocol version 3 draft; the only thing to
note is that the constants are listed with the prefix I<SSH2>
instead of I<SSH>. So, for example, to import the constant for
the file-open command, you would write:

    use Net::SFTP::Constants qw( SSH2_FXP_OPEN );

=head1 TAGS

As mentioned above, constants can either be imported individually
or in sets grouped by tag names. The tag names are:

=over 4

=item * fxp

Imports all of the I<SSH2_FXP_*> constants: these are the
constants used in the messaging protocol.

=item * flags

Imports all of the I<SSH2_FXF_*> constants: these are constants
used as flags sent to the server when opening files.

=item * att

Imports all of the I<SSH2_FILEXFER_ATTR_*> constants: these are
the constants used to construct the flag in the serialized
attributes. The flag describes what types of file attributes
are listed in the buffer.

=item * status

Imports all of the I<SSH2_FX_*> constants: these are constants
returned from a server I<SSH2_FXP_STATUS> message and indicate
the status of a particular operation.

=back

There is one constant that does not fit into any of the
tag sets: I<SSH2_FILEXFER_VERSION>, which holds the value
of the SFTP protocol implemented by I<Net::SFTP>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP manpage for author, copyright, and
license information.

=cut
