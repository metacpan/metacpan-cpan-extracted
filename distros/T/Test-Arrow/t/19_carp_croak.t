use Test::Arrow;

t->warnings(sub { Test::Arrow::_carp('foo') })->catch(qr/^foo at main/);
t->throw(sub { Test::Arrow::_croak('foo') })->catch(qr/^foo at main/);

done;
