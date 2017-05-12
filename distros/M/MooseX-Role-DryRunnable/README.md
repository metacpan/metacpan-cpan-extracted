## MooseX-Role-DryRunnable

For many reasons can be interesting change the behavior of some methods using some configuration. For example, there is a special mode, called "dry run", where we can avoid some instructions (like delete/insert/update data) in order to run the system in the product environment and produce log of any operations.

There are many ways: extend the class to override some methods and trigger the option `dry_run` using some proxy, add if/else manually in each method, using (AOP) Aspects Oriented Programming (Aspect or Moose around). I choose, to solve this problem, the Moose around with AOP approach.

This module is a Moose Role who require two methods, `is_dry_run` and `on_dry_run`, the first method return true if we are in this mode (reading from a configuration file, command line option or some environment variable) and the second receive the name of the method and the list of arguments. Consider the example below:

	package Foo;
	use Data::Dumper;
	use Moose;

	with 'MooseX::Role::DryRunnable' => { 
	  methods => [ qw(bar) ]
	};

	has dry_run => (is => 'ro', isa => 'Bool', default => 0);

	sub bar {
	  shift;
	  print "Foo::bar @_\n";
	}

	sub is_dry_run { # required !
	  shift->dry_run
	}

	sub on_dry_run { # required !
	  my $self   = shift;
	  my $method = shift;
	  $self->logger("Dry Run method=$method, args: \n", @_);
	}
	
In this case, if we set the attribute `dry_run` to true, instead call the content of Foo::bar method, we call `on_dry_run` passing the method name and arguments to log (or do something different, you choose).

## Attributes - EXPERIMETAL

To put the information about the `dry run` capability close to the method, there is an Attribute called `:dry_it`.

	package Foo;
	use Data::Dumper;
	use Moose;
	use MooseX::Role::DryRunnable::Attribute;
	with 'MooseX::Role::DryRunnable::Base';

	has dry_run => (is => 'ro', isa => 'Bool', default => 0);

	sub bar :dry_it {
	  shift;
	  print "Foo::bar @_\n";
	}

	sub is_dry_run { # required !
	  shift->dry_run
	}

	sub on_dry_run { # required !
	  my $self   = shift;
	  my $method = shift;
	  $self->logger("Dry Run method=$method, args: \n", @_);
	}
	
Unfortunately, this attribute is injected in the UNIVERSAL. It is Experimental. Be Careful.

## Test Coverage

100% code coverage by 3 tests.

	--------------------------- ------ ------ ------ ------ ------ ------ ------
	File                           stmt   bran   cond    sub    pod   time  total
	---------------------------- ------ ------ ------ ------ ------ ------ ------
	...ooseX/Role/DryRunnable.pm  100.0    n/a    n/a  100.0    n/a   70.5  100.0
	.../DryRunnable/Attribute.pm  100.0  100.0    n/a  100.0    n/a   24.3  100.0
	.../Role/DryRunnable/Base.pm  100.0    n/a    n/a  100.0    n/a    5.2  100.0
	Total                         100.0  100.0    n/a  100.0    n/a  100.0  100.0
	---------------------------- ------ ------ ------ ------ ------ ------ ------
