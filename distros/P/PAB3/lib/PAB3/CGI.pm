package PAB3::CGI;
# =============================================================================
# Perl Application Builder
# Module: PAB3::CGI
# Use "perldoc PAB3::CGI" for documenation
# =============================================================================

use vars qw(
	$VERSION %HEAD $FIRSTRUN
	%_GET %_POST %_REQUEST %_COOKIE %_FILES
	$HeaderDone $Logger @CleanupHandler
	$MPartBufferSize $MaxBoundary $UploadFileDir $SaveToFile $RequestMaxData
	$TempDir
);

use Carp ();
use Time::HiRes ();

use strict;
no strict 'refs';

our @EXPORT_VAR = qw(
	%_GET %_POST %_REQUEST %_FILES %_COOKIE
);
our @EXPORT_SUB = qw(
	&header &redirect &setcookie &print_r &print_var
	&encode_uri &decode_uri &encode_uri_component &decode_uri_component
);
our @EXPORT_OK = ( @EXPORT_SUB, @EXPORT_VAR );
our @EXPORT = @EXPORT_VAR; # export variables by default
our %EXPORT_TAGS = (
#	'all' => \@EXPORT_OK,
	'default' => \@EXPORT_OK,
#	'var' => \@EXPORT_VAR,
);
require Exporter;
*import = \&Exporter::import;

BEGIN {
	$VERSION = '2.0.1';
	*print_r = \&print_var;
	$GLOBAL::MPREQ = undef;
	$GLOBAL::MODPERL = 0;
	$GLOBAL::MODPERL = 2 if exists $ENV{'MOD_PERL_API_VERSION'}
		&& $ENV{'MOD_PERL_API_VERSION'} == 2;
	$GLOBAL::MODPERL = 1 if ! $GLOBAL::MODPERL && exists $ENV{'MOD_PERL'}
		&& $Apache::VERSION > 1 && $Apache::VERSION < 1.99;
	if( $GLOBAL::MODPERL == 2 ) {
		require mod_perl2;
		require Apache2::Module;
		require Apache2::ServerUtil;
		require Apache2::RequestUtil;
		require APR::Pool;
		require APR::Table;
		require PAB3::CGI::Request;
	}
	elsif( $GLOBAL::MODPERL == 1 ) {
		require Apache;
		require Apache::Log;
		require PAB3::CGI::Request;
	}
	elsif( exists $ENV{'GATEWAY_INTERFACE'}
		&& $ENV{'GATEWAY_INTERFACE'} eq 'CGI-PerlEx'
	) {
		require PAB3::CGI::Request;
	}
	elsif( exists $ENV{'CONTENT_TYPE'}
		&& index( lc( $ENV{'CONTENT_TYPE'} ), 'multipart/form-data' ) >= 0
	) {
		require PAB3::CGI::Request;
	}
	else {
		require PAB3::CGI::RequestStd;
	}
	if( $^O eq 'MSWin32' ) {
		$TempDir = $ENV{'TEMP'}
			? ( $ENV{'TEMP'} . "\\" )
			# CSIDL_WINDOWS (0x0024)
			: ( &Win32::GetFolderPath( 0x0024 ) . "\\Temp\\" )
		;
	}
	else {
		$TempDir = '/tmp/';
	}
	$FIRSTRUN = 1;
}

END {
	if( ! $GLOBAL::MODPERL ) {
		&cleanup();
	}
}

use PAB3::Output::CGI ();

1;

sub _import {
	my $pkg = shift;
	my $callpkg = caller();
	if( $_[0] and $pkg eq __PACKAGE__ and $_[0] eq 'import' ) {
		*{$callpkg . '::import'} = \&import;
		return;
	}
	# export symbols
	foreach( @_ ) {
		if( $_ eq ':default' ) {
			*{$callpkg . '::' . $_} = \%{$pkg . '::' . $_} foreach @EXPORT_SUB;
		}
	}
	*{$callpkg . '::' . $_} = \%{$pkg . '::' . $_} foreach @EXPORT_VAR;
}

