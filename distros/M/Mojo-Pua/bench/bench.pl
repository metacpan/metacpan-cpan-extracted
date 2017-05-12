use Evo 'Test::More; Mojo::Pua want_code; Benchmark cmpthese';

cmpthese - 1, {
  want_code => sub {
    my $res;
    my $pua = Mojo::Pua->new();
    $pua->get("http://127.0.0.1:3000/")->then(want_code 200)->then(
      sub($res) {
        Mojo::IOLoop->stop;
        die unless $res->code == 200;
      }
    );
    Mojo::IOLoop->start;
  },

  simple_promise => sub {
    my $pua = Mojo::Pua->new;
    $pua->get("http://127.0.0.1:3000/")->then(
      sub($tx) {
        Mojo::IOLoop->stop;
        die unless $tx->res->code == 200;
      }
    );

    Mojo::IOLoop->start;
  },

  bare_mojoua => sub {

    my $ua = Mojo::UserAgent->new;
    $ua->get(
      'http://127.0.0.1:3000',
      sub ($ua, $tx) {
        Mojo::IOLoop->stop;
        die unless $tx->res->code == 200;
      }
    );

    Mojo::IOLoop->start;
  }
};
