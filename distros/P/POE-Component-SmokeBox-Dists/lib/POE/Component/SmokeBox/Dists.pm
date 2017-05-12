package POE::Component::SmokeBox::Dists;
{
  $POE::Component::SmokeBox::Dists::VERSION = '1.08';
}

#ABSTRACT: Search for CPAN distributions by cpanid or distribution name

use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec ();
use File::Path (qw/mkpath/);
use URI;
use File::Fetch;
use CPAN::DistnameInfo;
use Sort::Versions;
use IO::Zlib;
use POE qw(Wheel::Run);

sub author {
  my $package = shift;
  return $package->_spawn( @_, command => 'author' );
}

sub distro {
  my $package = shift;
  return $package->_spawn( @_, command => 'distro' );
}

sub phalanx {
  my $package = shift;
  return $package->_spawn( @_, command => 'phalanx' );
}

sub random {
  my $package = shift;
  return $package->_spawn( @_, command => 'random' );
}

sub _spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for grep { !/^\_/ } keys %opts;

  $opts{pkg_time} = 21600 unless $opts{pkg_time};

  my @mandatory = qw(event);
  push @mandatory, 'search' unless $opts{command} eq 'phalanx' or $opts{command} eq 'random';
  foreach my $mandatory ( @mandatory ) {
     next if $opts{ $mandatory };
     carp "The '$mandatory' parameter is a mandatory requirement\n";
     return;
  }
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
     package_states => [
	$self => [qw(
			_start
			_initialise
			_dispatch
			_spawn_fetch
			_fetch_err
			_fetch_close
			_fetch_sout
			_fetch_serr
			_spawn_process
			_proc_close
			_proc_sout
			_sig_child)],
     ],
     heap => $self,
     ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();

  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $self->{session} = $sender_id;
  $kernel->detach_myself() if $kernel != $sender;
  $kernel->yield( '_initialise' );
  return;
}

sub _initialise {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $return = { };

  my $smokebox_dir = File::Spec->catdir( _smokebox_dir(), '.smokebox' );

  mkpath $smokebox_dir if ! -d $smokebox_dir;
  if ( ! -d $smokebox_dir ) {
     $return->{error} = "Could not create smokebox directory '$smokebox_dir': $!";
     $kernel->yield( '_dispatch', $return );
     return;
  }

  $self->{return} = $return;
  $self->{sb_dir} = $smokebox_dir;

  my $packages_file = File::Spec->catfile( $smokebox_dir, '02packages.details.txt.gz' );

  $self->{pack_file} = $packages_file;

  if ( -e $packages_file ) {
     my $mtime = ( stat( $packages_file ) )[9];
     if ( $self->{force} or ( time() - $mtime > $self->{pkg_time} ) ) {
        $kernel->yield( '_spawn_fetch', $smokebox_dir, $self->{url} );
	return;
     }
  }
  else {
     $kernel->yield( '_spawn_fetch', $smokebox_dir, $self->{url} );
     return;
  }

  # if packages file exists but is older than $self->{pkg_time}, fetch.
  # if packages file does not exist, fetch.
  # otherwise it exists so spawn packages processing.

  $kernel->yield( '_spawn_process' );
  return;
}

sub _dispatch {
  my ($kernel,$self,$return) = @_[KERNEL,OBJECT,ARG0];
  $return->{$_} = $self->{$_} for grep { /^\_/ } keys %{ $self };
  $kernel->post( $self->{session}, $self->{event}, $return );
  $kernel->refcount_decrement( $self->{session}, __PACKAGE__ );
  return;
}

sub _sig_child {
  $poe_kernel->sig_handled();
}

sub _spawn_fetch {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{FETCH} = POE::Wheel::Run->new(
	Program     => \&_fetch,
	ProgramArgs => [ $self->{sb_dir}, $self->{url} ],
	StdoutEvent => '_fetch_sout',
	StderrEvent => '_fetch_serr',
	ErrorEvent  => '_fetch_err',             # Event to emit on errors.
	CloseEvent  => '_fetch_close',     # Child closed all output.
  );
  $kernel->sig_child( $self->{FETCH}->PID(), '_sig_chld' ) if $self->{FETCH};
  return;
}