sub cleanup {
	return if $FIRSTRUN;
	if( %_FILES ) {
		foreach( keys %_FILES ) {
			unless( $_FILES{$_}->{'tmp_name'} ) {
				next;
			}
			unlink( split( "\0", $_FILES{$_}->{'tmp_name'} ) );
		}
	}
	undef %_GET;
	undef %_POST;
	undef %_REQUEST;
	undef %_FILES;
	undef %_COOKIE;
	undef $HeaderDone;
	undef %HEAD;
	print ''; # untie stdout
	$FIRSTRUN = 1;
	my( $handler, $h, $ref );
	foreach $h( @CleanupHandler ) {
		if( ref( $h ) eq 'ARRAY' ) {
			$handler = shift @$h;
		}
		else {
			$handler = $h;
			$h = [];
		}
		if( ( $ref = ref( $handler ) ) ) {
			if( $ref eq 'CODE' ) {
				eval{
					local( $SIG{'__DIE__'}, $SIG{'__WARN__'} );
					$handler->( @$h );
				};
			}
		}
		else {
			eval{
				local( $SIG{'__DIE__'}, $SIG{'__WARN__'} );
				&{$handler}( @$h );
			};
		}
	}
	undef @CleanupHandler;
	if( $PAB3::Statistic::VERSION ) {
		&PAB3::Statistic::send(
			'CSN|' . ( $GLOBAL::MPREQ || $$ )
				. '|' . time
				. '|' . &microtime()
				. '|' . ( $GLOBAL::STATUS || ( $GLOBAL::MPREQ ? $GLOBAL::MPREQ->status : 200 ) )
		);
	}
	undef $GLOBAL::MPREQ;
}

sub cleanup_register {
	push @CleanupHandler, [ @_ ];
}

sub setenv {
	if( $ENV{'SCRIPT_FILENAME'}
		&& $ENV{'SCRIPT_FILENAME'} =~ /^(.+[\\\/])(.+?)$/
	) {
		$ENV{'SCRIPT_PATH'} = $1;
		$ENV{'SCRIPT'} = $2;
	}
	elsif( $0 =~ /^(.+[\\\/])(.+?)$/ ) {
		$ENV{'SCRIPT_PATH'} = $1;
		$ENV{'SCRIPT'} = $2;
	}
	else {
		$ENV{'SCRIPT_PATH'} = '';
		$ENV{'SCRIPT'} = $0;
	}
	my $hua = lc( $ENV{'HTTP_USER_AGENT'} );
	if( index( $hua, 'win' ) >= 0 ) {
		$ENV{'REMOTE_OS'} = 'windows'
	}
	elsif( index( $hua, 'linux' ) >= 0 ) {
		$ENV{'REMOTE_OS'} = 'linux';
	}
	elsif( index( $hua, 'ppc' ) >= 0 ) {
		$ENV{'REMOTE_OS'} = 'macos';
	}
	elsif( index( $hua, 'freebsd' ) >= 0 ) {
		$ENV{'REMOTE_OS'} = 'freebsd';
	}
	else {
		$ENV{'REMOTE_OS'} = 'unknown';
	}
}

sub set {
	my( $index, $len );
	$len = $#_ + 1;
	for( $index = 0; $index < $len; $index += 2 ) {
		if( $_[ $index ] eq 'request_max_size' ) {
			$RequestMaxData = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'mpart_buffer_size' ) {
			$MPartBufferSize = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'max_boundary' ) {
			$MaxBoundary = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'temp_dir' ) {
			$UploadFileDir = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'save_to_file' ) {
			$SaveToFile = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'logger' ) {
			$Logger = $_[ $index + 1 ];
		}
		elsif( $_[ $index ] eq 'request' ) {
			$GLOBAL::MPREQ = $_[ $index + 1 ];
		}
		else {
#			&Carp::carp( 'Unknown parameter ' . $_[ $index ] );
		}
	}
}

