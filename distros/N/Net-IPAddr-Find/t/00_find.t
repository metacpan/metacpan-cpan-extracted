use strict;
use Test;
BEGIN { plan tests => 3 }

use Net::IPAddr::Find;

my $text = join '', <DATA>;
my $origtext = $text;

my @how_many;
my $how_many = find_ipaddrs($text, sub {
				my($ipaddr, $orig) = @_;
				push @how_many, $ipaddr;
				return $orig;
			    });

ok(@how_many == $how_many);
ok((grep { $_->isa('NetAddr::IP') } @how_many) == $how_many);
ok($text, $origtext);

__DATA__
133.145.228.11 - - [09/Jul/2001:00:00:05 +0900] "GET /rss/rdf.cgi?Linux24 HTTP/1.0" 200 2671 "-" "libwww-perl/5.53"
211.128.52.139 - - [09/Jul/2001:00:00:15 +0900] "GET /go.cgi?id=83369 HTTP/1.1" 302 311 "http://bulknews.net/" "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)"
202.247.6.8 - - [09/Jul/2001:00:00:45 +0900] "GET /rss/rdf.cgi?Launch HTTP/1.0" 200 2725 "-" "Java1.3.0_02"
210.170.147.68 - - [09/Jul/2001:00:06:50 +0900] "GET /lib/doc-ja/exegesis2.ja.html HTTP/1.1" 200 34581 "http://silver.fureai.or.jp/diary/diary.200105.html" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.2+) Gecko/20010630"
194.109.233.175 - - [09/Jul/2001:00:07:52 +0900] "GET /lib/archives/CGI-Upload-0.01.readme HTTP/1.1" 404 310 "http://www.google.com/search?q=cgi+upload+example&hl=en&safe=off&start=10&sa=N" "Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)"
202.247.6.8 - - [09/Jul/2001:00:12:42 +0900] "GET /rss/rdf.cgi?KtaiWatch HTTP/1.0" 200 2729 "-" "Java1.3.0_02"