sub _fetch_sout {
  return;
}

sub _fetch_serr {
  return;
}

sub _fetch_err {
  return;
}

sub _fetch_close {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{FETCH};
  if ( -e $self->{pack_file} ) {
     $kernel->yield( '_spawn_process' );
  }
  else {
     $self->{return}->{error} = 'Could not retrieve packages file';
     $kernel->yield( '_dispatch', $self->{return} );
  }
  return;
}

sub _spawn_process {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{dists} = [ ];
  $self->{PROCESS} = POE::Wheel::Run->new(
	Program     => \&_read_packages,
	ProgramArgs => [ $self->{pack_file}, $self->{command}, $self->{search} ],
	StdoutEvent => '_proc_sout',
	StderrEvent => '_fetch_serr',
	ErrorEvent  => '_fetch_err',             # Event to emit on errors.
	CloseEvent  => '_proc_close',     # Child closed all output.
  );
  $kernel->sig_child( $self->{PROCESS}->PID(), '_sig_chld' ) if $self->{PROCESS};
  return;
}

sub _proc_sout {
  my ($self,$line) = @_[OBJECT,ARG0];
  push @{ $self->{dists} }, $line;
  return;
}

sub _proc_close {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{PROCESS};
  $self->{return}->{dists} = delete $self->{dists};
  $kernel->yield( '_dispatch', $self->{return} );
  return;
}

