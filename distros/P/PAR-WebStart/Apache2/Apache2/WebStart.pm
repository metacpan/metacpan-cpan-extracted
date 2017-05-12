package Apache2::WebStart;

use strict;
use warnings;
use Apache2::RequestRec ();                           # $r
use Apache2::Const -compile => qw(OK SERVER_ERROR);   # constants
use Apache2::RequestUtil ();                          # $r->dir_config
use APR::Table ();                                    # dir_config->get
use Apache2::Log ();                                  # log_error
use Apache2::ServerRec ();                            # host_name
use Apache2::RequestIO ();                            # print

our $VERSION = '0.20';

sub handler {
  my $r = shift;
  
  my %config;
  my $host_name = $r->server->server_hostname;
  if (my $port = $r->server->port) {
      $host_name .= ':' . $port unless ($port == 80);
  }

  for my $key (qw(codebase title vendor homepage description main
                  os arch version perl_version no_sign long_opts short_opts)) {
    $config{$key} = $r->dir_config->get('WS_' . $key) || '';
  }

  my $href = sprintf(qq{http://%s%s}, $host_name, $r->unparsed_uri);
  my $codebase = sprintf(qq{http://%s/%s},
                         $host_name, $config{codebase});

  my $homepage;
  if ($config{homepage}) {
    $homepage = ($config{homepage} =~ /^http:/) ? $config{homepage} :
      sprintf(qq{http://%s/%s}, $host_name, $config{homepage});
  }

  my $info = qq{   <information>\n};
  for my $key(qw(title vendor description)) {
    next unless $config{$key};
    $info .= qq{      <$key>$config{$key}</$key>\n};
  }
  if ($homepage) {
    $info .= qq{      <homepage href="$homepage" />\n};
  }
  $info .= qq{   </information>\n};

  my $resources = '    <resources';
  foreach my $key(qw(os arch version perl_version)) {
    next unless $config{$key};
    $resources .= qq{ $key="$config{$key}"};
  }
  $resources .= '>';

  my $security = '';
  if ($config{no_sign}) {
    $security = <<'END';
    <security>
      <allow-unsigned-pars />
    </security>
END
  }
  my @pars = $r->dir_config->get('WS_par');
  unless (@pars) {
    $r->log->error("WebStart: No par files specified");
    return Apache2::Const::SERVER_ERROR;
  }
  my $pars = join "\n", map{qq{      <par href="$_" />}} @pars;

  my $app = '    <application-desc';
  if ($config{main}) {
    $app .= sprintf(qq{ main-par="%s"}, $config{main});
  }
  $app .= '>';

  my @args = $r->dir_config->get('WS_arg');
  if (my $args = $r->args) {
    push @args, parse_args($args);
  }
  my $args = '';
  if (@args) {
    my $prefix = $config{long_opts} ? '--' :
      ($config{short_opts} ? '-' : '');
    $args = join "\n", map{qq{     <argument>$prefix$_</argument>}} @args;
  }

  my @mods = $r->dir_config->get('WS_module');
  my $mods = '';
  if (@mods) {
    $mods = join "\n", map{qq{     <module>$_</module>}} @mods;
  }

  $r->content_type('application/x-perl-pnlp-file');
  $r->headers_out->set('Content-Disposition' => 'inline; filename=resp.pnlp');

  $r->print(<<"END");
<?xml version="1.0" encoding="utf-8"?>
<pnlp spec="0.1"
      codebase="$codebase"
      href="$href">
$info
$security
$resources
      <perlws version="0.1"/>
$pars
   </resources>
$app
$args
$mods
   </application-desc>
</pnlp> 
END

  return Apache2::Const::OK;
}

sub parse_args {
  my $string = shift;
  return unless defined $string;

  return map {
    tr/+/ /;
    s/%([0-9a-fA-F]{2})/pack("C",hex($1))/ge;
    $_;
  } split /[&;]/, $string, -1;
}

1;

__END__

=head1 NAME

Apache2::WebStart - Apache handler for PAR::WebStart

=head1 SYNOPSIS

In F<httpd.conf>,

  PerlModule Apache2::WebStart
  <Location /webstart>
     SetHandler perl-script
     PerlResponseHandler Apache2::WebStart
     PerlSetVar WS_codebase "lib/apps"
     PerlSetVar WS_title "My App"
     PerlSetVar WS_vendor "me.com"
     PerlSetVar WS_homepage "docs/hello.html"
     PerlSetVar WS_description "A Perl WebStart Application"
     PerlSetVar WS_os "MSWin32"
     PerlSetVar WS_no_sign 1
     PerlSetVar WS_par "A.par"
     PerlAddVar WS_par "C.par"
     PerlSetVar WS_main "A"
     PerlSetVar WS_arg "verbose"
     PerlAddVar WS_arg "--debug"
     PerlSetVar WS_long_opts 1
     PerlSetVar WS_module "Tk"
     PerlAddVar WS_module "LWP"
  </Location>

=head1 DESCRIPTION

This module is an Apache (version 2) handler for dynamically
generating C<PNLP> files for C<PAR::WebStart>. See
L<PAR::WebStart::PNLP> for details of the content of a
C<PNLP> files.

=head2 Directives

The following C<PerlSetVar> directives are used to control
the content of the C<PNLP> file; of these, only
at least one C<WS_par> must be specified.

=over

=item C<PerlSetVar WS_codebase "lib/apps">

This specifies the base by which all relative URLs specified
in the PNLP file will be resolved against. If this is not specified,
the default root document directory will be assumed.

=item C<PerlSetVar WS_title "My App">

This specifies the title of the application.

=item C<PerlSetVar WS_vendor "me.com">

This specifies the vendor of the application.

=item C<PerlSetVar WS_homepage "docs/hello.html">

This specifies a link describing further details of the
application; if it does not begin with C<http://>, it will
be assumed to use C<WS_codebase> as the base.

=item C<PerlSetVar WS_description "A Perl WebStart Application">

This specifies a description of the application.

=item C<PerlSetVar WS_os "MSWin32">

This specifies that the application will only run on
machines matching C<$Config{osname}>.

=item C<PerlSetVar WS_arch "MSWin32-x86-multi-thread">

This specifies that the application will only run on
machines matching C<$Config{archname}>.

=item C<PerlSetVar WS_version "5.008006">

This specifies that the minimal perl version required
(as given by C<$]>) to run the application,
and I<must> be given in the form, for example,
C<5.008006> for perl-5.8.6.

=item C<PerlSetVar WS_perl_version "8">

This specifies that the application will only run on
machines matching C<$Config{PERL_VERSION}>.

=item C<PerlSetVar WS_no_sign 1>

If set to a true value, this specifies that the par files
will not be expected to be signed by C<Module::Signature>
(the default value is false, meaning par files are expected
to be signed).

=item C<PerlSetVar WS_par "A.par">

This specifies a C<par> file used within the application;
additional files may be specified by
multiple directives such as C<PerlAddVar WS_par "C.par">.

=item C<PerlSetVar WS_main "A">

This specifies the name of the C<par> file (without the
C<.par> extension) that contains the main script to be
run. This directive is not needed if only one par file
is specified. If this directive is not specified in the
case of multiple par files, it will be assumed that the
first par file specified by C<PerlSetVar WS_par> contains
the main script.

=item C<PerlSetVar WS_arg "--verbose">

This specifies an argument to be passed to the main script.
Additional arguments may be added through a directive like
C<PerlAddVar WS_arg "--debug">. In addition, if the URL
associated with the handler contains a query string, those
arguments (split on the C<;> or C<&> character) will be
added to the arguments passed to the main script. For example,
a query string of C<arg1=arg;arg2=3> will include the
arguments (in order) C<arg1=arg> and C<arg2=3> passed to the main script.
Query string arguments are added to the argument list after
any specified by C<PerlSetVar WS_arg>.

=item C<PerlSetVar WS_long_opts 1>

If this option is set to a true value, all arguments passed via
either C<PerlSetVar/PerlAddVar WS_arg> directives or by
a query string will have two dashes (C<-->) prepended to them
when passed to the main script (for example, a query string
of C<arg=4> will be passed to the main script as C<--arg=4>.
This may be useful if the main script uses C<Getopt::Long>
to process command-line options.

=item C<PerlSetVar WS_short_opts 1>

If this option is set to a true value, all argumets passed via
either C<PerlSetVar/PerlAddVar WS_arg> directives or by
a query string will have one dash (C<->) prepended to them
when passed to the main script (for example, a query string
of C<a=4> will be passed to the main script as C<-a=4>.
This may be useful if the main script uses C<Getopt::Std>
to process command-line options.

=item C<PerlSetVar WS_module "Tk">

This specifies additional modules, outside of the basic perl core,
that the application needs;
additional modules may be specified by
multiple directives such as C<PerlAddVar WS_module "LWP">.

=back

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

L<PAR::WebStart> for an overview, and
L<PAR::WebStart::PNLP> for details of the
C<PNLP> file.

=cut
