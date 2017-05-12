

use strict;
use warnings;
use Digest::SHA1 qw(sha1_hex);
use LWP::UserAgent;


my $private_key = '12345';
my $public_id = 'mcrawfor';

my $content = '';

my $host = "http://solstice.washington.edu";
my $url = "/tools/rest/webq/v1/?foo=blah";
my $method = "GET";

#build auth key
my $date = localtime;
my $content_sha1 = $content ? sha1_hex($content) : '';
my $to_sign = "$private_key\n$method\n$url\n$date\n$content_sha1";
my $auth_key = "SolAuth $public_id:". sha1_hex($to_sign);


my $ua = LWP::UserAgent->new;
$ua->agent("Solstice Webservices Client/0.1 ");

my $req = HTTP::Request->new($method => $host.$url);
$req->content($content) if $content;
$req->header('Content-SHA1', $content_sha1) if $content;
$req->header('Date', $date);
$req->header('Authorization', $auth_key);

my $res = $ua->request($req);

if ($res->is_success) {
    print $res->content;
}
else {
    print $res->status_line, "\n";
    print $res->content;
}


