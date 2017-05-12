use strict;
use warnings;
package TestClass;
use Moose;
with 'MooseX::Role::LogHandler' => { logfile => 't/testlog'};
has test => ( isa => 'Str', is => 'rw');

sub method_that_logs_1 {
	my $self = shift;
	$self->logger->warn('method1');
}

sub method_that_logs_2 {
	my $self = shift;
	$self->logger->debug('method2') 
}

1;
