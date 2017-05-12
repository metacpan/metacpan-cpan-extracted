use Test::More tests => 3;
use Plack::Test;
use Plack::Builder;
use FindBin qw($Bin);

{
  my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ] };

  test_psgi
    app => builder {
      enable 'DiePretty';
      $app;
    },
    client => sub {
      my $cb = shift;
      my $req = HTTP::Request->new(GET => '/');
      my $res = $cb->($req);
      is $res->content, 'Hello World';
    };
}

{
  my $app = sub { die 'error' };

  test_psgi
    app => builder {
      enable 'DiePretty';
      $app;
    },
    client => sub {
      my $cb = shift;
      my $req = HTTP::Request->new(GET => '/');
      my $res = $cb->($req);
      like $res->content, qr{error at t/01-basic.t line };
    };
}

{
  my $app = sub { die 'error' };

  test_psgi
    app => builder {
      enable 'DiePretty', template => "$Bin/html/error.html";
      $app;
    },
    client => sub {
      my $cb = shift;
      my $req = HTTP::Request->new(GET => '/');
      my $res = $cb->($req);
      like $res->content, qr{error at t/01-basic.t line };
    };
}