sub init {
	&cleanup() if ! $FIRSTRUN;
	$UploadFileDir = $TempDir;
	$RequestMaxData = 131072;
	$MPartBufferSize = 8192;
	$MaxBoundary = 10;
	$SaveToFile = 1;
	$Logger = undef;
	$GLOBAL::MPREQ = undef;
	&set( @_ );
	if( $FIRSTRUN ) {
		$FIRSTRUN = 0;
		if( $GLOBAL::MODPERL ) {
			if( $GLOBAL::MODPERL == 2 ) {
				$GLOBAL::MPREQ ||= Apache2::RequestUtil->request();
				$GLOBAL::MPREQ->pool->cleanup_register( \&cleanup );
				if( $GLOBAL::MPREQ->handler() eq 'modperl' ) {
					tie *STDIN, $GLOBAL::MPREQ;
				}
			}
			elsif( $GLOBAL::MODPERL == 1 ) {
				$GLOBAL::MPREQ ||= Apache->request();
				$GLOBAL::MPREQ->register_cleanup( \&cleanup );
			}
			if( $PAB3::Statistic::VERSION ) {
				my $r = $GLOBAL::MPREQ;
				my $s = $r->server();
				my $s2 = $GLOBAL::MODPERL == 2
					? Apache2::ServerUtil->server()
					: $r->server()
				;
				my $c = $r->connection();
				&PAB3::Statistic::send(
					'ISN|' . $r
						. '|' . time
						. '|' . &microtime()
						. '|' . $s->server_hostname
						. '|' . ( $s->port || $s2->port )
						. '|' . $s->is_virtual
						. '|' . $r->document_root
						. '|' . $r->uri
						. '|' . ( $c->remote_host || $c->remote_ip )
						. '|' . $GLOBAL::MODPERL
				);
			}
		}
		else {
			my $iru = index( $ENV{'REQUEST_URI'}, '?' );
			if( $PAB3::Statistic::VERSION ) {
				&PAB3::Statistic::send(
					'ISN|' . $$
						. '|' . time
						. '|' . &microtime()
						. '|' . $ENV{'SERVER_NAME'}
						. '|' . $ENV{'SERVER_PORT'}
						. '|' . '2'
						. '|' . $ENV{'DOCUMENT_ROOT'}
						. '|' . ( $iru > 0 ? substr( $ENV{'REQUEST_URI'}, 0, $iru ) : $ENV{'REQUEST_URI'} )
						. '|' . $ENV{'REMOTE_ADDR'}
						. '|' . '0'
				);
			}
		}
		%HEAD = ();
		$HeaderDone = 0;
		tie *STDOUT, 'PAB3::Output::CGI';
		$SIG{'__DIE__'} = \&_die_handler;
		$SIG{'__WARN__'} = \&_warn_handler;
		&_parse_cookie();
		&_parse_request();
	}
	return 1;
}

sub setcookie {
	my( $name, $value, $expire, $path, $domain, $secure ) = @_;
	unless( $name ) {
		&Carp::croak(
			'Usage: setcookie( $name [, $value [, $expire [, $path [, $domain'
			. ' [, $secure ]]]]] )'
		);
	}
	if( $HeaderDone ) {
		&Carp::carp(
			'CGI Headers already sent at '
				. $HeaderDone->[1] . ':' . $HeaderDone->[2]
		);
		return 0;
	}
	if( $domain ) {
		my $suffix = substr( $domain, rindex( $domain, '.' ) + 1 );
		my $len = length( $suffix );
		if( $suffix !~ /\d{$len}|com|net|org/i && $domain !~ /^\./ ) {
			$domain = '.' . $domain;
		}
	}
	if( defined $expire && $expire > 0 ) {
		my @t = split( / +/, gmtime( $expire ) );
		push @t, split( /:/, $t[3] );
		$expire = $t[0] . ', ' . $t[2] . '-' . $t[1] . '-' .
			$t[4] . ' ' . $t[5] . ':' . $t[6] . ':' . $t[7] .
			' GMT';
	}
	if( $value ) {
		$value =~ s/([^0-9A-z]{1})/"%".unpack("H2",$1)/ge;
	}
	$name =~ s/([^0-9A-z]{1})/"%".unpack("H2",$1)/ge;
	&header(
		'Set-Cookie: ' . $name . '='
		. ( defined $value ? '"' . $value . '";' : ';' )
		. ( defined $expire ? ' Expires="' . $expire . '";' : '' )
		. ( $domain ? ' Domain="' . $domain . '";' : '' )
		. ( $path ? ' Path="' . $path . '";' : '' )
		. ( $secure ? ' Secure="1";' : '' )
		. ' Version="1";'
		. "\n\r"
	) or return 0;
	return 1;
}

