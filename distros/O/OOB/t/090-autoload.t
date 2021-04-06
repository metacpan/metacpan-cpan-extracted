use Test::More;

use OOB;

{
	package  BBB;

	sub AUTOLOAD {
		$OOB::AUTOLOAD = $BBB::AUTOLOAD;
		OOB::AUTOLOAD(@_);
	}
}


is(OOB->dump, undef);

eval { BBB->okay };
like($@, qr/Undefined subroutine/);

eval { OOB->okay('one', 'two') };
like($@, qr/Attempt to set unregistered OOB attribute/);

is(OOB->okay, undef);

my $thing;
my $other = \$thing;
my $again = \$other;
my $message = bless \$again, 'REF';
OOB->okay($message, 'testing');
is(OOB->okay($message), 'testing');
is(OOB->okay, undef);

1;



ok(1);

1;
done_testing;
