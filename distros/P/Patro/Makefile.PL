use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010001;

our %RECOMMENDED = (
    'Sys::HostAddr' => 0
    );
our %REQUIRED = (
    'Devel::GlobalDestruction' => 0,
    'Storable' => 0,
    'MIME::Base64' => 0 
    );
our @NO_INDEX = ( 'threads::shared' );

our %META_MERGE
    = (recommends => \%RECOMMENDED,
       'meta-spec' => { version => 2 },
       resources => {
	   repository => {
	       type => 'git',
	       url => 'https://github.com/mjob/p5-patro.git',
	       web => 'https://github.com/mjob/p5-patro'
	   },
       });
if (@NO_INDEX) {
    $META_MERGE{no_index} = { 'package' => \@NO_INDEX };
}

our $FILES_TO_CLEAN
    = join " ", qw(Patro-* t/cfg*);

our @TEST_FILES = ('t/*.t');

if (eval { can_socket(); 1 }) {
    print STDERR "Network check ok. Will conduct network Patro tests\n";
    open my $fh, '>', 't/PatroNetworkOK.pm';
    print $fh "1;\n";
    close $fh;
}

######################################################################

my $MM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(

    NAME                => 'Patro',
    AUTHOR              => q[Marty O'Brien <mob@cpan.org>],       #'],
    VERSION_FROM        => 'lib/Patro.pm',
    ABSTRACT_FROM       => 'lib/Patro.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%REQUIRED,
    test                => { TESTS => join(' ',@TEST_FILES) },
    ($MM_VERSION >= 6.46   ? ('META_MERGE' => \%META_MERGE ) : ()),
    ($MM_VERSION >= 6.3002 ? ('LICENSE'    => 'perl')        : ()),

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => $FILES_TO_CLEAN },

    );


sub can_socket {

    # see if this system is capable of creating a socket and connecting
    # to that socket through the hostname

    $SIG{ALRM} = sub { die "can_socket timeout\n" };
    use Socket;
    alarm 5;
    my $host = eval "require Sys::HostAddr;Sys::HostAddr->new->main_ip"
        // $ENV{HOSTNAME} // qx(hostname) // "localhost";
    chomp($host);

    socket(my $socket,Socket::PF_INET(),Socket::SOCK_STREAM(),
           getprotobyname("tcp")) || die "socket";
    setsockopt($socket,Socket::SOL_SOCKET(),Socket::SO_REUSEADDR(),
               pack("l",1)) || die "setsockopt";
    my $sa = Socket::pack_sockaddr_in(0,Socket::inet_aton($host));
    bind($socket,$sa) || die "bind";
    listen($socket,Socket::SOMAXCONN()) || die "listen";
    my($port,$addr)=Socket::unpack_sockaddr_in(getsockname($socket));
    die "port" unless $port;

    my $pid = fork();
    die "fork" unless defined $pid;
    if ($pid == 0) {
        my $client;
        my $paddr = accept($client,$socket) or die "accept";
        my $fh_sel = select $client;
        $| = 1;
        select $fh_sel;

        my $x = <$client>;
        my $y = <$client>;
        print {$client} $x+$y,"\n";
        close $client;
        exit 0;
    }

    my $pa = Socket::pack_sockaddr_in($port, Socket::inet_aton($host));
    socket(my $client,Socket::PF_INET(),Socket::SOCK_STREAM(),
           getprotobyname('tcp')) or die "2nd socket";
    connect($client,$pa) or die "connect";
    my $fh_sel = select $client;
    $| = 1;
    select $fh_sel;
    print {$client} 42,"\n";
    print {$client} 19,"\n";
    my $result = <$client>;
    chomp($result);
    if ($result != 61) {
        die "bad result $result";
    }
    close $client;
    my $wpid = waitpid $pid,0;
    my $status = $?;
    if ($status != 0) {
        die "child status $status";
    }
    alarm 0;
    return;
}



#############################################################################

package MY;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# additional testing targets
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub MY::postamble {
    # placeholder for future use
    return "";
}

