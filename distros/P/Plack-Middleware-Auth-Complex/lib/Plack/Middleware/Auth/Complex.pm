package Plack::Middleware::Auth::Complex;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.002';

use parent qw/Plack::Middleware/;
use re '/s';

use Authen::Passphrase;
use Authen::Passphrase::BlowfishCrypt;
use Bytes::Random::Secure qw//;
use Carp qw/croak/;
use DBI;
use Digest::SHA qw/hmac_sha1_base64 sha256/;
use Email::Simple;
use Email::Sender::Simple qw/sendmail/;
use MIME::Base64 qw/decode_base64/;
use Plack::Request;
use Tie::Hash::Expire;

sub default_opts {(
	dbi_connect       => ['dbi:Pg:', '', ''],
	select_user       => 'SELECT passphrase, email FROM users WHERE id = ?',
	update_pass       => 'UPDATE users SET passphrase = ? WHERE id = ?',
	insert_user       => 'INSERT INTO users (id, passphrase, email) VALUES (?,?,?)',
	mail_subject      => 'Password reset token',
	realm             => 'restricted area',
	cache_fail        => 0,
	cache_max_age     => 5 * 60,
	token_max_age     => 60 * 60,
	username_regex    => qr/^\w{2,20}$/as,
	invalid_username  => 'Invalid username',
	register_url      => '/action/register',
	passwd_url        => '/action/passwd',
	request_reset_url => '/action/request-reset',
	reset_url         => '/action/reset'
)}

sub new {
	my ($class, $opts) = @_;
	my %self = $class->default_opts;
	%self = (%self, %$opts);
	my $self = bless \%self, $class;
	$self
}

sub init {
	my ($self) = @_;
	$self->{dbh} = DBI->connect(@{$self->{dbi_connect}})              or croak $DBI::errstr;
	$self->{post_connect_cb}->($self) if $self->{post_connect_cb}; # uncoverable branch false
	$self->{insert_sth} = $self->{dbh}->prepare($self->{insert_user}) or croak $self->{dbh}->errstr;
	$self->{select_sth} = $self->{dbh}->prepare($self->{select_user}) or croak $self->{dbh}->errstr;
	$self->{update_sth} = $self->{dbh}->prepare($self->{update_pass}) or croak $self->{dbh}->errstr;
}

sub create_user {
	my ($self, $parms) = @_;
	my %parms = $parms->flatten;
	$self->{insert_sth}->execute($parms{username}, $self->hash_passphrase($parms{password}), $parms{email}) or croak $self->{insert_sth}->errstr;
}

sub get_user {
	my ($self, $user) = @_;
	$self->{select_sth}->execute($user) or croak $self->{select_sth}->errstr;
	$self->{select_sth}->fetchrow_hashref
}

sub check_passphrase {
	my ($self, $username, $passphrase) = @_;
	unless ($self->{cache}) {
		## no critic (ProhibitTies)
		tie my %cache, 'Tie::Hash::Expire', {expire_seconds => $self->{cache_max_age}};
		$self->{cache} = \%cache;
	}
	my $cachekey = sha256 "$username:$passphrase";
	return $self->{cache}{$cachekey} if exists $self->{cache}{$cachekey}; # uncoverable branch true
	my $user = $self->get_user($username);
	return 0 unless $user;
	my $ret = Authen::Passphrase->from_rfc2307($user->{passphrase})->match($passphrase);
	$self->{cache}{$cachekey} = $ret if $ret || $self->{cache_fail};
	$ret
}

sub hash_passphrase {
	my ($self, $passphrase) = @_;
	Authen::Passphrase::BlowfishCrypt->new(
		cost => 10,
		passphrase => $passphrase,
		salt_random => 1,
	)->as_rfc2307
}

sub set_passphrase {
	my ($self, $username, $passphrase) = @_;
	$self->{update_sth}->execute($self->hash_passphrase($passphrase), $username) or croak $self->{update_sth}->errstr;
}

