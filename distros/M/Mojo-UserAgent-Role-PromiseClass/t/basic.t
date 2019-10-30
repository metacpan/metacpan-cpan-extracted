use Mojo::Base -strict;

use Test::More;
use Test::Fatal;
use Mojolicious::Lite;
use Test::Mojo;

{
    package Mojo::Promise::Role::Fake;
    use Mojo::Base -role;
    sub the_answer_to_everything {
	return 42;
    }
}

my $class = Mojo::Base->with_roles('+PromiseClass');
ok(defined $class, "base->with_roles works");
my $obj = $class->new;
ok(defined $obj, "new");
is($obj->promise_class, 'Mojo::Promise');
ok(!Role::Tiny::does_role($obj->promise_class,'Mojo::Promise::Role::Fake'));
like(exception { $obj->promise_class->does('Mojo::Promise::Role::Fake') }, qr/Can't locate object method/);

$obj->promise_roles('+Fake');
ok($obj->promise_class->does('Mojo::Promise::Role::Fake'));
is($obj->promise_class->new->the_answer_to_everything, '42');
is($obj->promise_class, $obj->promise_roles('+Fake')->promise_class, "twice");

$class = Mojo::UserAgent->with_roles('+PromiseClass');
ok(defined $class, "ua->with_roles works");

get '/' => sub {
  my $c = shift;
  $c->render(text => "Hello World");
};

my $t = Test::Mojo->new;
$t->ua->with_roles('+PromiseClass')->promise_roles('+Fake');
my $tx;
my $p = $t->ua->get_p('/')->then( sub { $tx = shift; } );
is ($p->the_answer_to_everything, '42', 'method picked up');
$p->wait;
is($tx->res->code, '200');
is($tx->res->body, 'Hello World');

my $pc1 = $t->ua->promise_class;
$t->ua->promise_roles('+Fake');
ok($pc1 eq $t->ua->promise_class, 'add +Fake twice');
like(exception { $t->ua->promise_roles(); }, qr/^No roles supplied!.*/);

{
    package MyTransactor;
    use Mojo::Base 'Mojo::UserAgent::Transactor';
    our $global;
    sub promisify {
	my $self = shift;
	my ($promise) = @_;
	$global = eval { $promise->the_answer_to_everything; } // $@;
	return $self->SUPER::promisify(@_);
    }
}

$t = Test::Mojo->new;
$t->ua->transactor(MyTransactor->new)->with_roles('+PromiseClass')->promise_roles('+Fake');
$p = $t->ua->get_p('/');
$p->wait;
is ($p->the_answer_to_everything, '42', 'method picked up');
is ($MyTransactor::global, '42', 'method visible in transactor');

$t = Test::Mojo->new;
$t->ua->transactor(MyTransactor->new);
$p = $t->ua->get_p('/');
like (exception { $p->the_answer_to_everything }, qr/the_answer_to_everything/);
$p->wait;
like ($MyTransactor::global,
      qr/the_answer_to_everything/,
      'transactor indeed being invoked');

done_testing();