sub redirect {
	my( $location, $params, $internal ) = @_;
	if( ! $location ) {
		&Carp::croak(
			'Usage: &PAB3::CGI::redirect( $location [, \%params [, $internal ] ] )'
		);
	}
	if( defined $params && ref( $params ) eq 'HASH' ) {
		my( $index );
		if( $location && index( $location, '?' ) >= 0 ) {
			$location .= '&';
			$index = 1;
		}
		else {
			$location .= '?';
			$index = 0;
		}
		foreach( keys %$params ) {
			$location .= '&' if $index ++ > 0;
			$location .= $_ . '=' . &encode_uri_component( $params->{$_} );
		}
	}
	&header( 'Status: 302 Moved' );
	&header(
		$internal && $GLOBAL::MPREQ
			? 'intredir: ' . $location
			: 'Location: ' . $location
	);
	print '';
	return 302;
}

sub header {
	# my( $header, $replace ) = @_;
	my( $key, $val, $k );
	if( $HeaderDone ) {
		&Carp::carp(
			'CGI Headers already sent at '
				. $HeaderDone->[1] . ':' . $HeaderDone->[2]
		);
	}
	if( $_[0] =~ m!^HTTP/\d+\.\d+\s+(\d+\s*.*)!i ) {
		&header( "Status: $1", $_[1] );
	}
	( $key, $val ) = $_[0] =~ m!^\s*([\w\-\_]+)\s*?\:\s*(.+)! or return;
	$k = lc( $key );
	if( ! defined $_[1] || $_[1] || ! defined $HEAD{$k} ) {
		$HEAD{$k} = $val;
	}
	elsif( defined $HEAD{$k} ) {
		$HEAD{$k} = [ $HEAD{$k} ] if ! ref( $HEAD{$k} );
		push @{ $HEAD{$k} }, $val;
	}
}

sub print_hash {
	my( $hashname, $ref_table, $level ) = @_;
	my( $r_hash, $r, $k );
	$ref_table ||= [];
	if( $hashname =~ /HASH\(0x\w+\)/ ) {
		$r_hash = $hashname;
	}
	else {
		return;
	}
	print $r_hash;
	if( $ref_table->{$r_hash} && $ref_table->{$r_hash} <= $level ) {
		print " [recursive loop]\n";
		return;
	}
	print "\n", "    " x $level, "(\n";
	$ref_table->{$r_hash} = $level + 1;
	foreach $k( sort { lc( $a ) cmp lc( $b ) } keys %{ $r_hash } ) {
		print "    " x ( $level + 1 ) . "[$k] => ";
		$r = ref( $r_hash->{$k} );
		if( $r && index( $r_hash->{$k}, 'ARRAY(' ) >= 0 ) {
			&print_array( $r_hash->{$k}, $ref_table, $level + 1 );
		}
		elsif( $r && index( $r_hash->{$k}, 'HASH(' ) >= 0 ) {
			&print_hash( $r_hash->{$k}, $ref_table, $level + 1 );
		}
		else {
			print ( ! defined $r_hash->{$k} ? '(null)' : $r_hash->{ $k } );
			print "\n";
		}
	}
	print "    " x $level, ")\n";
}

