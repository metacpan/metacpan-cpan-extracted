package PAM::Constants;
{
  $PAM::Constants::VERSION = '0.31';
}

=head1 NAME

PAM::Constants - Module to import constants for use with PAM

=head1 VERSION

version 0.31

=cut

use strict;
use warnings;

use Carp qw(croak);
use Exporter;

use base 'Exporter';

our %EXPORT_TAGS;

$EXPORT_TAGS{'return'} = [ qw(
PAM_SUCCESS
PAM_OPEN_ERR
PAM_SYMBOL_ERR
PAM_SERVICE_ERR
PAM_SYSTEM_ERR
PAM_BUF_ERR
PAM_PERM_DENIED
PAM_AUTH_ERR
PAM_CRED_INSUFFICIENT
PAM_AUTHINFO_UNAVAIL
PAM_USER_UNKNOWN
PAM_MAXTRIES
PAM_NEW_AUTHTOK_REQD
PAM_ACCT_EXPIRED
PAM_SESSION_ERR
PAM_CRED_UNAVAIL
PAM_CRED_EXPIRED
PAM_CRED_ERR
PAM_NO_MODULE_DATA
PAM_CONV_ERR
PAM_AUTHTOK_ERR
PAM_AUTHTOK_RECOVERY_ERR
PAM_AUTHTOK_LOCK_BUSY
PAM_AUTHTOK_DISABLE_AGING
PAM_TRY_AGAIN
PAM_IGNORE
PAM_ABORT
PAM_AUTHTOK_EXPIRED
PAM_MODULE_UNKNOWN
) ];

$EXPORT_TAGS{'return_linux'} = [ qw(
PAM_BAD_ITEM
PAM_CONV_AGAIN
PAM_INCOMPLETE
) ];

$EXPORT_TAGS{'item'} = [ qw(
PAM_SERVICE
PAM_USER
PAM_USER_PROMPT
PAM_TTY
PAM_RUSER
PAM_RHOST
PAM_AUTHTOK
PAM_OLDAUTHTOK
PAM_CONV
) ];

$EXPORT_TAGS{'item_linux'} = [ qw(
PAM_FAIL_DELAY
PAM_XDISPLAY
PAM_XAUTHDATA
PAM_AUTHTOK_TYPE
) ];

$EXPORT_TAGS{'conv'} = [ qw(
PAM_PROMPT_ECHO_OFF
PAM_PROMPT_ECHO_ON
PAM_ERROR_MSG
PAM_TEXT_INFO
) ];

# @{$EXPORT_TAGS{'item_linux'}},
$EXPORT_TAGS{'all'} = [
    @{$EXPORT_TAGS{'return'}},
    @{$EXPORT_TAGS{'item'}},
    @{$EXPORT_TAGS{'conv'}},
    ($^O eq "linux" ? @{$EXPORT_TAGS{'return_linux'}} : ()),
    ($^O eq "linux" ? @{$EXPORT_TAGS{'item_linux'}} : ()),
];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    require PAM;

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&PAM::Constants::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) {
        if ($error =~  /is not a valid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        } else {
            croak $error;
        }
    }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#        if ($] >= 5.00561) {
#            *$AUTOLOAD = sub () { $val };
#        }
#        else {
            *$AUTOLOAD = sub { $val };
#        }
    }
    goto &$AUTOLOAD;
}


1;
