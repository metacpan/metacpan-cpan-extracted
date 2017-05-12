use Evo 'Mojo::Pua PUA want_code; Mojo::IOLoop';


# 200
PUA->get('http://alexbyk.com')

  ->then(want_code 200)

  # we got $res, not $tx, from want_code in the previous step
  ->then(sub($res) { say $res->dom->at('title') })

  ->catch(sub($err) { say "$err"; })

  ->finally(sub { Mojo::IOLoop->stop });


Mojo::IOLoop->start;
