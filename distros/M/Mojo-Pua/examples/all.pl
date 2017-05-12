# this is nice import/export, thanks to Evo. + strict, warnings and other
use Evo 'Mojo::Pua; Mojo::Promise all; Mojo::IOLoop';

# Synchronization example with catch and finally.
# see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all

my $pua = Mojo::Pua->new;

all($pua->get('http://alexbyk.com/'), $pua->get('http://mojolicious.org/'))

  # works like my @tx = @$tx;
  ->spread(sub(@tx) { say $_->res->dom->at('title')->text for @tx })

  ->catch(sub($err) { say "$err" })

  ->finally(sub { Mojo::IOLoop->stop });


Mojo::IOLoop->start;
