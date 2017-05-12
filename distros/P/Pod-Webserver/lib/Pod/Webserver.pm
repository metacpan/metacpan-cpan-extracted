package Pod::Webserver;

use parent 'Pod::Simple::HTMLBatch';
use strict;
use vars qw( $VERSION @ISA );

use Pod::Webserver::Daemon;
use Pod::Webserver::Response;

use Pod::Simple::HTMLBatch;
use Pod::Simple::TiedOutFH;
use Pod::Simple;
use IO::Socket;
use File::Spec;
use File::Spec::Unix ();

our $VERSION = '3.11';

# ------------------------------------------------

BEGIN {
  if(defined &DEBUG) { } # no-op
  elsif( defined &Pod::Simple::DEBUG ) { *DEBUG = \&Pod::Simple::DEBUG }
  elsif( ($ENV{'PODWEBSERVERDEBUG'} || '') =~ m/^(\d+)$/ )
    { my $x = $1; *DEBUG = sub(){$x} }
  else { *DEBUG = sub () {0}; }

} # End of BEGIN.

# ------------------------------------------------

#sub Pod::Simple::HTMLBatch::DEBUG () {5}

# ------------------------------------------------

sub add_to_fs {  # add an item to my virtual in-memory filesystem
  my($self,$file,$type,$content) = @_;

  die "Missing filespec\n" unless defined $file and length $file;
  $file = "/$file";
  $file =~ s{/+}{/}s;
  $type ||=
     $file eq '/'        ? 'text/html' # special case
   : $file =~ m/\.dat?/  ? 'application/octet-stream'
   : $file =~ m/\.html?/ ? 'text/html'
   : $file =~ m/\.txt/   ? 'text/plain'
   : $file =~ m/\.gif/   ? 'image/gif'
   : $file =~ m/\.jpe?g/ ? 'image/jpeg'
   : $file =~ m/\.png/   ? 'image/png'
   : 'text/plain'
  ;
  $content = '' unless defined '';
     $self->{'__daemon_fs'}{"\e$file"} = $type;
  \( $self->{'__daemon_fs'}{$file} = $content );

} # End of add_to_fs.

# ------------------------------------------------

sub _arg_h {
  my $class = ref($_[0]) || $_[0];
  $_[0]->_arg_V;
  print join "\n",
    "Usage:",
    "  podwebserver                   = Start podwebserver on localhost:8020. Search \@INC",
    "  podwebserver -p 1234           = Start podwebserver on localhost:1234",
    "  podwebserver -p 1234 -H blorp  = Start podwebserver on blorp:1234",
    "  podwebserver -t 3600           = Auto-exit in 1 hour. Default => 18000 (5 hours). 0 => No timeout",
	"  podwebserver -d /path/to/lib   = Ignore \@INC, and only search within /path/to/lib",
	"  podwebserver -e /path/to/skip  = Exclude /path/to/skip files",
    "  podwebserver -q                = Quick startup (but no Table of Contents)",
    "  podwebserver -v                = Run with verbose output to STDOUT",
    "  podwebserver -h                = See this message",
    "  podwebserver -V                = Show version information",
    "\nRun 'perldoc $class' for more information.",
  "";
  return;

} # End of _arg_h.

# ------------------------------------------------

