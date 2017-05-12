# $Id: Util.pm,v 1.4 2001/05/22 04:28:00 btrott Exp $

package Net::SFTP::Util;
use strict;

use Net::SFTP::Constants qw( :status );

use vars qw( @ISA @EXPORT_OK );
use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( fx2txt );

use vars qw( %ERRORS );
%ERRORS = (
    SSH2_FX_OK() => "No error",
    SSH2_FX_EOF() => "End of file",
    SSH2_FX_NO_SUCH_FILE() => "No such file or directory",
    SSH2_FX_PERMISSION_DENIED() => "Permission denied",
    SSH2_FX_FAILURE() => "Failure",
    SSH2_FX_BAD_MESSAGE() => "Bad message",
    SSH2_FX_NO_CONNECTION() => "No connection",
    SSH2_FX_CONNECTION_LOST() => "Connection lost",
    SSH2_FX_OP_UNSUPPORTED() => "Operation unsupported",
);

sub fx2txt { exists $ERRORS{$_[0]} ? $ERRORS{$_[0]} : "Unknown status" }

1;
__END__

=head1 NAME

Net::SFTP::Util - SFTP utility methods

=head1 SYNOPSIS

    use Net::SFTP::Util qw( sub_name );

=head1 DESCRIPTION

I<Net::SFTP::Util> provides a set of exportable utility functions
used by I<Net::SFTP> libraries.

=head2 fx2txt($status)

Takes an integer status I<$status> as an argument, and returns
a "friendly" textual message corresponding to that status.
I<$status> should be one of the I<SSH2_FX_*> constants (exported
by I<Net::SSH::Perl::Constants>), perhaps returned from the
SFTP server in a I<SSH2_FXP_STATUS> message.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP manpage for author, copyright, and
license information.

=cut