sub make_reset_hmac {
	my ($self, $username, @data) = @_;
	$self->{hmackey} //= Bytes::Random::Secure->new(NonBlocking => 1)->bytes(512); # uncoverable condition false
	my $user = $self->get_user($username);
	my $message = join ' ', $username, $user->{passphrase}, @data;
	hmac_sha1_base64 $message, $self->{hmackey};
}

sub mail_body {
	my ($self, $username, $token) = @_;
	my $hours = $self->{token_max_age} / 60 / 60;
	$hours .= $hours == 1 ? ' hour' : ' hours'; # uncoverable branch false
	<<"EOF";
Someone has requested a password reset for your account.

To reset your password, please submit the reset password form on the
website using the following information:

Username: $username
Password: <your new password>
Reset token: $token

The token is valid for $hours.
EOF
}

sub send_reset_email {
	my ($self, $username) = @_;
	my $expire = time + $self->{token_max_age};
	my $token = $self->make_reset_hmac($username, $expire) . ":$expire";
	my $user = $self->get_user($username);
	sendmail (Email::Simple->create(
		header => [
			From    => $self->{mail_from},
			To      => $user->{email},
			Subject => $self->{mail_subject},
		],
		body => $self->mail_body($username, $token),
	));
}

##################################################

sub response {
	my ($self, $code, $body) = @_;
	return [
		$code,
		['Content-Type' => 'text/plain',
		 'Content-Length' => length $body],
		[ $body ],
	];
}

sub reply                 { shift->response(200, $_[0]) }
sub bad_request           { shift->response(400, $_[0]) }
sub internal_server_error { shift->response(500, $_[0]) }

sub unauthorized {
	my ($self) = @_;
	my $body = 'Authorization required';
	return [
		401,
		['Content-Type' => 'text/plain',
		 'Content-Length' => length $body,
		 'WWW-Authenticate' => 'Basic realm="' . $self->{realm} . '"' ],
		[ $body ],
	];
}

##################################################

sub call_register {
	my ($self, $req) = @_;
	my %parms;
	for (qw/username password confirm_password email/) {
		$parms{$_} = $req->param($_);
		return $self->bad_request("Missing parameter $_") unless $parms{$_};
	}

	return $self->bad_request($self->{invalid_username}) unless $parms{username} =~ $self->{username_regex};
	return $self->bad_request('Username already in use') if $self->get_user($parms{username});
	return $self->bad_request('The two passwords do not match') unless $parms{password} eq $parms{confirm_password};

	$self->create_user($req->parameters);
	return $self->reply('Registered successfully')
}

sub call_passwd {
	my ($self, $req) = @_;
	return $self->unauthorized unless $req->user;
	my %parms;
	for (qw/password new_password confirm_new_password/) {
		$parms{$_} = $req->param($_);
		return $self->bad_request("Missing parameter $_") unless $parms{$_};
	}

	return $self->bad_request('Incorrect password') unless $self->check_passphrase($req->user, $parms{password});
	return $self->bad_request('The two passwords do not match') unless $parms{new_password} eq $parms{confirm_new_password};
	$self->set_passphrase($req->user, $parms{new_password});
	return $self->reply('Password changed successfully');
}

sub call_request_reset {
	my ($self, $req) = @_;
	return $self->internal_server_error('Password resets are disabled') unless $self->{mail_from};
	my $username = $req->param('username');
	my $user = $self->get_user($username) or return $self->bad_request('No such user');
	eval {
		$self->send_reset_email($username);
		1
	} or return $self->internal_server_error($@);
	$self->reply('Email sent');
}

