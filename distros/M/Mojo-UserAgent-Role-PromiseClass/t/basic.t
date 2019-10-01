use Mojo::Base -strict;

use Test::More;
use Test::Fatal;
use Mojolicious::Lite;
use Test::Mojo;

my $class = Mojo::UserAgent->with_roles('+PromiseClass');
ok(defined $class, "class->with_roles works");

{
    package Mojo::Promise::Role::Fake;
    use Mojo::Base -role;
    sub the_answer_to_everything {
	return 42;
    }
}
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

done_testing();
