use utf8;
use t::Helper;
use Mojo::UserAgent;
use Mojo::Util qw(decode spurt);

{
  use Mojolicious::Lite;
  use Mojo::Util 'decode';

  plugin CGI => {
    route => '/',
    run   => sub {
      diag "PATH_INFO=$ENV{PATH_INFO}";
      print "HTTP/1.1 200 OK\r\n";
      print "Content-Type: text/plain; charset=UTF-8\r\n";
      print "\r\n";
      print "p=$ENV{PATH_INFO}\n";
    },
  };
}

# Application is alive
my $t = Test::Mojo->new;
my @w;

$t->get_ok("/foo")->status_is(200)->content_is("p=/foo\n", 'ascii');
$t->get_ok("/föö")->status_is(200)->content_is("p=/föö\n", 'umlauts');
$t->get_ok("/fö’")->status_is(200)->content_is("p=/fö’\n", 'quote');

is "@w", "", "no warnings";

done_testing();
