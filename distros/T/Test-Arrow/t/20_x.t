use Test::Arrow;

t->got(123)->expect(123)->name('foo')->x->is;

done;
