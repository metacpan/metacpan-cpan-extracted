package Net::Server::Mail::ESMTP::AUTH;

use 5.006;
use strict;
use base qw(Net::Server::Mail::ESMTP::Extension);
use MIME::Base64;

use vars qw( $VERSION );
$VERSION = '0.2';

=head1 NAME

Net::Server::Mail::ESMTP::AUTH - SMTP Authentification extensions for Net::Server::Mail::ESMTP

=head1 SYNOPSIS

  use Net::Server::Mail::ESMTP;
  my @local_domains = qw(example.com example.org);
  my $server = new IO::Socket::INET Listen => 1, LocalPort => 25;

  my $conn;
  while($conn = $server->accept)
  {
    my $esmtp = new Net::Server::Mail::ESMTP socket => $conn;
  
    # activate AUTH extension
    $esmtp->register('Net::Server::Mail::ESMTP::AUTH');

    # adding AUTH handler
    $esmtp->set_callback(AUTH => \&validate_auth);
    $esmtp->set_callback(DATA => \&queue_message);
    $esmtp->process;
  }

  sub validate_auth
  {
    my ($session, $username, $password) = @_;

    if ($username eq 'ROBERT' and $password eq 'TOTO04') {
      # AUTH SUCCESFULL
      $session->{AUTH}->{ok} = 1;
      return 1;
    } else {
      # AUTH FAILED
      return 0;
    }
  }

sub queue_message {
    my($session, $data) = @_;

    # providing AUTH doesn't make it mandatory.
    # A client might not use AUTH at all!
    # You must deal now with permissions:

    unless ($session->{AUTH}->{ok}) {
        # warn "no AUTH supplied!";
        return(0, 530, 'Error: Authentication required');
    }
    ... do stuff
}

=head1 FEATURES

  * AUTH LOGIN method support
  * AUTH PLAIN method support

=head1 DESCRIPTION

"Net::Server::Mail::ESMTP::AUTH" is an extension to provide
ESMTP Authentification support to Net::Server::Mail::ESMTP module.
Actually only AUTH LOGIN and AUTH PLAIN methods are supported.

AUTH callback is called with login and password who was given
by user's mail client, AUTH callback should return 1 when authentification
mechanism was succesfull otherwise 0.

=cut

our $verb = 'AUTH';

sub init
{
	my ($self, $parent) = @_;
	$self->{AUTH} = ();

	return $self;
}

sub verb
{
	return ( [ 'AUTH' => \&process, ],);
}

sub keyword
{
	return 'AUTH LOGIN PLAIN';
}

sub reply
{
	return ( [ 'AUTH', ]);
}

sub process_authlogin_username
{
  my ($self, $operation) = @_;
	$self->{AUTH}->{username} = decode_base64($operation);
	$self->{AUTH}->{password} = '';
	$self->reply(334, "UGFzc3dvcmQ6");
	$self->next_input_to(\&process_authlogin_password);
	return ();
}

sub process_authlogin_password
{
	my ($self, $operation) = @_;
	$self->{AUTH}->{password} = decode_base64($operation);

	return exec_auth_callback($self);
}

sub exec_auth_callback
{
	my ($self) = @_;

	my $authok=0;

	my $ref = $self->{callback}->{AUTH};
	if (ref $ref eq 'ARRAY' && ref $ref->[0] eq 'CODE') {
		my $code = $ref->[0];

		$authok = &$code($self, $self->{AUTH}->{username}, $self->{AUTH}->{password});
	}

	if ($authok) {
		$self->reply(235, "Authentification successful.");
		return ();
	} else {
 		$self->reply(535, "Authentification failed.");
		return 1;
	}
}

sub process
{
	my ($self, $data) = @_;
	my ($operation, $param) = $data=~/^(.+?)\s(.*)$/ ? ($1, $2) : ($data, '');

	$self->{AUTH}->{type} = $operation;
	map { $self->{AUTH}->{$_} = '' } ('username', 'password', 'challenge', 'ticket', );

	if ($operation eq '*') {
 	  $self->reply(501, "Authentification aborted.");
		return ();
	} elsif ($operation eq 'PLAIN') {
		$param=decode_base64($param);
		my @plaindata = split /\0/, $param;
		unless (@plaindata > 2) {
  		$self->reply(535, "Authentification failed.");
			return ();
		} else {
			$self->{AUTH}->{username} = $plaindata[@plaindata-2];
			$self->{AUTH}->{password} = $plaindata[@plaindata-1];
			return exec_auth_callback($self);
		}
	} elsif ($operation eq 'LOGIN') {
		$param=decode_base64($param);
		# warn " ==> LOGIN ==> $param\n";
		$self->reply(334, "VXNlcm5hbWU6");
		$self->next_input_to(\&process_authlogin_username);
		return ();
	} else {
		$self->reply(504, "Unrecognized authentification type.");
  }

	return ();
}

=pod

=head1 SEE ALSO

Please, see L<Net::Server::Mail::SMTP> and L<Net::Server::Mail::ESMTP> for
more documentations.

=head1 AUTHOR

Sylvain Cresto E<lt>scresto@gmail.comE<gt>

Thanks to Chris E<lt>chris at u- club.deE<gt>

=head1 BUGS

Please send bug-reports to scresto@gmail.com.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 COPYRIGHT

Copyright (C) 2004, 2016 - Sylvain Cresto

=cut

1;