sub call_reset {
	my ($self, $req) = @_;
	my %parms;
	for (qw/username new_password confirm_new_password token/) {
		$parms{$_} = $req->param($_);
		return $self->bad_request("Missing parameter $_") unless $parms{$_};
	}

	my $user = $self->get_user($parms{username}) or return $self->bad_request('No such user');
	return $self->bad_request('The two passwords do not match') unless $parms{new_password} eq $parms{confirm_new_password};
	my ($token, $exp) = split /:/, $parms{token};
	my $goodtoken = $self->make_reset_hmac($parms{username}, $exp);
	return $self->bad_request('Bad reset token') unless $token eq $goodtoken;
	return $self->bad_request('Reset token has expired') if time >= $exp;
	$self->set_passphrase($parms{username}, $parms{new_password});
	return $self->reply('Password reset successfully');
}

sub call {
	my ($self, $env) = @_;

	unless ($self->{init_done}) {
		$self->init;
		$self->{init_done} = 1;
	}

	my $auth = $env->{HTTP_AUTHORIZATION};
	if ($auth && $auth =~ /^Basic (.*)$/i) {
		my ($user, $pass) = split /:/, decode_base64($1), 2;
		$env->{REMOTE_USER} = $user if $self->check_passphrase($user, $pass);
	}

	my $req = Plack::Request->new($env);

	if ($req->method eq 'POST') {
		return $self->call_register($req)      if $req->path eq $self->{register_url};
		return $self->call_passwd($req)        if $req->path eq $self->{passwd_url};
		return $self->call_request_reset($req) if $req->path eq $self->{request_reset_url};
		return $self->call_reset($req)         if $req->path eq $self->{reset_url};
	}

	$env->{authcomplex} = $self;
	$self->app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::Auth::Complex - Feature-rich authentication system

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
    enable 'Auth::Complex', dbi_connect => ['dbi:Pg:dbname=mydb', '', ''], mail_from => 'nobody@example.org';
    sub {
      my ($env) = @_;
      [200, [], ['Hello ' . ($env->{REMOTE_USER} // 'unregistered user')]]
    }
  }

=head1 DESCRIPTION

AuthComplex is an authentication system for Plack applications that
allows user registration, password changing and password reset.

AuthComplex sets REMOTE_USER if the request includes correct basic
authentication and intercepts POST requests to some configurable URLs.
It also sets C<< $env->{authcomplex} >> to itself before passing the
request.

Some options can be controlled by passing a hashref to the
constructor. More customization can be achieved by subclassing this
module.

=head2 Intercepted URLs

Only POST requests are intercepted. Parameters can be either query
parameters or body parameters. Using query parameters is not
recommended. These endpoints return 200 for success, 400 for client
error and 500 for server errors. All parameters are mandatory.

=over

=item B<POST> /action/register?username=user&password=pw&confirm_password=pw&email=user@example.org

This URL creates a new user with the given username, password and
email. The two passwords must match, the user must match
C<username_regex> and the user must not already exist.

=item B<POST> /action/passwd?password=oldpw&new_password=newpw&confirm_new_password=newpw

This URL changes the password of a user. The user must be
authenticated (otherwise the endpoint will return 401).

=item B<POST> /action/request-reset?username=user

This URL requests a password reset token for the given user. The token
will be sent to the user's email address.

A reset token in the default implementation is C<< base64(HMAC-SHA1("$username $passphrase $expiration_unix_time")) . ":$expiration_user_time" >>.

=item B<POST> /action/reset?username=user&new_password=pw&confirm_new_password=pw&token=token

This URL performs a password reset.

=back

=head2 Constructor arguments

=over

=item dbi_connect

Arrayref of arguments to pass to DBI->connect. Defaults to
C<['dbi:Pg', '', '']>.

=item post_connect_cb

Callback (coderef) that is called just after connecting to the
database. Used by the testsuite to create the users table.

=item select_user

SQL statement that selects a user by username. Defaults to
C<'SELECT id, passphrase, email FROM users WHERE id = ?'>.

=item update_pass

SQL statement that updates a user's password. Defaults to
C<'UPDATE users SET passphrase = ? WHERE id = ?'>.

=item insert_user

SQL statement that inserts a user. Defaults to
C<'INSERT INTO users (id, passphrase, email) VALUES (?,?,?)'>.

=item hmackey

HMAC key used for password reset tokens. If not provided it is
generated randomly, in which case reset tokens do not persist across
application restarts.

=item mail_from

From: header of password reset emails. If not provided, password reset
is disabled.

=item mail_subject

The subject of password reset emails. Defaults to
C<'Password reset token'>.

=item realm

Authentication realm. Defaults to C<'restricted area'>.

=item cache_fail

If true, all authentication results are cached. If false, only
successful logins are cached. Defaults to false.

=item cache_max_age

Authentication cache timeout, in seconds. Authentication results are
cached for this number of seconds to avoid expensive hashing. Defaults
to 5 minutes.

=item token_max_age

Password reset token validity, in seconds. Defaults to 1 hour.

=item username_regex

Regular expression that matches valid usernames. Defaults to
C<qr/^\w{2,20}$/as>.

=item invalid_username

Error message returned when the username does not match
username_regex. Defaults to C<'Invalid username'>

=item register_url

URL for registering. Defaults to C<'/action/register'>.

=item passwd_url

URL for changing your password. Defaults to C<'/action/passwd'>.

=item request_reset_url

URL for requesting a password reset token by email. Defaults to
C<'/action/request-reset'>.

=item reset_url

URL for resetting your password with a reset token. Defaults to
C<'/action/reset'>.

=back

=head2 Methods

=over

=item B<default_opts>

Returns a list of default options for the constructor.

=item B<new>(I<\%opts>)

Creates a new AuthComplex object.

=item B<init>

Called when the first request is received. The default implementation
connects to the database, calls C<post_connect_cb> and prepares the
SQL statements.

=item B<create_user>(I<$parms>)

Inserts a new user into the database. I<$parms> is a
L<Hash::MultiValue> object containing the request parameters.

=item B<get_user>(I<$username>)

Returns a hashref with (at least) the following keys: passphrase (the
RFC2307-formatted passphrase of the user), email (the user's email
address).

=item B<check_passphrase>(I<$username>, I<$passphrase>)

Returns true if the given plaintext passphrase matches the one
obtained from database. Default implementation uses L<Authen::Passphrase>.

=item B<hash_passphrase>(I<$passphrase>)

Returns a RFC2307-formatted hash of the passphrase. Default
implementation uses L<Authen::Passphrase::BlowfishCrypt> with a cost
of 10 and a random salt.

=item B<set_passphrase>(I<$username>, I<$passphrase>)

Changes a user's passphrase to the given value.

=item B<make_reset_hmac>(I<$username>, [I<@data>])

Returns the HMAC part of the reset token.

=item B<mail_body>(I<$username>, I<$token>)

Returns the body of the password reset email for the given username
and password reset token.

=item B<send_reset_email>(I<$username>)

Generates a new reset token and sends it to the user via email.

=item B<response>(I<$code>, I<$body>)

Helper method. Returns a PSGI response with the given response code
and string body.

=item B<reply>(I<$message>)

Shorthand for C<response(200, $message)>.

=item B<bad_request>(I<$message>)

Shorthand for C<response(400, $message)>.

=item B<internal_server_error>(I<$message>)

Shorthand for C<response(500, $message)>.

=item B<unauthorized>

Returns a 401 Authorization required response.

=item B<call_register>(I<$req>)

Handles the C</action/register> endpoint. I<$req> is a Plack::Request object.

=item B<call_passwd>(I<$req>)

Handles the C</action/passwd> endpoint. I<$req> is a Plack::Request object.

=item B<call_request_reset>(I<$req>)

Handles the C</action/request-reset> endpoint. I<$req> is a Plack::Request object.

=item B<call_reset>(I<$req>)

Handles the C</action/reset> endpoint. I<$req> is a Plack::Request object.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
