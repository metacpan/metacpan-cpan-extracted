# =============================================================================
# Perl Application Builder
# Module: PAB3::ModPerl::Registry
# Use "perldoc PAB3::ModPerl::Registry" for documentation
# =============================================================================
package PAB3::ModPerl::Registry;

use strict;
use warnings;

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.0.1';
	if( exists $ENV{'MOD_PERL_API_VERSION'}
		&& $ENV{'MOD_PERL_API_VERSION'} == 2
	) {
		require Apache2::ServerUtil;
		require Apache2::Response;
		require Apache2::RequestRec;
		require Apache2::RequestUtil;
		require Apache2::RequestIO;
		require Apache2::Log;
		require Apache2::Access;
		
		require APR::Table;
		require APR::Status;
		
		require ModPerl::Util;
		require ModPerl::Global;
	}
	elsif( exists $ENV{'MOD_PERL'} ) {
		require Apache;
		require Apache::Log;
	}
	
	require PAB3;
	require PAB3::CGI;
}

1;

sub handler : method {
    # init modperl handler
    my $class = ( @_ >= 2 ) ? shift : __PACKAGE__;
    my $r = shift;

	if( ! $PAB3::Statistic::VERSION &&
		$r->dir_config->get( 'UseStatistic' )
	) {
		require PAB3::Statistic;
	}

	# set additional variables to the environment
	&PAB3::CGI::setenv();
	
	# parse request and cookies
	&PAB3::CGI::init();
	
	$ENV{'GATEWAY_INTERFACE'} = 'CGI-ModPerl-PAB3';
	
	my $filename = $r->filename();

	my $package = $r->dir_config->get( 'Package' );
	if( ! $package ) {
		$package = __PACKAGE__ . '_' . $filename;
		$package =~ s/\W/_/go;
	}
	
	my $code = <<EOT1;
*{'$package\::_GET'} = \\\%{'PAB3::CGI::_GET'};
*{'$package\::_POST'} = \\\%{'PAB3::CGI::_POST'};
*{'$package\::_REQUEST'} = \\\%{'PAB3::CGI::_REQUEST'};
*{'$package\::_FILES'} = \\\%{'PAB3::CGI::_FILES'};
*{'$package\::_COOKIE'} = \\\%{'PAB3::CGI::_COOKIE'};
*{'$package\::header'} = \\\&{'PAB3::CGI::header'};
*{'$package\::redirect'} = \\\&{'PAB3::CGI::redirect'};
*{'$package\::setcookie'} = \\\&{'PAB3::CGI::setcookie'};
*{'$package\::print_var'} = \\\&{'PAB3::CGI::print_var'};
*{'$package\::print_r'} = \\\&{'PAB3::CGI::print_var'};
*{'$package\::encode_uri'} = \\\&{'PAB3::CGI::encode_uri'};
*{'$package\::decode_uri'} = \\\&{'PAB3::CGI::decode_uri'};
*{'$package\::encode_uri_component'} = \\\&{'PAB3::CGI::encode_uri_component'};
*{'$package\::encode_uri_component'} = \\\&{'PAB3::CGI::encode_uri_component'};
EOT1

	if( -r $filename ) {
		&PAB3::require_and_run( $filename, $package, $code, [ $r ] );
		$r->print( '' );
	}
	else {
		return 410;
	}
}

__END__

=head1 NAME

PAB3::ModPerl::Registry -
Run Perl5 scripts persistently under Apache and mod_perl inside the PAB3 CGI
environment

