# $Id: apache.t,v 1.28 1999/08/26 23:39:52 john Exp $

use strict;
use Cwd;
use IO::Socket;
use Net::Ident;

# GET uri from server
sub GET {
    my ( $server, $uri ) = @_;
    my ( $header, $content );

    print "# GET http://$server$uri\n";
    eval {
        my $sock = new IO::Socket::INET PeerAddr => $server, Timeout => 10;
        $sock or die "cannot connect to $server: $!\n";
        $sock->autoflush(1);
        local $SIG{ALRM} = sub { die "Timeout in GET\n" };
        alarm(10);
        print $sock <<HTTP;
GET $uri HTTP/1.0\r
User-Agent: t/apache.t\r
Host: $server\r
Connection: close\r
\r
HTTP

        my $resp = join( "", <$sock> );
        alarm(0);
        ( $header, $content ) = $resp =~ /\A((?:.*\n)+)\r?\n([\s\S]*)\Z/;
        $header or die "server returned garbage: $resp\n";
        wantarray ? ( $content, $header ) : $content;
    };
}

use vars qw($apache_bin $apache_addr $apache_root $username $ourpid);

END {
    # make sure apache dies when we exit, but only if we exit ourselves
    return if !$ourpid || $ourpid != $$;
    if (   defined $apache_root
        && -r "$apache_root/logs/httpd.pid"
        && open( PID, "$apache_root/logs/httpd.pid" ) ) {
        my $pid = <PID>;
        chomp $pid;
        close PID;
        kill TERM => $pid
          and print "# stopped apache\n";
        sleep 2;
        kill KILL => $pid;
    }
}

# Initialise apache test. If the below dies at any point, it means the
# apache setup failed. This does NOT fail the test, however...
eval {
    # get current directory
    my $cwd = cwd();

    # set our PID, for the END{} routine
    $ourpid = $$;

    # verify the apache test is configured
    -f "$cwd/t/apache/conf/apache_config.pl"
      or die "Apache test not configured\n";

    # read configuration data
    require "$cwd/t/apache/conf/apache_config.pl";

    # write file containing current @INC, to be used by the apache
    # mod_perl programs.
    open( INC, ">$apache_root/perl/inc" )
      or die "cannot write $apache_root/perl/inc: $!\n";
    print INC '@INC = ("', join(
        '","',
        map {
            s/^\./$cwd/;
            $_ = "$cwd/$_" unless m-^/-;
            s/\\/\\\\/g;
            s/"/\\"/g;
            $_
        } @INC
      ),
      "\");\n";
    close INC;

    # OK! Let's have fun!
    print "# Starting apache...\n";
    system( $apache_bin, "-f", "$apache_root/conf/httpd.conf" )
      and die "Apache returned non-zero exit status: $?\n";
    my $startuptime = 3 + time;

    # do a really silly loopback connection and ident lookup on this
    # to find out what identd returns. We assume previous tests
    # already established the proper functioning of Net::Ident in
    # "normal" circumstances!
    my $listen = new IO::Socket::INET Listen => 5, LocalAddr => 'localhost', Timeout => 10;
    $listen or die "SLEEP: Cannot create listening socket: $!\n";
    my $listenport = $listen->sockport;
    my $pid        = fork;
    defined $pid or die "SLEEP: cannot fork: $!\n";
    if ( $pid == 0 ) {

        # child. connect from here to prevent deadlocks
        my $connect = new IO::Socket::INET PeerAddr => "localhost:$listenport";
        $connect or exit 0;    # can't generate error.
        my $dummy = <$connect>;
        exit 0;
    }

    # parent. wait for an incoming connection, or possibly time out
    my $accept = $listen->accept;
    $accept or die "SLEEP: Error in accept: $!\n";

    # phew. we have an incoming connection from ourselves. let's do the
    # actual ident lookup.
    my ( $os, $error );
    ( $username, $os, $error ) = Net::Ident::lookup( $accept, 10 );
    defined $username
      or die "SLEEP: Couldn't perform ident lookup: $error\n";
    print "# identd tells us we're $username\n";
    print $accept "you are $username\n";
    close $accept;
    close $listen;

    # if you think the above is an extremely silly way to do getpwuid($<),
    # think again. Just for fun, let's compare the ID we got with getpwuid
    # and co... sometimes it IS different (for privacy-enhanced identd)
    if (   ( getpwuid($<) && $username ne getpwuid($<) )
        && ( getlogin() && $username ne getlogin() )
        && ( $ENV{USER} && $username ne $ENV{USER} ) ) {
        print "# Hmm... that doesn't look like getpwuid(\$<) = \"", getpwuid($<) || "(undef)", "\"\n";
        print "# nor like getlogin() = \"",                         getlogin()   || "(undef)", "\"\n";
        print "# nor like $ENV{USER} = \"",                         $ENV{USER}   || "(undef)", "\"\n";
    }

    # let apache warm up some more, if necessary
    sleep $startuptime - time if $startuptime > time;

    # test apache itself
    my $result = GET( $apache_addr, "/testapache.txt" );
    defined $result and $result =~ /^Apache OK/
      or die "Apache not ready\n";
    print "# standard Apache OK\n";
    GET( $apache_addr, "/perl/testmodperl" ) =~ /^mod_perl OK/
      or die "mod_perl not ready\n";
    print "# mod_perl OK\n";
};

if ($@) {
    my $reason = $@;
    if ( $reason =~ /^SLEEP: (.*)$/s ) {

        # we died too soon, apache is still starting up.
        $reason = $1;

        # make sure apache starts properly, else we can't kill it
        sleep 5;
    }
    print "# $reason";
    print "\n" unless $reason =~ /\n$/;
    print "1..0\n";
    exit 0;
}

# when we get here, identd is responding, apache is running, and mod_perl
# is functioning. Let's finally do some testing of Net::Ident

print "1..4\n";
my $i = 1;
my ( $reply, $header ) = GET( $apache_addr, "/perl/testident" );
if ( !defined $reply ) {
    print "not ok $i\n";
    $i++;
    exit 0;
}
print "ok $i\n";
$i++;
if ( $header !~ m{\AHTTP/[\d.]+\s+(\d+)\s} || $1 ne "200" ) {
    print "# apache barfed\n";
    print "not ok $i\n";
    $i++;
    print STDERR "$header\n\n$reply\n";
    exit 0;
}
print "ok $i\n";
$i++;
my ( $func, $meth ) = $reply =~ m{
    ^function\slookupFromInAddr\ssays\syou\sare:\s(.*)\n
    ident_lookup\smethod\ssays\syou\sare:\s(.*)\n
}xm;
if ( !defined $meth ) {
    print "not ok $i\n";
    $i++;
    exit 0;
}
print "# ident lookup via apache returned: \"$func\" and \"$meth\"\n";
print( ( $func eq $username ) ? "ok $i\n" : "not ok $i\n" );
$i++;
print( ( $meth eq $username ) ? "ok $i\n" : "not ok $i\n" );
$i++;
