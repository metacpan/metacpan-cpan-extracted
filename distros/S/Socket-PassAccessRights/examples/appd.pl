#!/usr/bin/perl
# 29.1.2000, Sampo Kellomaki <sampo@iki.fi>
#
# Application and cache daemon
#   - generates pages and caches them in memory
#   - stores volatile application state variables in memory
#
# Listens on a Unix domain socket and sequentially accepts
# connections and serves them from memory. Also accepts file descriptors
# from the Unix domain socket and pumps data back and forth. Eventually
# this should be done in multithreaded fashion, but that requres
# threaded perl, which is not certified as stable.

use tcpcat;
use cgi;
use Data::Dumper;
use Socket::PassAccessRights;

### Set up the socket and start listening

umask 0;
$SERV = &tcpcat::open_unix_server('/tmp/appd');
warn "Listening on unix stream socket /tmp/appd\n";

$|=1;
$rin = '';
vec($rin,fileno($SERV),1) = 1;

### Select loop. Timeout is zero if there is background work to do.

while (1) {
    $n++;
    $0 = 'FXD '.($#work+1).": $n FXD idle";    
    if (select($rout=$rin, undef, undef, (@work?0:undef))) {
	warn "New connection...\n";
	eval {
	    local $SIG{ALRM} = sub { die "timeout\n" };
	    alarm 3;
	    $CLI = tcpcat::accept_unix_connection();
	    $was = select S; $|=1; select $was;
	    
	    $in = Socket::PassAccessRights::recvfd(fileno($CLI)) or die;
	    open IN, "<&=$in" or die "open received fd $in failed: $!";
	    
	    $out = Socket::PassAccessRights::recvfd(fileno($CLI)) or die;
	    open OUT, ">&=$out" or die "open received fd $out failed: $!";
	    $was = select OUT; $|=1; select $was;
	    
	    warn "Ready to receive...\n";
	    alarm 30;
	    
	    sysread $CLI, $req, 4096;
	    ($op, $path, $rest) = $req =~
		/^(\w+)\s+(\S+)\s+HTTP\/1.[01]\r?\n(.*)$/is;

	    print "Got >$req<\n";
	    
	    if (uc($op) eq GET) {
		unless ($cache{$path}) {
		    warn "Cache miss $path";
		    $cache{$path} = <<HTML;
HTTP/1.0 200 Ok
Content-type: text/html

<title>test</title>
<h1>An X Document</h1>
<form method=post action="test.x">
<input name=FOO>
<input name=OK type=submit value=" Ok ">
</form>
HTML
    ;
		}
		print OUT $cache{$path};
	    } elsif (uc($op) eq POST) {

		### Process any headers we may have received piggy backed
		### to the request line.

		warn "Processing piggybacked headers...\n";
		@lines = split /\n/, $rest;
		while (defined ($_ = shift @lines)) {
		    last if /^\s*$/;
		    warn ">$_<\n";
		    if (($x)=/^Content-length:\s*(\d+)/i) {
			$len = $x;
		    }
		    #warn $_;
		}

		if (!@lines) {
		    ### Read more HTTP headers from in stream and catch
		    ### content length

		    warn "Getting more headers...\n";
		    while (defined ($_ = <IN>)) {
			last if /^\s*$/;
			warn ">$_<\n";
			if (($x)=/^Content-length:\s*(\d+)/i) {
			    $len = $x;
			}
			#warn $_;
		    }

		    $xx = '';
		} else {
		    $xx = join "\n", @lines;  # rest is piggy backed data
		}
		### Now read the post content

		if (length($xx) < $len) {
		    warn "Expecting $len bytes of post content >$xx<\n";
		    read IN, $x, $len-length($xx);
		    %cgi = cgi::cgi_pairs($x.$xx);
		} else {
		    %cgi = cgi::cgi_pairs($xx);
		}

		warn "Ok\n";
		print OUT <<HTML;
HTTP/1.0 200 Ok
Content-type: text/html

<title>post test</title>
<h1>A posted X Document ($cgi{FOO}) $n</h1>
<form method=post action="test.x">
<input name=FOO value="$cgi{FOO}">
<input name=OK type=submit value=" Ok ">
</form>
HTML
    ;
	    } else {
		warn "Unhandled request `$req'";
	    }
	    
	    close OUT;
	    close IN;
	    #print $CLI "HTTP/1.0 200 OK\r\n\r\n";
	    close $CLI;
	    alarm 0;
	};
	if ($@ and $@ !~ /^timeout/) { die }
	warn "Done $@\n";
	next;  # go back to process more requests, in case there was a burst
    }
    ### Do background work
    warn "Do background work.\n";
}

#EOF
