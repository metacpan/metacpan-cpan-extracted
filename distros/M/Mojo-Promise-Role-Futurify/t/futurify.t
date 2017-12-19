use strict;
use warnings;
use Test::More;
use Mojo::Promise;

my $class = Mojo::Promise->with_roles('Mojo::Promise::Role::Futurify');

my $p = $class->new;
my $f = $p->futurify;
ok $f->isa('Future'), 'returned a Future';
$p->resolve('Success', 'extra', 'args');
my @results;
ok eval { @results = $f->get; 1 }, 'retrieved success';
is_deeply \@results, ['Success', 'extra', 'args'], 'right success';

$p = $class->new;
$f = $p->futurify;
$p->reject('Failure', 'extra', 'args');
my @failure;
ok !eval { @results = $f->get; 1 }, 'exception thrown on failure';
like $@, qr/^Failure/, 'right failure';
is_deeply [$f->failure], ['Failure', 'extra', 'args'], 'right failure';

$p = $class->new;
$f = $p->futurify;
$p->ioloop->timer(0.1 => sub { $p->resolve('Delayed') });
$f->await;
ok $f->is_ready, 'Future is ready';
ok $f->is_done, 'Future succeeded';
is $f->get, 'Delayed', 'right success';

$p = $class->new;
$f = $p->futurify;
$p->ioloop->timer(0.1 => sub { $p->reject('Delayed') });
$f->await;
ok $f->is_ready, 'Future is ready';
ok $f->is_failed, 'Future is failed';
is $f->failure, 'Delayed', 'right failure';

my $loop = Mojo::IOLoop->new;
$p = $class->new(ioloop => $loop);
$f = $p->futurify;
$loop->timer(0.1 => sub { $p->resolve('Custom loop') });
$f->await;
ok $f->is_ready, 'Future is ready';
ok $f->is_done, 'Future succeeded';
is $f->get, 'Custom loop', 'right success';

done_testing;
