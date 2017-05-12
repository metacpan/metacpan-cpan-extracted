use strict;
use warnings;
package TestClass2;
use Moose;
with 'MooseX::Role::LogHandler' => { logconf =>                                      
                                       { file => { 
										    filename =>  't/testlog2', 
										    maxlevel => 'debug',
										    minlevel => 'warning',
										    message_layout => '%T [%L] [%p] line %l: %m'
										   } 
                                        } 
                                    };
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