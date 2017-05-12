package Puzzle::Session::Auth;

our $VERSION = '0.02';

use Params::Validate qw(:types);;

use base 'Class::Container';


sub login {
	# this is a skel
	my $self	= shift;
	my $user	= shift;
	my $pass	= shift;
	# distruggo tutto il pregresso se sono gia' autenticato
  # forse voglio cambiare utente
  $self->destroyUserSessionInfo if ($self->container->user->auth);
  return if ($pass eq '');
	# always auth in this skel
  $self->createUserSessionInfo($user);
}

sub logout{
	# this is a skel
	my $self	= shift;
	$self->destroyUserSessionInfo;
}

sub createUserSessionInfo {
	my $self		= shift;
	my $id			= shift;
	my $suser		= $self->container->user;
	$suser->auth(1);
	$suser->id($id);
  # il secondo elemento cambia da anoymous a registered
  $suser->gid->[1] = 'registered';
	# inoltre, voglio vedere il debug sempre
  $suser->gid->[2] = 'debug';
	# e sono admin
  $suser->gid->[3] = 'admin';
	$suser->time_last_login($suser->time_login || '0000-00-00 00:00:00');
  $suser->time_login(scalar(localtime));
  }

sub destroyUserSessionInfo {
	my $self	= shift;
	$self->container->user->default;
	$self->container->user->gid(['everybody','anonymous']);
}

sub check() {
	# verifica i permessi dell'utente
	my $self			= shift;
	my $puzzle		= $self->container->container;
	my $gids			= $puzzle->cfg->gids;
	return 1 if $self->container->user->isGid($gids);
}	

1;
