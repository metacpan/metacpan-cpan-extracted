use strict;
use Test::More;

my %called;

BEGIN {
	package Person;
	use Sub::Lazy;
	sub new {
		$called{Person_new}++;
		bless $_[1], $_[0];
	}
	sub name :Lazy {
		$called{Person_name}++;
		shift->{name};
	}
	sub job_title :Lazy {
		$called{Person_job_title}++;
		shift->{job_title};
	}
};

BEGIN {
	package Company;
	use Sub::Lazy;
	sub new {
		$called{Company_new}++;
		bless $_[1], $_[0];
	}
	sub name :Lazy {
		$called{Company_name}++;
		shift->{name};
	}
	sub get_employee :Lazy(class=>"Person") {
		$called{Company_get_employee}++;
		my ($self, $n) = @_;
		return $self->{employees}[$n];
	}
	sub get_manager :Lazy(class=>"Person",job_title=>"Manager") {
		$called{Company_get_manager}++;
		my ($self) = @_;
		my ($manager) = grep {$_->job_title eq 'Manager'} @{$self->{employees}};
		return $manager;
	}
};

my $acme = Company::->new({
	name      => 'Acme Inc',
	employees => [
		Person::->new({ name => 'Alice', job_title => 'Staff' }),
		Person::->new({ name => 'Bob',   job_title => 'Staff' }),
		Person::->new({ name => 'Carol', job_title => 'Manager' }),
	],
});

%called = ();

my $e0 = $acme->get_employee(0);
ok( $e0->isa('Person') );
ok( $e0->can('job_title') );
ok( not $called{Company_get_employee} );

my $e0_name = $e0->name;
ok( $called{Company_get_employee} );
ok( not $called{Person_name} );
is( $e0_name, 'Alice' );
ok( $called{Person_name} );

%called = ();

my $m = $acme->get_manager;
ok( $m->isa('Person') );
ok( $m->can('job_title') );
is( $m->job_title, 'Manager' );
ok( not $called{Company_get_employee} );

my $m_name = $m->name;
ok( not $called{Company_get_employee} );
ok( not $called{Person_name} );
is( $m_name, 'Carol' );
is( $m->job_title, 'Manager' );
ok( $called{Person_name} );

done_testing;
