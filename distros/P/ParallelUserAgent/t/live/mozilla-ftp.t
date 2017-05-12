print "1..4\n";

use strict;
use LWP::Parallel::UserAgent;

my $ua = LWP::Parallel::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "ftp://ftp.mozilla.org/pub/");

my $res = $ua->request($req);

#print $res->as_string;

print "not " unless $res->code eq "200";
print "ok 1\n";

print "not " unless $res->header("Content-Type") =~ /ftp-dir-listing/;
print "ok 2\n";

print "not " unless $res->content =~ /README/;
print "ok 3\n";

$req = HTTP::Request->new(GET => "ftp://ftp.mozilla.org/pub/README");
$res = $ua->request($req);

# do not print the contents in a real test -- it contains 'not' :-)
#print $res->as_string;  
#print "not " unless $res->header("Content-Type") =~ /text\/plain/;
#print "ok 4\n";

print "not " unless $res->content =~ /mirrors.html/;
print "ok 4\n";
