use Test::More;

{
	package Test::Foo;

	sub new {
		bless { okay => 1 }, $_[0];
	}

	sub DESTROY {

	}

	1;
}


use OOB ':all';
my $message = Test::Foo->new();
my @set = OOB_set($message, foo => 'testing');
is ($set[0], undef);
my $old = OOB_set($message, bar => OOB_get($message, 'foo'));
is ($old, undef);
@set = OOB_set($message, foo => 'test');
is ($set[0], 'testing');
$old = OOB_set($message, bar => OOB_get($message, 'foo'));
is ($old, 'testing');

is(OOB->dump, undef);

is(OOB_get($message, 'bar'), 'test');
is(OOB_get($message, 'bar', ''), undef);
OOB_reset($message);

1;



ok(1);

1;
done_testing;
