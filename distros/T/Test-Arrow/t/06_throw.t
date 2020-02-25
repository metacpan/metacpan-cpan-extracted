use Test::Arrow;

my $arr = Test::Arrow->new;

$arr->throw_ok(sub { die 'foo' });
$arr->throw_ok(sub { die 'bar' }, 'die bar');
$arr->name('die baz')->throw_ok(sub { die 'baz' });
$arr->throw(sub { die 'bar' })->catch(qr/^ba/);
$arr->name('die bar')->throw(sub { die 'bar' })->catch(qr/^ba/);
$arr->throw(sub { die 'baz' })->catch(qr/^ba/, 'die baz');
$arr->throw(sub { die 'bar' })->expect(qr/^ba/)->like;
$arr->throw(sub { die 'bar' }, qr/^ba/);
$arr->throw(sub { die 'bar' }, qr/^ba/, 'die bar');

$arr->done_testing;
