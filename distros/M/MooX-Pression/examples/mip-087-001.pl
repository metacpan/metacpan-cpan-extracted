use v5.14;
use strict;
use warnings;

package Local {
	use MooX::Pression;
	
	class Employee {
		has name  (type => Str, required => true);
		has title (type => Str, required => true);
		
		method name_and_title () {
			my $name  = $self->name;
			my $title = $self->title;
			return "$name, $title";
		}
	}
	
	class Employee::Former {
		extends Employee;
		factory former_employee;
		has +title = "Team Member";
		
		around name_and_title () {
			my $old = $self->$next(@_);
			return "$old (Former)";
		}
	}
}

my $peon = Local->new_employee(
	name  => 'William Toady',
	title => 'Associate Assistant',
);

say $peon->name_and_title;

my $ex_peon = Local->former_employee(
	name  => 'William Toady',
	title => 'Associate Assistant',
);

say $ex_peon->name_and_title;

my $ex_peon2 = Local->former_employee(
	name  => 'William Toady',
);

say $ex_peon2->name_and_title;

__END__
William Toady, Associate Assistant
William Toady, Associate Assistant (Former)
William Toady, Team Member (Former)
