package t::lib::HashSession;
use strict;
use warnings;

use parent 'Plack::Session::Store';

sub new {
	my ($class, %args) = @_;
	return bless +{
		_data => +{},
		%args,
	}, $class;
}

sub fetch {
	my ($self, $session_id) = @_;
	die 'die for testing in fetch' if $self->{dies_on_fetch};
	return $self->{_data}->{$session_id};
}

sub store {
	my ($self, $session_id, $session) = @_;
	die 'die for testing in store' if $self->{dies_on_store};
	$self->{_data}->{$session_id} = $session;

}

sub remove {
	my ($self, $session_id) = @_;
	die 'die for testing in remove' if $self->{dies_on_remove};
	delete $self->{_data}->{$session_id};
}

1;

