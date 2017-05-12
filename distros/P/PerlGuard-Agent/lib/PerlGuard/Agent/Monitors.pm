package PerlGuard::Agent::Monitors;
use Moo;
use PerlGuard::Agent::LexWrap;
use Module::Loaded();

has agent => ( is => 'ro', required => 1, weak_ref => 1);
has overrides => ( is => 'rw', default => sub { [] });

sub is_module_loaded {
  my $self = shift;
  my $module_name = shift;

  Module::Loaded::is_loaded($module_name)

}

sub start_monitoring {
  die "Implement in sublass"
}

sub stop_monitoring {
  die "Implement in subclass"
}

sub inform_agent_of_event {

}

sub die_unless_suitable {
  
}

1;