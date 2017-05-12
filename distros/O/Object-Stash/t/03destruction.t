use Test::More;

{
	package Local::Vocal;
	$Local::Vocal::Flag = 0;
	sub new {
		my ($class, $n) = @_;
		#Test::More::diag("Creating $n");
		bless \$n, $class;
	}
	sub DESTROY {
		my $n = ${$_[0]};
		#Test::More::diag("Destroying $n");		
		Test::More::ok($Local::Vocal::Flag, "Destroying $n");
	}
}

{
	package Local::WithStash;
	use Object::Stash;
	sub new { bless [], $_[0]; }	
}

package main;
use Test::More;

# We're going to start the testing, so set the flag to 1, which will
# mean that each object destruction passes a test.
$Local::Vocal::Flag = 1;

plan tests => (my $count = 10);
foreach my $i (1..$count)
{
	my $obj = Local::WithStash->new;
	$obj->stash( vocal => Local::Vocal->new($i) );
	# Allow object to go out of scope.
}

# By now, our original 10 objects should all be completely destroyed.
# Set the flag to 0, which will cause them to fail a test when destroyed.
$Local::Vocal::Flag = 0;