sub print_array {
	my( $arrayname, $ref_table, $level ) = @_;
	my( $r_array, $r, $v, $i );
	$ref_table ||= {};
	$level ||= 0;
	if( $arrayname =~ /ARRAY\(0x\w+\)/ ) {
		$r_array = $arrayname;
	}
	else {
		return;
	}
	print $r_array;
	if( $ref_table->{$r_array} && $ref_table->{$r_array} <= $level ) {
		print " [recursive loop]\n";
		return;
	}
	print "\n", "    " x $level, "(\n";
	$ref_table->{$r_array} = $level + 1;
	$i = 0;
	foreach $v( @{ $r_array } ) {
		$r = ref( $v );
		print "    " x ( $level + 1 ) . "[$i] => ";
		if( $r && index( $v, 'ARRAY(' ) >= 0 ) {
			&print_array( $v, $ref_table, $level + 1 );
		}
		elsif( $r && index( $v, 'HASH(' ) >= 0 ) {
			&print_hash( $v, $ref_table, $level + 1 );
		}
		else {
			print "" . ( ! defined $v ? '(null)' : $v ) . "\n";
		}
		$i ++;
	}
	print "    " x $level, ")\n";
}

sub print_var {
	my( $v, $r, $ref_table );
	$ref_table = {};
	print "<pre>\n";
	foreach $v( @_ ) {
		$r = ref( $v );
		if( $r && index( $v, 'ARRAY(' ) >= 0 ) {
			&print_array( $v, $ref_table, 0 );
		}
		elsif( $r && index( $v, 'HASH(' ) >= 0 ) {
			&print_hash( $v, $ref_table, 0 );
		}
		elsif( $r && index( $v, 'SCALAR(' ) >= 0 ) {
			print $$v, "\n";
		}
		else {
			print $v, "\n";
		}
	}
	print "</pre>\n";
}

sub print_code {
	my( $content, $filename ) = @_;
	my( $t, $l, $p );
	return if ! defined $content;
	$content =~ s/\r//go;
	$content =~ s/</&lt;/go;
	$content =~ s/>/&gt;/go;
	#$content =~ s/ /&nbsp;/go;
	print "<table border=1>\n";
	print "<tr><th>$filename</th></tr>\n" if $filename;
	print "<tr><td><pre>\n";
	$p = 1;
	foreach $l( split( /\n/, $content ) ) {
		print $p . "\t" . $l . "\n";
		$p ++;
	}
	print "</pre></td></tr>\n";
	print "</table>\n";
}

