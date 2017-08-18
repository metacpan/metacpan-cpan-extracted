package MooseX::DIC::Loggable;

use Moose::Role;
use Log::Log4perl;

has logger => ( is => 'ro', isa => 'Log::Log4perl::Logger', lazy => 1, default => sub {
	return Log::Log4perl->get_logger(__PACKAGE__);
});

1;
