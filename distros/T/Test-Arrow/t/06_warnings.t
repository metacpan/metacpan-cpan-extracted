use Test::Arrow;

my $arr = Test::Arrow->new;

$arr->warnings_ok(sub { warn 'foo' });
$arr->warnings_ok(sub { warn 'bar' }, 'warn bar');
$arr->name('warn baz')->warnings_ok(sub { warn 'baz' });

$arr->warn_ok(sub { warn 'warn_ok' });
$arr->warning_ok(sub { warn 'warnings_ok' });

$arr->warnings(sub { warn 'bar' })->catch(qr/^ba/);
$arr->name('die bar')->warnings(sub { warn 'bar' })->catch(qr/^ba/);
$arr->warnings(sub { warn 'baz' })->catch(qr/^ba/, 'warn baz');
$arr->warnings(sub { warn 'bar' })->expect(qr/^ba/)->like;
$arr->warnings(sub { warn 'bar' }, qr/^ba/);
$arr->warnings(sub { warn 'bar' }, qr/^ba/, 'warn bar');

$arr->warning(sub { warn 'bar' })->catch(qr/^ba/);

Test::Arrow->done_testing;
