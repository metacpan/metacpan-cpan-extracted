package PEF::Front::Session::MLDBM;

use strict;
use warnings;
use PEF::Front::Config;
use MLDBM::Sync;
use MLDBM qw(GDBM_File Storable);
use Fcntl qw(:DEFAULT :flock);
use base 'PEF::Front::Session';

sub _key ()     {0}
sub _session () {1}
sub _expires () {0}
sub _data ()    {1}

sub load {
	my $self = $_[0];
	my %session_db;
	my $sobj = tie(%session_db, 'MLDBM::Sync', cfg_session_db_file, O_CREAT | O_RDWR, 0660) or die "$!";
	$sobj->Lock;
	my $session = $session_db{$self->[_key]};
	if ($session && $session->[_expires] > time) {
		$self->[_session]    = $session;
		$session->[_expires] = time + cfg_session_ttl;
	} else {
		delete $session_db{$self->[_key]};
	}
	$sobj->UnLock;
}

sub store {
	my $self = $_[0];
	tie(my %session_db, 'MLDBM::Sync', cfg_session_db_file, O_CREAT | O_RDWR, 0660) or die "$!";
	$self->[_session][_expires] = time + cfg_session_ttl;
	$session_db{$self->[_key]} = $self->[_session];
}

sub destroy {
	my $self = $_[0];
	$self->[_session][_expires] = 0;
	tie(my %session_db, 'MLDBM::Sync', cfg_session_db_file, O_CREAT | O_RDWR, 0660) or die "$!";
	delete $session_db{$self->[_key]};
}

sub data {
	my ($self, $data) = @_;
	if (defined($data)) {
		$self->[_session][_data] = $data;
	}
	$self->[_session][_data];
}

sub key {
	my ($self) = @_;
	$self->[_key];
}

sub DESTROY {
	my $self = $_[0];
	if ($self->[_session][_expires] > time) {
		$self->store;
	} else {
		$self->destroy;
	}
}

1;

__END__

=head1 NAME
 
PEF::Front::Session - Session data object

=head1 SYNOPSIS

  my $session = PEF::Front::Session->new($context->{request});
  if ($session->data->{name}) {
    $name      = $session->data->{name};
    $is_author = $session->data->{is_author};
  }

=head1 DESCRIPTION

This module allows you to easily create sessions , store data in them and 
later retrieve that information. It uses L<Storable> for data serialisation.

=head1 FUNCTIONS

=head2 new([$key])

Makes new session object. $key is unique string or request object. 
If it is empty or omitted then it will be generated.
If $key is a request object then it will be looked in request parameters 
and then in cookies for C<cfg_session_request_field> to get the key.

=head2 load()

Loads session data associated with the key.

=head2 store()

Stores session data associated with the key. You don't need to call it
usually, only when you want to synchronize data with storage.

=head2 destroy()

Destroys session data associated with the key.

=head2 key()

Returns session key.

=head2 data([$hash])

Returns and optionaly sets session data hash. 

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
