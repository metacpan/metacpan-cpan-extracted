package t::lib::MachineTest;

use 5.008001;
use strict;
use warnings;
use Perl::Dist::WiX::Util::Machine;
use parent qw(Perl::Dist::WiX);

sub default_machine {
	my $class = shift;

	# Create the machine
	my $machine = Perl::Dist::WiX::Util::Machine->new(
		class => $class,
		@_,
	);

	# Set the different versions
	$machine->add_dimension('option1');
	$machine->add_option('option1',
		number1 => 1,
	);
	$machine->add_option('option1',
		number1 => 2,
	);
	$machine->add_option('option1',
		number1 => 3,
	);
	$machine->add_option('option1',
		number1 => 4,
	);
	$machine->add_option('option1',
		number1 => 5,
	);

	$machine->add_dimension('option2');
	$machine->add_option('option2',
		number2 => 0,
	);
	$machine->add_option('option2',
		number2 => 1,
	);

	return $machine;
}

#sub new {
#	my $class = shift;
#	my $self = bless { @_ }, $class;
#
#	mkdir $self->image_dir();
#	
#	return $self;
#}

sub prepare { 1; };

sub run {
	my $self = shift;

	my $num = $self->{number2} * 5 + $self->{number1}; 
	
	print "Object number $num ran.\n";
}

sub get_output_files {
	return ();
}

1;