package OS2::FTP;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	FTPABORT
	FTPCOMMAND
	FTPCONNECT
	FTPDATACONN
	FTPHOST
	FTPLOCALFILE
	FTPLOGIN
	FTPNOPRIMARY
	FTPNOXLATETBL
	FTPPROXYTHIRD
	FTPSERVICE
	FTPSOCKET
	PINGHOST
	PINGPROTO
	PINGRECV
	PINGREPLY
	PINGSEND
	PINGSOCKET
	T_ASCII
	T_BINARY
	T_EBCDIC
);
@EXPORT_OK = qw(ping);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

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
	    die "Your vendor has not defined OS2::FTP macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap OS2::FTP;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
