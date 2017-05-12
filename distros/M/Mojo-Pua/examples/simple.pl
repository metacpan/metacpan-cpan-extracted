use Evo 'Mojo::Pua PUA; Mojo::IOLoop';


# 200
PUA->get('http://alexbyk.com')

  ->then(sub($tx) { say $tx->res->dom->at('title') })

  ->catch(sub($err) { say "$err"; })

  ->finally(sub { Mojo::IOLoop->stop });


Mojo::IOLoop->start;