sub _read_packages {
  my ($packages_file,$command,$search) = @_;
  my %phalanx;
  if ( $command eq 'phalanx' ) {
    $phalanx{ $_ } = undef for _phalanx();
  }
  my $fh = IO::Zlib->new( $packages_file, "rb" ) or die "$!\n";
  my %dists;
  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my $path = ( split ' ', $_ )[2];
    next unless $path;
    next if exists $dists{ $path };
    my $distinfo = CPAN::DistnameInfo->new( $path );
    next unless $distinfo->filename() =~ m!(\.tar\.gz|\.tgz|\.zip)$!i;
    if ( $command eq 'author' ) {
       next unless eval { $distinfo->cpanid() =~ /$search/ };
       print $path, "\n";
    }
    elsif ( $command eq 'phalanx' ) {
       next unless exists $phalanx{ $distinfo->dist };
       if ( defined $phalanx{ $distinfo->dist } ) {
	       my $exists = CPAN::DistnameInfo->new( $phalanx{ $distinfo->dist } );
	       if ( versioncmp( $distinfo->version, $exists->version ) == 1 ) {
		        $phalanx{ $distinfo->dist } = $path;
	       }
       }
       else {
	       $phalanx{ $distinfo->dist } = $path;
       }
    }
    elsif ( $command eq 'random' ) {
       $dists{ $path } = 1;
       next;
    }
    else {
       next unless eval { $distinfo->distvname() =~ /$search/ };
       print $path, "\n";
    }
    $dists{ $path } = 1;
  }
  if ( $command eq 'phalanx' ) {
    print $_, "\n" for grep { defined $_ } values %phalanx;
  }
  if ( $command eq 'random' ) {
    my @dists = keys %dists;
    my %picked;
    while ( scalar keys %picked < 100 ) {
      my $random = $dists[ rand( $#dists ) ];
      next if $picked{ $random };
      $picked{ $random } = $random;
      print $random, "\n";
    }
  }
  return;
}

sub _fetch {
  my $location = shift || return;
  my $url = shift;
  my @urls = qw(
    http://www.cpan.org/
    ftp://ftp.cpan.org/pub/CPAN/
    http://cpan.cpantesters.org/
    ftp://cpan.cpantesters.org/CPAN/
    ftp://ftp.funet.fi/pub/CPAN/
  );
  @urls = ( $url ) if $url;
  my $file;
  foreach my $url ( @urls ) {
    my $uri = URI->new( $url ) or next;
    my @segs = $uri->path_segments();
    pop @segs unless $segs[$#segs];
    $uri->path_segments( @segs, 'modules', '02packages.details.txt.gz' );
    local $File::Fetch::TIMEOUT = 30;
    my $ff = File::Fetch->new( uri => $uri->as_string() ) or next;
    $file = $ff->fetch( to => $location ) or next;
    last if $file;
  }
  return $file;
}

sub _smokebox_dir {
  return $ENV{PERL5_SMOKEBOX_DIR}
     if  exists $ENV{PERL5_SMOKEBOX_DIR}
     && defined $ENV{PERL5_SMOKEBOX_DIR};

  my @os_home_envs = qw( APPDATA HOME USERPROFILE WINDIR SYS$LOGIN );

  for my $env ( @os_home_envs ) {
      next unless exists $ENV{ $env };
      next unless defined $ENV{ $env } && length $ENV{ $env };
      return $ENV{ $env } if -d $ENV{ $env };
  }

  return cwd();
}

# List taken from Bundle::Phalanx100 v0.07
sub _phalanx {
  return qw(
	Test-Harness
	Test-Reporter
	Test-Simple
	Test-Builder-Tester
	Sub-Uplevel
	Test-Exception
	Test-Tester
	Test-NoWarnings
	Test-Tester
	Pod-Escapes
	Pod-Simple
	Test-Pod
	YAML
	PathTools
	Archive-Tar
	Module-Build
	Devel-Symdump
	Pod-Coverage
	Test-Pod-Coverage
	Compress-Zlib
	IO-Zlib
	Archive-Zip
	Archive-Tar
	Storable
	Digest-MD5
	URI
	HTML-Tagset
	HTML-Parser
	libwww-perl
	IPC-Run
	CPANPLUS
	DBI
	DBD-mysql
	GD
	MIME-Base64
	Net-SSLeay
	perl-ldap
	XML-Parser
	Apache-ASP
	CGI.pm
	Date-Manip
	DBD-Oracle
	DBD-Pg
	Digest-SHA1
	Digest-HMAC
	HTML-Tagset
	HTML-Template
	libnet
	MailTools
	MIME-tools
	Net-DNS
	Time-HiRes
	Apache-DBI
	Apache-Session
	Apache-Test
	AppConfig
	App-Info
	Authen-PAM
	Authen-SASL
	BerkeleyDB
	Bit-Vector
	Carp-Clan
	Chart
	Class-DBI
	Compress-Zlib-Perl
	Config-IniFiles
	Convert-ASN1
	Convert-TNEF
	Convert-UUlib
	CPAN
	Crypt-CBC
	Crypt-DES
	Crypt-SSLeay
	Data-Dumper
	Date-Calc
	DateTime
	DBD-DB2
	DBD-ODBC
	DBD-SQLite
	DBD-Sybase
	Device-SerialPort
	Digest-SHA
	Encode
	Event
	Excel-Template
	Expect
	ExtUtils-MakeMaker
	File-Scan
	File-Spec
	File-Tail
	File-Temp
	GDGraph
	GDTextUtil
	Getopt-Long
	HTML-Mason
	Image-Size
	IMAP-Admin
	Parse-RecDescent
	Inline
	IO
	Spiffy
	IO-All
	IO-Socket-SSL
	IO-String
	IO-stringy
	libxml-perl
	Mail-Audit
	Mail-ClamAV
	Mail-Sendmail
	Math-Pari
	MD5
	MIME-Lite
	MP3-Info
	Net-Daemon
	Net-FTP-Common
	Net-Ping
	Net-Server
	Net-SNMP
	Net-SSH-Perl
	Net-Telnet
	OLE-Storage_Lite
	Params-Validate
	PerlMagick
	PlRPC
	Pod-Parser
	POE
	SNMP
	SOAP-Lite
	Spreadsheet-ParseExcel
	Spreadsheet-WriteExcel
	Spreadsheet-WriteExcelXML
	Storable
	Template-Toolkit
	TermReadKey
	Term-ReadLine-Perl
	Text-Iconv
  TimeDate
  Time-modules
	Unicode-String
	Unix-Syslog
	Verilog-Perl
	WWW-Mechanize
	XML-DOM
	XML-Generator
	XML-LibXML
	XML-NamespaceSupport
	XML-SAX
	XML-Simple
	XML-Writer
  );
}

1;

__END__

=pod

=head1 NAME

POE::Component::SmokeBox::Dists - Search for CPAN distributions by cpanid or distribution name

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  use strict;
  use warnings;

  use POE;
  use POE::Component::SmokeBox::Dists;

  my $search = '^BINGOS$';

  POE::Session->create(
    package_states => [
	    'main' => [qw(_start _results)],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Dists->author(
      event => '_results',
      search => $search,
    );
    return;
  }

  sub _results {
    my $ref = $_[ARG0];

    return if $ref->{error}; # Oh dear there was an error

    print $_, "\n" for @{ $ref->{dists} };

    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Dists is a L<POE> component that provides non-blocking CPAN distribution
searches. It is a wrapper around L<File::Fetch> for C<02packages.details.txt.gz> file retrieval,
L<IO::Zlib> for extraction and L<CPAN::DistnameInfo> for parsing the packages data.

Given either author ( ie. CPAN ID ) or distribution search criteria, expressed as a regular expression,
it will return to a requesting session all the CPAN distributions that match that pattern.

The component will retrieve the C<02packages.details.txt.gz> file to the C<.smokebox> directory. If
that file already exists, a newer version will only be retrieved if the file is older than 6 hours.
Specifying the C<force> parameter overrides this behaviour.

The C<02packages.details.txt.gz> is extracted and a L<CPAN::DistnameInfo> object built in order to
run the search criteria. This process can take a little bit of time.

=head1 CONSTRUCTORS

There are a number of constructors:

You may also set arbitary keys to pass arbitary data along with your request. These must be prefixed
with an underscore _.

=over

=item C<author>

Initiates an author search. Takes a number of parameters:

  'event', the name of the event to return results to, mandatory;
  'search', a regex pattern to match CPAN IDs against, mandatory;
  'session', specify an alternative session to send results to;
  'force', force the poco to refresh the packages file regardless of age;
  'pkg_time', in seconds before the poco refreshes the packages file, defaults to 6 hours;
  'url', the CPAN mirror url to use, defaults to a built-in list;

=item C<distro>

Initiates a distribution search. Takes a number of parameters:

  'event', the name of the event to return results to, mandatory;
  'search', a regex pattern to match distributions against, mandatory;
  'session', specify an alternative session to send results to;
  'force', force the poco to refresh the packages file regardless of age;
  'pkg_time', in seconds before the poco refreshes the packages file, defaults to 6 hours;
  'url', the CPAN mirror url to use, defaults to a built-in list;

=item C<phalanx>

Initiates a search for the Phalanx "100" distributions. Takes a number of parameters:

  'event', the name of the event to return results to, mandatory;
  'session', specify an alternative session to send results to;
  'force', force the poco to refresh the packages file regardless of age;
  'pkg_time', in seconds before the poco refreshes the packages file, defaults to 6 hours;
  'url', the CPAN mirror url to use, defaults to a built-in list;

=item C<random>

Initiates a search for a random 100 CPAN distributions. Takes a number of parameters:

  'event', the name of the event to return results to, mandatory;
  'session', specify an alternative session to send results to;
  'force', force the poco to refresh the packages file regardless of age;
  'pkg_time', in seconds before the poco refreshes the packages file, defaults to 6 hours;
  'url', the CPAN mirror url to use, defaults to a built-in list;

=back

In all the constructors, C<session> is only required if the component is not spawned from within
an existing L<POE::Session> or you wish the results event to be sent to an alternative
existing L<POE::Session>.

=head1 OUTPUT EVENT

Once the component has finished, retrieving, extracting and processing an event will be sent.

C<ARG0> will be a hashref, with the following data:

  'dists', an arrayref consisting of prefixed distributions;
  'error', only present if something went wrong with any of the stages;

=head1 ENVIRONMENT

The component uses the C<.smokebox> directory to stash the C<02packages.details.txt.gz> file.

This is usually located in the current user's home directory. Setting the environment variable C<PERL5_SMOKEBOX_DIR> will
effect where the C<.smokebox> directory is located.

=head1 SEE ALSO

L<CPAN::DistnameInfo>

L<http://qa.perl.org/phalanx>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
