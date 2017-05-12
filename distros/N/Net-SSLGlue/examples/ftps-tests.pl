#!/usr/bin/perl
use strict;
use warnings;

# This runs lots of tests with SSL against a test server
# - plain
# - with SSL upgrade and plain data connections
# - with SSL upgrade and SSL data connections
# - with SSL upgrade and downgrade after auth
# - with direct SSL connection

# setup stuff here
# you need a server where you can write and read and create directories
# SSL support is optional, but preferred
# IPv6 support should be possible

my $testhost = '127.0.0.1'; # where your test server is, IPv6 should be ok
my $plain_port = 2021;      # port where server listens for plain ftp
my $user = 'foo';           # login as user
my $pass = 'bar';           # with pass
my $can_auth = 1;           # does server support AUTH TLS
my $ssl_port = 2090;        # does server support direct SSL
my %sslargs = (
    # should be enabled if you want to verify certificates
    SSL_verify_mode => 1,
    # for CAs known to the system this might be maybe ommitted
    # otherwise set this or SSL_ca_path
    SSL_ca_file => 'ca.pem',
    # if the certificate has a different name then $testhost set it here
    SSL_verifycn_name => 'server.local',
);


use Net::SSLGlue::FTP;
use IO::Socket::SSL;
use Carp 'croak';

my @test = (
    # basic FTP server stuff
    { Passive => 0 },
    { Passive => 1 },
    $can_auth ? (
	# SSL upgrade with data connections unprotected
	{ Passive => 0, _starttls => 1, _prot => 'C' },
	{ Passive => 1, _starttls => 1, _prot => 'C' },
	# SSL upgrade with data connections protected
	{ Passive => 0, _starttls => 1 },
	{ Passive => 1, _starttls => 1 },
	# SSL upgrade with SSL downgrade after auth
	{ Passive => 0, _starttls => 1, _stoptls => 1 },
	{ Passive => 1, _starttls => 1, _stoptls => 1 },
    ):(),
    # direct SSL on separate port
    $ssl_port ? (
	{ Passive => 0, SSL => 1, Port => $ssl_port },
	{ Passive => 1, SSL => 1, Port => $ssl_port },
    ):(),
);

my $testbase = sprintf("test-%04x%04x-",rand(2**16),rand(2**16));
for( my $i=0;$i<@test;$i++ ) {

    my %conf = %{$test[$i]};
    my $starttls = delete $conf{_starttls};
    my $stoptls = delete $conf{_stoptls};
    my $prot = delete $conf{_prot};
    my $dir = "$testbase$i";

    print STDERR "------------ $dir\n";
    my $ftp = Net::FTP->new( $testhost,
	Port => $plain_port,
	Debug => 1,
	%sslargs,
	%conf,
    ) or die "ftp connect failed";

    my $ftperr = sub {
	my $msg = shift;
	croak "$msg failed (@_): ".$ftp->message;
    };

    # upgrade to SSL
    $ftp->starttls or $ftperr->('auth tls', $SSL_ERROR)
	if $starttls;

    # login
    $ftp->login($user,$pass) or $ftperr->('login');

    # downgrade from SSL
    $ftp->stoptls or $ftperr->('ccc') if $stoptls;

    # change protection level
    $ftp->prot($prot) or $ftperr->("PROT $prot")
	if $prot;

    # create directory for test and change into it
    $ftp->mkdir($dir) or $ftperr->('mkd');
    $ftp->cwd($dir) or $ftperr->('cwd');

    # check that dir is empty
    my @files = $ftp->ls;
    $ftp->ok or $ftperr->('nlst');
    @files and die "directory should be empty";

    # create a file in dir
    $ftp->put( _s2f( my $foo = 'foo' ,'<' ), 'foo.txt' )
	or $ftperr->('stor');
    # append some bytes to it
    $ftp->append( _s2f('bar'),'foo.txt' ) or $ftperr->('appe');
    # check that it is there
    @files = $ftp->ls;
    "@files" eq 'foo.txt' or die "wrong ls: @files";

    # retrieve file and verify content
    $ftp->get( 'foo.txt', _s2f( $foo = '','>' ));
    $foo eq 'foobar' or die "wrong data: 'foobar' != '$foo'";

    $ftp->quit;
}

sub _s2f {
    open( my $fh,$_[1] || '<',\$_[0] );
    return $fh
}