sub encode_uri($) {
	my $s = $_[0] or return $_[0];
	$s =~ s/([^A-Za-z0-9\-_.!~*\'()\,\/\?\:\@\&\=\+\$]{1})/sprintf('%%%02X',ord($1))/ge;
	return $s;
}

sub decode_uri($) {
	my $s = $_[0] or return $_[0];
	$s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
	return $s;
}

sub encode_uri_component($) {
	my $s = $_[0] or return $_[0];
	$s =~ s/([^A-Za-z0-9\-_.!~*\'()]{1})/sprintf('%%%02X',ord($1))/ge;
	return $s;
}

sub decode_uri_component($) {
	my $s = $_[0] or return $_[0];
	$s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
	return $s;
}

sub microtime {
	my( $sec, $usec ) = &Time::HiRes::gettimeofday();
	return $sec + $usec / 1000000;
}

sub _parse_cookie {
	my( $key, $val, $i, @in, $iv );
	%_COOKIE = ();
	return 1 unless defined $ENV{'HTTP_COOKIE'};
	@in = split( /; */, $ENV{'HTTP_COOKIE'} );
	for $i( 0 .. $#in ) {
		$iv = index( $in[$i], '=' );
		if( $iv > 0 ) {
			$key = substr( $in[$i], 0, $iv );
			$val = substr( $in[$i], $iv + 1 );
			$key =~ tr/+/ /;
			$key =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;
			if( $val ) {
				$val =~ s!\"!!gso;
				#$val =~ s/^\"(.+)\"$/$1/;
				$val =~ tr/+/ /;
				$val =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;
			}
			$_COOKIE{ $key } = defined $_COOKIE{ $key } ? "\0" . $val : $val;
		}
		else {
			$_COOKIE{ $in[$i] } .= defined $_COOKIE{ $in[$i] } ? "\0" : "";
		}
	}
	return 1;
}

sub _die_handler {
	my $str = shift;
	my( @c, $step );
	if( $str =~ /(.+) at (.+) line (.+)$/s ) {
		print "<br />\n<code>Fatal:\n"
			. "<p><font size=\"+2\"><b>$1</b></font></p>\n"
			. 'at <b>' . $2 . '</b> line <b>' . $3 . '</b>'
			. "<br />\n"
		;
	}
	else {
		print "<br />\n<code>Fatal:\n"
			. '<p><font size="+2"><b>' . $str . "</b></font></p><br />\n"
		;
	}
	@c = caller();
	print "<ul>\n";
	print '<li>'
		. '<b>' . $c[0] . '</b> raised <b>the exception</b>'
		. ' at <b>'	. $c[1] . '</b> line <b>' . $c[2] . '</b>'
		. "</li>\n"
	;
	$step = 1;
	while( @c = caller( $step ) ) {
		print '<li>'
			. '<b>' . $c[0] . '</b> called <b>' . $c[3] . '</b>'
			. ' at <b>' . $c[1] . '</b> line <b>' . $c[2] . '</b>'
			. "</li>\n"
		;
		$step ++;
	}
	print "</ul>\n";
	print "</code><br />\n";
	my $s = $str;
	$s =~ s!\n+$!!;
	if( $Logger ) {
		$Logger->error( $s );
	}
	if( $GLOBAL::MPREQ ) {
		$GLOBAL::MPREQ->log()->error( $s );
		#$GLOBAL::MPREQ->status( 500 );
		$GLOBAL::STATUS = 500;
		Apache::exit() if $GLOBAL::MODPERL == 1;
	}
	else {
		print STDERR '[error] Perl: ' . $str;
	}
#	return 500;
	exit( 0 );
}

sub _warn_handler {
	my $str = shift;
	if( $str =~ /(.+) at (.+) line (.+)$/s ) {
		print "<br />\n<code>Warning: <b>$1</b>\n"
			. 'at <b>' . $2 . '</b> line <b>' . $3 . '</b>'
			. "</code>\n<br />\n"
		;
	}
	else {
		print "<br />\n<code>Warning: <b>$str</p></code>\n<br />\n";
	}
	my $s = $str;
	$s =~ s!\n+$!!;
	if( $Logger ) {
		$Logger->warn( $s );
	}
	if( $GLOBAL::MPREQ ) {
		$GLOBAL::MPREQ->log()->warn( $s );
	}
	else {
		print STDERR '[warn] Perl: ' . $str;
	}
}


__END__

=head1 NAME

PAB3::CGI - CGI module for the PAB3 environment or as standalone

=head1 SYNOPSIS

  # load module and export default functions and variables
  use PAB3::CGI qw(:default);
  
  # set some useful variables to the environment
  PAB3::CGI::setenv();
  
  # parse request and cookies and start the cgi output handler
  PAB3::CGI::init();
  
  if( $_REQUEST{'cmd'} eq 'showenv' ) {
      print_var( \%ENV );
  }
  elsif( $_REQUEST{'cmd'} eq 'redirect' ) {
      return redirect( 'http://myserver.com/' );
  }


=head1 DESCRIPTION

PAB3::CGI handles CGI requests.
Some syntax is taken from PHP.
Multipart content is based on the cgi-lib. Thank you for the great work.

=head1 EXAMPLES

=head2 Standard CGI output

  # load module and export default functions and variables
  use PAB3::CGI qw(:default);
  
  # parse request and cookies and start the cgi output handler
  PAB3::CGI::init();
  
  # start data output
  print "<h1>Environment</h1>\n";
  
  # print a human readable version of %ENV
  print_var( \%ENV );


=head2 CGI output with HTTP headers

  # load module and export default functions and variables
  use PAB3::CGI qw(:default);
  
  # parse request and cookies and start the cgi output handler
  PAB3::CGI::init();
  
  # set userdefined header
  header( "Content-Type: text/plain" );
  
  # start data output
  print "plain text comes here\n";


=head1 METHODS

=over 4

=item init ( [%ARG] )

Initializes the CGI environment, parses request and cookies.

Available arguments are:

  request_max_size   => maximum allowed data to be sent to the server,
                        default value is 131072 (128kb)
  mpart_buffer_size  => size of buffer for reading files sent to
                        the server, default is 8192 (8kb)
  max_boundary       => maximum length of boundary in multipart
                        content, default is 10
  temp_dir           => directory to upload temporary files,
                        default value is '/tmp' on unix and %WINDOWS%\\Temp on
                        Win32
  save_to_file       => if TRUE, save uploaded files to disk
                        if FALSE, hold uploaded files in memory
                        default is TRUE

Example:

  PAB3::CGI::init();


=item setenv ()

Set some useful variables to the interpreters environment 

these variables are:

  $ENV{'SCRIPT_PATH'}   : path to the main script
  $ENV{'SCRIPT'}        : name of the main script
  $ENV{'REMOTE_OS'}     : name of the remote operating system


=item setcookie ( $name )

=item setcookie ( $name, $value )

=item setcookie ( $name, $value, $expire )

=item setcookie ( $name, $value, $expire, $path )

=item setcookie ( $name, $value, $expire, $path, $domain )

=item setcookie ( $name, $value, $expire, $path, $domain, $secure )


setcookie() defines a cookie to be sent along with the rest of the
HTTP headers. Like other headers, cookies must be sent before any
other output. If output exists prior to calling this function,
setcookie() will fail and return 0. If setcookie() successfully runs,
it will return a true value. This does not indicate whether the remote
user accepted the cookie.
The first parameter I<$name> defines the name of the cookie. The
second parameter I<$value> is stored on the clients computer. The
third parameter defines the time the cookie expires. This is a Unix
timestamp as number of seconds since the epoch. If I<$expire> is
undefined, the cookie will expire at the end of the session.
The fourth parameter I<$path> defines the path on the server in which
the cookie will be available on. If path set to '/', the cookie will be
available within the entire domain. If set to '/foo/', the cookie
will only be available within the /foo/ directory and all sub-
directories such as /foo/bar/ of domain. The default value is '/'.
The fifth parameter I<$domain> defines the domain that the cookie
is available. To make the cookie available on all subdomains of
example.com then you would set it to '.example.com'. The . is not
required but makes it compatible with more browsers. Setting it to
www.example.com will make the cookie only available in the www
subdomain. The sixth parameter indicates that the cookie should
only be transmitted over a secure HTTPS connection. When set to
TRUE, the cookie will only be set if a secure connection exists.
The default is FALSE.


=item header ( $header )

=item header ( $header, $overwrite )

header() is used to send raw HTTP headers. See the
http://www.faqs.org/rfcs/rfc2616 specification for more
information on HTTP headers.

Example:

  use PAB3::CGI qw(:default);
  
  # We'll be outputting a PDF
  header( 'Content-type: application/pdf' );
  # It will be called downloaded.pdf
  header( 'Content-Disposition: attachment; filename="downloaded.pdf"' );
  # Setting transfer encoding to binary
  header( 'Content-Transfer-Encoding: binary' );
  # Setting content length
  header( 'Content-Length: ' . ( -s 'original.pdf' ) );
  # Force proxies and clients to disable caching
  header( 'Pragma: no-cache, must-revalidate' );
  # Content expires now
  header( 'Expires: 0' );
  
  # Send the PDF to STDOUT
  open( FH '<original.pdf' );
  binmode( FH );
  while( read( FH, $buf, 8192 ) ) {
      print $buf;
  }
  close( FH );


=item redirect ( $location )

=item redirect ( $location, \%params )

=item redirect ( $location, \%params, $internal )

Redirects the client to I<$location>. Optionally parameters can be
defined in I<\%params>. Inside modperl you can use an internal
redirect by setting I<$internal> to a TRUE value.

Example:

  &PAB3::CGI::redirect(
      'http://www.myserver.com/myscript',
      {
          'run' => 'login',
      }
  );


=item encode_uri_component ( $uri )

encode_uri_component escapes all characters except the following:

  alphabetic, decimal digits, - _ . ! ~ * ' ( ) 

For security reasons, you should call encode_uri_component() on any user-entered
parameters that will be passed as part of a URI. For example, a user could
type "Thyme &time=again" for a variable comment. Not using encode_uri_component
on this variable will give comment=Thyme%20&time=again. Note that the
ampersand and the equal sign mark a new key and value pair. So instead
of having a POST comment key equal to "Thyme &time=again", you have two
POST keys, one equal to "Thyme " and another (time) equal to again.

B<Example>

  $uri = 'http://www.myserver.com/myscript?get='
      . encode_uri_component( 'My+Special&Designed:Argument' )
  ;


=item decode_uri_component ( $uri )

Decodes a Uniform Resource Identifier (URI) component previously created by
encode_uri_component() or by a similar routine. 

Replaces each escape sequence in the encoded URI component with the character
that it represents.


=item encode_uri ( $uri )

Assumes that the URI is a complete URI, so does not encode reserved characters
that have special meaning in the URI. 

encode_uri() replaces all characters except the following with the appropriate
UTF-8 escape sequences: 

  Reserved characters   |  ; , / ? : @ & = + $
  ----------------------+-----------------------------------------------------
  Unescaped characters  |  alphabetic, decimal digits, - _ . ! ~ * ' ( )
  ----------------------+-----------------------------------------------------
  Score                 |  #

Note that encode_uri() by itself cannot form proper HTTP GET and POST requests,
because "&", "+", and "=" are not encoded, which are treated as special
characters in GET and POST requests.
L<encode_uri_component()|PAB3::CGI/encode_uri_component>, however, does
encode these characters.


=item decode_uri ( $uri )

Replaces each escape sequence in the encoded URI with the character that
it represents. 

Does not decode escape sequences that could not have been introduced by
L<encode_uri()|PAB3::CGI/encode_uri>. 


=item print_var ( ... )

=item print_r ( ... )

Prints human-readable information about one or more variables 

Example:

  &PAB3::CGI::print_r( \%ENV );


=item cleanup ()

Cleanup the PAB3::CGI environment, delete uploaded files and call the callback
functions registered by L<cleanup_register()|PAB3::CGI/cleanup_register>.

cleanup() is called internally at the END block or inside ModPerl as cleanup
callback at the end of each request. In other environments, like PerlEx or FastCGI,
that do not support cleanup mechanism you need to call it at the end of
your script.

=item cleanup_register ( $callback )

=item cleanup_register ( $callback, @arg )

Register cleanup callback to run

B<Parameters>

I<$callback>

A cleanup callback CODE reference or just a name of the subroutine
(fully qualified unless defined in the current package).

I<@arg>

If this optional arguments are passed, the $callback function will receive it as
the arguments when executed.


=back

=head1 VARIABLES

=over 4

=item %_COOKIE

The hash %_COOKIE contains the cookies provided to the script via HTTP
cookies.


=item %_GET

The hash %_GET contains the arguments provided to the script via
GET input mechanismus. When running on the command line, this
will also include the @ARGV entries.


=item %_POST

The hash %_POST contains the arguments provided to the script via
POST input mechanismus.


=item %_REQUEST

The hash %_REQUEST contains the arguments provided to the script via
GET and POST input mechanismus. When running on the command line, this
will also include the @ARGV entries.


=item %_FILES

%_FILES is available in a multipart request. It contains the content
or the temporary filename, the content-type, remote-filename and the
content-length of uploaded files.

The following parameters are defined:

  name          => contains the remote filename
  size          => size of content
  type          => contains the content-type of the uploaded file
  tmp_name      => contains the temporary filename on the server


=back

=head1 EXPORTS

By default the variables %_COOKIE, %_GET, %_POST, %_REQUEST and %_FILES are
exported. To export variables and functions you can use the export
tag ':default'.

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::CGI module is free software. You may distribute under the
terms of either the GNU General Public License or the Artistic
License, as specified in the Perl README file.

=cut