sub _arg_V {
  my $class = ref($_[0]) || $_[0];
  #
  # Anything else particularly useful to report here?
  #
  print '', __PACKAGE__, " version $VERSION",
    # and report if we're running a subclass:
    (__PACKAGE__ eq $class) ? () : (" ($class)"),
    "\n",
  ;
  print " Running under perl version $] for $^O",
    (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";
  print " Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
    if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();
  print " MacPerl verison $MacPerl::Version\n"
    if defined $MacPerl::Version;
  return;

} # End of _arg_V.

# ------------------------------------------------

sub _contents_filespec { return '/' } # overriding the superclass's

# ------------------------------------------------

sub filespecsys { $_[0]{'_filespecsys'} || 'File::Spec::Unix' }

# ------------------------------------------------

sub _get_options {
  my($self) = shift;
  $self->verbose(0);
  return unless @ARGV;
  require Getopt::Std;
  my %o;

  Getopt::Std::getopts( "d:e:H:hp:qt:Vv" => \%o ) || die "Failed to parse options\n";

  # The 2 switches that shortcut the run:
  $o{'h'} and exit( $self->_arg_h || 0);
  $o{'V'} and exit( $self->_arg_V || 0);

  $self->_arg_h, exit(0) if ($o{p} and ($o{p} !~ /^\d+$/) );
  $self->_arg_h, exit(0) if ($o{t} and ($o{t} !~ /^\d+$/) );

  $self->dir_exclude( [ map File::Spec->canonpath($_), split(/:|;/, $o{'e'}) ] ) if ($o{'e'});
  $self->dir_include( [ map File::Spec->canonpath($_), split(/:|;/, $o{'d'}) ] ) if ($o{'d'});

  $self->httpd_host( $o{'H'} )		if $o{'H'};
  $self->httpd_port( $o{'p'} )		if $o{'p'};
  $self->httpd_timeout( $o{'t'} )	if $o{'t'};

  $self->skip_indexing(1)			if $o{'q'};
  $self->verbose(4)					if $o{'v'};

  return;

} # End of _get_options.

# ------------------------------------------------

# Run me as:  perl -MPod::HTTP -e Pod::Webserver::httpd
# or (assuming you have it installed), just run "podwebserver"

sub httpd {
  my $self = @_ ? shift(@_) : __PACKAGE__;
  $self = $self->new unless ref $self;
  $self->{'_batch_start_time'} = time();
  $self->_init_options;
  $self->_get_options;

  $self->contents_file('/');
  $self->prep_for_daemon;

  my $daemon = $self->new_daemon || return;
  my $url = $daemon->url;
  $url =~ s{//default\b}{//localhost} if $^O =~ m/Win32/; # lame hack

  DEBUG > -1 and print "You can now open your browser to $url\n";

  return $self->run_daemon($daemon);

} # End of httpd.

# ------------------------------------------------

sub _init_options
{
  my($self) = shift;

  $self->dir_exclude([]);
  $self->dir_include([@INC]);

} # End of _init_options.

# ------------------------------------------------

sub makepath { return }               # overriding the superclass's

# ------------------------------------------------

#sub muse { return 1 }

# ------------------------------------------------

sub new_daemon {
  my $self = shift;

  my @opts;

  push @opts, LocalHost => $self->httpd_host if (defined $self->httpd_host);
  push @opts, LocalPort => $self->httpd_port || 8020;

  if (defined $self->httpd_timeout)
  {
	if ($self->httpd_timeout > 0)
	{
	  push @opts, Timeout => $self->httpd_timeout;
	}
  }
  else
  {
	push @opts, Timeout => 24 * 3600; # Default to exit after 24 hours of idle time.
  }

  $self->muse( "Starting daemon with options {@opts}" );
  Pod::Webserver::Daemon->new(@opts) || die "Can't start a daemon: $!\n";

} # End of _new_daemon.

# ------------------------------------------------

sub prep_for_daemon {
  my($self) = shift;

  DEBUG > -1 and print "I am process $$ = perl ", __PACKAGE__, " v$VERSION\n";

  $self->{'__daemon_fs'} = {};  # That's where we keep the bodies!!!!
  $self->{'__expires_as_http_date'} = time2str(24*3600+time);
  $self->{  '__start_as_http_date'} = time2str(        time);

  $self->add_to_fs( 'robots.txt', 'text/plain',  join "\cm\cj",
    "User-agent: *",
    "Disallow: /",
    "", "", "# I am " . __PACKAGE__ . " v$VERSION", "", "",
  );

  $self->add_to_fs( '/', 'text/html',
   # We get this only when we start up in -q mode:
   "* Perl Pod server *\n<p>Example URL: http://whatever/Getopt/Std\n\n"
  );
  $self->_spray_css(        '/' );
  $self->_spray_javascript( '/' );
  DEBUG > 5 and print "In FS: ",
    join(' ', map qq{"$_"}, sort grep !m/^\e/, keys %{ $self->{'__daemon_fs'} }),
    "\n";

  $self->prep_lookup_table();

  return;

} # End of prep_for_daemon.

# ------------------------------------------------

sub prep_lookup_table {
  my $self = shift;

  my $m2p;

  if( $self->skip_indexing ) {
    $self->muse("Skipping \@INC indexing.");
  } else {

    if($self->progress) {
      DEBUG and print "Using existing progress object\n";
    } elsif( DEBUG or ($self->verbose() >= 1 and $self->verbose() <= 5) ) {
      require Pod::Simple::Progress;
      $self->progress( Pod::Simple::Progress->new(4) );
    }

    my $search = $Pod::Simple::HTMLBatch::SEARCH_CLASS->new;
	my $dir_include = $self->dir_include;
    if(DEBUG > -1) {
		if ($#{$self->dir_include} >= 0) {
			print " Indexing all of @$dir_include -- this might take a minute.\n";
		}
		else {
			print " Indexing all of \@INC -- this might take a minute.\n";
			DEBUG > 1 and print "\@INC = [ @INC ]\n";
		}
      $self->{'httpd_has_noted_inc_already'} ++;
    }
	$m2p = $self->modnames2paths($dir_include ? $dir_include : undef);
    $self->progress(0);

	# Filter out excluded folders
	while ( my ($key, $value) = each %$m2p ) {
		DEBUG > 1 and print "-e $value, ",  (grep $value =~ /^\Q$_\E/, @{ $self->dir_exclude }), "\n";
		delete $m2p->{$key} if grep $value =~ /^\Q$_\E/, @{ $self->dir_exclude };
	}

    die "Missing path\n" unless $m2p and keys %$m2p;

	DEBUG > -1 and print " Done scanning \n";

    foreach my $modname (sort keys %$m2p) {
      my @namelets = split '::', $modname;
      $self->note_for_contents_file( \@namelets, 'crunkIn', 'crunkOut' );
    }
    $self->write_contents_file('crunkBase');
  }
  $self->{'__modname2path'} = $m2p || {};

  return;

} # End of prep_lookup_table.

# ------------------------------------------------

sub run_daemon {
  my($self, $daemon) = @_;

  while( my $conn = $daemon->accept ) {
    if( my $req = $conn->get_request ) {
      #^^ That used to be a while(... instead of an if( ..., but the
      # keepalive wasn't working so great, so let's just leave it for now.
      # It's not like our server here is streaming GIFs or anything.

      DEBUG and print "Answering connection at ", localtime()."\n";
      $self->_serve_thing($conn, $req);
    }
    $conn->close;
    undef($conn);
  }
  $self->muse("HTTP Server terminated");
  return;

} # End of run_daemon.

# ------------------------------------------------

sub _serve_pod {
  my($self, $modname, $filename, $resp) = @_;
  unless( -e $filename and -r _ and -s _ ) { # sanity
    $self->muse( "But filename $filename is no good!" );
    return;
  }

  my $modtime = (stat(_))[9];  # use my own modtime whynot!
  $resp->content('');
  my $contr = $resp->content_ref;

  $Pod::Simple::HTMLBatch::HTML_EXTENSION
     = $Pod::Simple::HTML::HTML_EXTENSION = '';

  $resp->header('Last-Modified' => time2str($modtime) );

  my $retval;
  if(
    # This is totally gross and hacky.  So unless your name rhymes
    #  with "Pawn Lurk", you have to cover your eyes right now.
    $retval =
    $self->_do_one_batch_conversion(
      $modname,
      { $modname => $filename },
      '/',
      Pod::Simple::TiedOutFH->handle_on($contr),
    )
  ) {
    $self->muse( "$modname < $filename" );
  } else {
    $self->muse( "Ugh, couldn't convert $modname"  );
  }

  return $retval;

} # End of _serve_pod.

# ------------------------------------------------

sub _serve_thing {
  my($self, $conn, $req) = @_;
  return $conn->send_error(405) unless $req->method eq 'GET';  # sanity

  my $path = $req->url;
  $path .= substr( ($ENV{PATH} ||''), 0, 0);  # to force-taint it.

  my $fs   = $self->{'__daemon_fs'};
  my $pods = $self->{'__modname2path'};
  my $resp = Pod::Webserver::Response->new(200);
  $resp->content_type( $fs->{"\e$path"} || 'text/html' );

  $path =~ s{:+}{/}g;
  my $modname = $path;
  $modname =~ s{/+}{::}g;   $modname =~ s{^:+}{};
  $modname =~ s{:+$}{};     $modname =~ s{:+$}{::}g;
  if( $modname =~ m{^([a-zA-Z0-9_]+(?:::[a-zA-Z0-9_]+)*)$}s ) {
    $modname = $1;  # thus untainting
  } else {
    $modname = '';
  }
  DEBUG > 1 and print "Modname $modname ($path)\n";

  if( $fs->{$path} ) {   # Is it in our mini-filesystem?
    $resp->content( $fs->{$path} );
    $resp->header( 'Last-Modified' => $self->{  '__start_as_http_date'} );
    $resp->header( 'Expires'       => $self->{'__expires_as_http_date'} );
    $self->muse("Serving pre-cooked $path");
  } elsif( $modname eq '' ) {
    $resp = '';

  # After here, it's only untainted module names
  } elsif( $pods->{$modname} ) {   # Is it known pod?
    #$self->muse("I know $modname as ", $pods->{$modname});
    $self->_serve_pod( $modname, $pods->{$modname}, $resp )  or  $resp = '';

  } else {
    # If it's not known, look for it.
    #  This is necessary for indexless mode, and also useful just in case
    #  the user has just installed a new module (after the index was generated)
    my $fspath = $Pod::Simple::HTMLBatch::SEARCH_CLASS->new->find($modname);

    if( defined($fspath) ) {
      #$self->muse("Found $modname as $fspath");
      $self->_serve_pod( $modname, $fspath, $resp );
    } else {
      $resp = '';
      $self->muse("Can't find $modname in \@INC");
      unless( $self->{'httpd_has_noted_inc_already'} ++ ) {
        $self->muse("  \@INC = [ @INC ]");
      }
    }
  }

  $resp ? $conn->send_response( $resp ) : $conn->send_error(404);

  return;

} # End of _serve_thing.

# ------------------------------------------------

sub _wopen {             # overriding the superclass's
  my($self, $outpath) = @_;

  return Pod::Simple::TiedOutFH->handle_on( $self->add_to_fs($outpath) );

} # End of _wopen.

# ------------------------------------------------

sub write_contents_file {
  my $self = shift;
  $Pod::Simple::HTMLBatch::HTML_EXTENSION
     = $Pod::Simple::HTML::HTML_EXTENSION = '';

  return $self->SUPER::write_contents_file(@_);

} # End of write_contents_file.

# ------------------------------------------------

sub url_up_to_contents { return '/' } # overriding the superclass's

# ------------------------------------------------

# Inlined from HTTP::Date to avoid a dependency

{
  my @DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
  my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

  sub time2str (;$) {
    my $time = shift;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	    $DoW[$wday],
	    $mday, $MoY[$mon], $year+1900,
	    $hour, $min, $sec);
  }
}

# ------------------------------------------------

__PACKAGE__->Pod::Simple::_accessorize(
	'dir_include',
	'dir_exclude',
	'httpd_port',
	'httpd_host',
	'httpd_timeout',
	'skip_indexing',
);

httpd() unless caller;

# ------------------------------------------------

1;

__END__

=head1 NAME

Pod::Webserver -- Minimal web server for local Perl documentation

=head1 SYNOPSIS

  % podwebserver
  ...
  You can now open your browser to http://localhost:8020/

=head1 DESCRIPTION

This module can be run as an application that works as a
minimal web server to serve local Perl documentation.  It's like
L<perldoc> except it works through your browser.

C<podwebserver -h> displays help:

	Pod::Webserver version 3.11
	 Running under perl version 5.020002 for linux
	Usage:
	  podwebserver                   = Start podwebserver on localhost:8020. Search @INC
	  podwebserver -p 1234           = Start podwebserver on localhost:1234
	  podwebserver -p 1234 -H blorp  = Start podwebserver on blorp:1234
	  podwebserver -t 3600           = Auto-exit in 1 hour. Default => 86000 (24 hours)
	                                       0 => No timeout, but does not work for me
	  podwebserver -d /path/to/lib   = Ignore @INC, and only search within /path/to/lib
	  podwebserver -e /path/to/skip  = Exclude /path/to/skip files
	  podwebserver -q                = Quick startup (but no Table of Contents)
	  podwebserver -v                = Run with verbose output to STDOUT
	  podwebserver -h                = See this message
	  podwebserver -V                = Show version information

	Run 'perldoc Pod::Webserver' for more information.

=head1 SECURITY (AND @INC)

Pod::Webserver is not what you'd call a gaping security hole --
after all, all it does and could possibly do is serve HTML
versions of anything you could get by typing "perldoc
SomeModuleName".  Pod::Webserver won't serve files at
arbitrary paths or anything.

But do consider whether you're revealing anything by
basically showing off what versions of modules you've got
installed; and also consider whether you could be revealing
any proprietary or in-house module documentation.

And also consider that this exposes the documentation
of modules (i.e., any Perl files that at all look like
modules) in your @INC dirs -- and your @INC probably
contains "."!  If your current working directory could
contain modules I<whose Pod> you don't
want anyone to see, then you could do two things:
The cheap and easy way is to just chdir to an
uninteresting directory:

  mkdir ~/.empty; cd ~/.empty; podwebserver

The more careful approach is to run podwebserver
under perl in -T (taint) mode (as explained in
L<perlsec>), and to explicitly specify what extra
directories you want in @INC, like so:

  perl -T -Isomepath -Imaybesomeotherpath -S podwebserver

You can also use the -I trick (that's a capital "igh",
not a lowercase "ell") to add dirs to @INC even
if you're not using -T.  For example:

  perl -I/that/thar/Module-Stuff-0.12/lib -S podwebserver

An alternate approach is to use your shell's
environment-setting commands to alter PERL5LIB or
PERLLIB before starting podwebserver.

These -T and -I switches are explained in L<perlrun>. But I'll note in
passing that you'll likely need to do this to get your PERLLIB
environment variable to be in @INC...

  perl -T -I$PERLLIB -S podwebserver

(Or replacing that with PERL5LIB, if that's what you use.)


=head2 ON INDEXING '.' IN @INC

Pod::Webserver uses the module Pod::Simple::Search to build the index
page you see at http://yourservername:8020/ (or whatever port you
choose instead of 8020). That module's indexer has one notable DWIM
feature: it reads over @INC, except that it skips the "." in @INC.  But
you can work around this by expressing the current directory in some
other way than as just the single literal period -- either as some
more roundabout way, like so:

  perl -I./. -S podwebserver

Or by just expressing the current directory absolutely:

  perl -I`pwd` -S podwebserver

Note that even when "." isn't indexed, the Pod in files under it are
still accessible -- just as if you'd typed "perldoc whatever" and got
the Pod in F<./whatever.pl>

=head1 SEE ALSO

This module is implemented using many CPAN modules,
including: L<Pod::Simple::HTMLBatch> L<Pod::Simple::HTML>
L<Pod::Simple::Search> L<Pod::Simple>

See also L<Pod::Perldoc> and L<http://search.cpan.org/>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2004-2006 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 Repository

L<https://github.com/ronsavage/Pod-Webserver>

=head1 AUTHOR

Original author: Sean M. Burke C<sburke@cpan.org>.

Maintained by: Allison Randal C<allison@perl.org> and Ron Savage C<ron@savage.net.au>.

=cut


