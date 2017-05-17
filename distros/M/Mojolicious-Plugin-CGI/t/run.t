use lib '.';
use t::Helper;

use Mojolicious::Lite;

plugin CGI => {
  route => '/',
  run   => sub {
    print "HTTP/1.1 200 OK\r\n";
    print "Content-Type: text/html; charset=ISO-8859-1\r\n";
    print "\r\n";
    print "<body><p>Hi!\n";
  },
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_like(qr/Hi!/);

done_testing;
