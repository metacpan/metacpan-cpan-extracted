# NAME [![Build Status](https://travis-ci.org/alexbyk/mojo-pua.svg?branch=master)](https://travis-ci.org/alexbyk/mojo-pua)

Mojo::Pua - HTTP Client + PromisesA+

# SYNOPSIS

```perl
use Evo 'Mojo::Pua PUA want_code; Mojo::IOLoop';


# 200
PUA->get('http://alexbyk.com')

  ->then(want_code 200)

  # we got $res, not $tx, from want_code in the previous step
  ->then(sub($res) { say $res->dom->at('title') })

  ->catch(sub($err) { say "$err"; })

  ->finally(sub { Mojo::IOLoop->stop });


Mojo::IOLoop->start;
```

`Mojo::UserAgent` with promises. See some examples in `examples` dir. The benchmarks are in `bench` dir
