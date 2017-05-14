package OS2::UPM;

require Exporter;
require AutoLoader;
require DynaLoader;
@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = qw(
	UPM_ACTIVE
	UPM_ADMIN
	UPM_ALL
	UPM_BAD_AUTHCHECK
	UPM_BAD_PARAMETER
	UPM_BAD_TYPE
	UPM_CONFIG
	UPM_DNODE
	UPM_DOMAIN
	UPM_DOMAIN_MAX_FORCE
	UPM_DOMAIN_VERBOSE
	UPM_DUP_ULP_ENTRY
	UPM_ERROR_MORE_DATA
	UPM_ERROR_NONVAL_LOGON
	UPM_FAIL_SECURITY
	UPM_FL_DOMVER
	UPM_FL_LOCVER
	UPM_FL_NOVER
	UPM_LOCAL
	UPM_LOCAL_HPFS
	UPM_LOGGED
	UPM_LOGGED_ELSEWHERE
	UPM_LOG_CANCEL
	UPM_LOG_FILE_NOT_FOUND
	UPM_LOG_INPROC
	UPM_MAX_ENT_EXCEEDED
	UPM_MAX_ULP_EXCEEDED
	UPM_NODISK
	UPM_NOMEM
	UPM_NOT_LOGGED
	UPM_OK
	UPM_OPEN_SESSIONS
	UPM_PASSWORD_EXP
	UPM_PRIV_ADMIN
	UPM_PRIV_LOCAL_ADMIN
	UPM_PRIV_USER
	UPM_PROF_NOT_FOUND
	UPM_PWDLEN
	UPM_REMLEN
	UPM_SS_BUSY
	UPM_SS_DEAD
	UPM_SS_PWDEXPWARNING
	UPM_SYS_ERROR
	UPM_UIDLEN
	UPM_ULP_LOADED
	UPM_UNAVAIL
	UPM_USER
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
	local_user
	user_list
	local_logon
	logon
	logoff
	logon_user
	logoff_user
);

sub AUTOLOAD {
    if (@_ > 1) {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD;
    }
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined UPM macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap UPM;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
