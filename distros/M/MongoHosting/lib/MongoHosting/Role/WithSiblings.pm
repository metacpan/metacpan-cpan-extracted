package MongoHosting::Role::WithSiblings;

use Moo::Role;
use strictures 2;
use Rex::Commands::Host;

requires 'setup';
requires '_init';

has parent => (is => 'rw', weak_ref => 1, handles => {siblings => 'members'});
has is_primary => (is => 'ro', default => 0, init_arg => 'primary');

before setup => sub {
  my $self = shift;
  Rex::Logger::info('Populating /etc/hosts');
  $self->_setup_etc_hosts;
};

sub _setup_etc_hosts {
  my $self = shift;
  create_host $_->host => {ip => $_->private_ip} for @{$self->siblings};

  create_host $_->host => {ip => $_->private_ip}
    for map { @{$_->members} } @{$self->parent->siblings};

}

1;
