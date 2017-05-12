package Net::SFTP::Server::Constants;

use strict;
use warnings;
use Scalar::Util qw(dualvar);

my %constants = ( SSH_FXP_INIT => 1,
		  SSH_FXP_VERSION => 2,
		  SSH_FXP_OPEN => 3,
		  SSH_FXP_CLOSE => 4,
		  SSH_FXP_READ => 5,
		  SSH_FXP_WRITE => 6,
		  SSH_FXP_LSTAT => 7,
		  SSH_FXP_FSTAT => 8,
		  SSH_FXP_SETSTAT => 9,
		  SSH_FXP_FSETSTAT => 10,
		  SSH_FXP_OPENDIR => 11,
		  SSH_FXP_READDIR => 12,
		  SSH_FXP_REMOVE => 13,
		  SSH_FXP_MKDIR => 14,
		  SSH_FXP_RMDIR => 15,
		  SSH_FXP_REALPATH => 16,
		  SSH_FXP_STAT => 17,
		  SSH_FXP_RENAME => 18,
		  SSH_FXP_READLINK => 19,
		  SSH_FXP_SYMLINK => 20,
		  SSH_FXP_STATUS => 101,
		  SSH_FXP_HANDLE => 102,
		  SSH_FXP_DATA => 103,
		  SSH_FXP_NAME => 104,
		  SSH_FXP_ATTRS => 105,
		  SSH_FXP_EXTENDED => 200,
		  SSH_FXP_EXTENDED_REPLY => 201,

		  SSH_FX_OK => 0,
		  SSH_FX_EOF => 1,
		  SSH_FX_NO_SUCH_FILE => 2,
		  SSH_FX_PERMISSION_DENIED => 3,
		  SSH_FX_FAILURE => 4,
		  SSH_FX_BAD_MESSAGE => 5,
		  SSH_FX_NO_CONNECTION => 6,
		  SSH_FX_CONNECTION_LOST => 7,
		  SSH_FX_OP_UNSUPPORTED => 8,

		  SSH_FILEXFER_ATTR_SIZE => 1,
		  SSH_FILEXFER_ATTR_UIDGID => 2,
		  SSH_FILEXFER_ATTR_PERMISSIONS => 4,
		  SSH_FILEXFER_ATTR_ACMODTIME => 8,
		  SSH_FILEXFER_ATTR_EXTENDED => 0x80000000,

		  SSH_FXF_READ => 1,
		  SSH_FXF_WRITE => 2,
		  SSH_FXF_APPEND => 4,
		  SSH_FXF_CREAT => 8,
		  SSH_FXF_TRUNC => 16,
		  SSH_FXF_EXCL => 32);

require constant;
while (my ($k, $v) = each %constants) {
    constant->import($k, dualvar(int $v, $k))
}

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;
$EXPORT_TAGS{fxp} = [grep /^SSH_FXP_/, @EXPORT_OK];
$EXPORT_TAGS{fx} = [grep /^SSH_FX_/, @EXPORT_OK];
$EXPORT_TAGS{filexfer} = [grep /^SSH_FILEXFER_/, @EXPORT_OK];
$EXPORT_TAGS{fxf} = [grep /^SSH_FXF_/, @EXPORT_OK];

1;