=head1 SYNOPSIS

  ------------
  mod_perl 1.x
  ------------
  
  # httpd.conf
  PerlModule PAB3::ModPerl::Registry
  Alias /cgi-pab/ /home/httpd/cgi-bin/
  <Location /cgi-pab>
      SetHandler perl-script
      PerlHandler PAB3::ModPerl::Registry
      PerlSendHeader off
      Options +ExecCGI
      # [optional] set a package to run the scripts inside it.
      #   If you are using different packages inside the scripts
      #   all "global" functions and variables will not be available anymore.
      #   Thats because Perl allows only package wide globals.
      #   The option below enables choosing a self defined package without
      #   loosing "global" access to the functions and variables announced here.
      PerlSetVar Package MyPackageName
  </Location>
  
  ------------
  mod_perl 2.x
  ------------
  
  # httpd.conf
  PerlModule PAB3::ModPerl::Registry
  Alias /cgi-pab/ /home/httpd/cgi-bin/
  <Location /cgi-pab>
      SetHandler perl-script
      PerlResponseHandler PAB3::ModPerl::Registry
      PerlOptions -ParseHeaders +GlobalRequest +SetupEnv
      Options +ExecCGI
      # [optional] set a package to run the scripts inside it.
      #   If you are using different packages inside the scripts
      #   all "global" functions and variables will not be available anymore.
      #   Thats because Perl allows only package wide globals.
      #   The option below enables choosing a self defined package without
      #   loosing "global" access to the functions and variables announced here.
      PerlSetVar Package MyPackageName
  </Location>

=head1 DESCRIPTION

URIs in the form of C<http://example.com/cgi-pab/test.pl> will be
compiled as the body of a Perl subroutine and executed. Each child
process will compile the subroutine once and store it in memory. It
will recompile it whenever the script file (e.g. I<test.pl> in our example)
is updated on disk.

Most of L<PAB3::CGI|PAB3::CGI> functions and variables are global to
the environment.

B<Example A:>

  # header is not needed
  # header( 'Content-Type: text/html' );
  print '<b>mod_perl is sweet!</b>!';

B<Example B:>

  header( 'Expires: Mon, 11 Jun 1999 06:00:00 GMT' );
  header( 'Cache-Control: no-cache, must-revalidate' );
  header( 'Pragma: no-cache' ); 
  
  print_r( 'GET:', \%_GET );
  print_r( 'POST:', \%_POST );
  print_r( 'REQUEST:', \%_REQUEST );
  print_r( 'COOKIES:', \%_COOKIE );
  print_r( 'FILES:', \%_FILES );
  
  if( $_GET{'cmd'} eq 'env' ) {
      print_r( 'ENV:', \%ENV );
  }

=head1 ENVIRONMENT

=head2 METHODS

=over

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

  # We'll be outputting a PDF
  &header( 'Content-type: application/pdf' );
  # It will be called downloaded.pdf
  &header( 'Content-Disposition: attachment; filename="downloaded.pdf"' );
  # Setting transfer encoding to binary
  &header( 'Content-Transfer-Encoding: binary' );
  # Setting content length
  &header( 'Content-Length: ' . ( -s 'original.pdf' ) );
  # Force proxies and clients to disable caching
  &header( 'Pragma: no-cache, must-revalidate' );
  # Content expires now
  &header( 'Expires: 0' );
  
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
defined in I<\%params>. You can use the modperl internal
redirect by setting I<$internal> to a TRUE value.

Example:

  &redirect(
      'http://www.myserver.com/myscript',
      {
          'run' => 'login',
      }
  );

=back

=head2 VARIABLES

=over

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

=head1 CAVEATS

From the mod_perl developers:

Each httpd child will compile your script into memory and keep it there, whereas
CGI will run it once, cleaning out the entire process space.  Many times you
have heard "always use C<-w>, always use C<-w> and 'use strict'".
This is more important here than anywhere else!

One note behind:

In a mod_perl environment several scripts may take access to the same instance
of the perl interpreter. All scripts inside this instance are shared. If you
plan changing $GLOBAL::V1 in script A it will also be changed in script B.

=head1 AUTHORS

Christian Mueller.

=head1 SEE ALSO

L<http://perl.apache.org>

L<the PAB3::CGI manpage|PAB3::CGI>

=head1 COPYRIGHT

The PAB3::ModPerl::Registry module is free software. You may distribute under the
terms of either the GNU General Public License or the Artistic
License, as specified in the Perl README file.

=cut
