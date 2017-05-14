package MyLibrary::Auth::Basic;

use base qw(MyLibrary::Auth);
use MyLibrary::Patron;
use Carp qw(croak cluck); 
use strict;

=head1 NAME

MyLibrary::Auth::Basic

=head1 SYNOPSIS

		use MyLibrary::Auth::Basic;

		# create a new authentication object
		my $auth = MyLibrary::Auth::Basic->new();
		my $auth = MyLibrary::Auth::Basic->new(sessid => $sessid);

		# access session attributes
		my $sessid = $auth->sessid();
		my $status = $auth->status();
		my $username = $auth->username();

		# authenticate
		my $return_code = $auth->authenticate(username => 'user', password => 'password');

		# place session cookie
		$auth->place_cookie();

		# remove session cookie
		$auth->remove_cookie();

		# close a session
		$auth->close_session();

=head1 DESCRIPTION

This method of authentication uses an internal mechanism to MyLibrary, with a simply encryption scheme. The user credentials are stored within the MyLibrary database structure. Users are required to create their own usernames and passwords, and are thus required to memorize them separately from any institutional authentication system. Changing the username and password is handled via the Patron.pm API.

=head1 METHODS

=head2 new()

This is the constructor for the class. It creates an object with a default set of attributes if no session id is supplied, and initializes the attributes according to session data previously saved if a session id is supplied. This object uses encapsulated data, so the only means to manipulate session variables is via the supplied API. This is done for security reasons and to help maintain data integrity.

        # create a new auth object
        my $auth = MyLibrary::Auth->new();

        # create an auth object based upon session id
        my $auth = MyLibrary::Auth->new(sessid => $sessid);

=head2 sessid()

Get the session id for the current auth object. This method cannot set the session id, only retrieve it.

        # get the session id
        my $sessid = $auth->sessid();

=head2 status()

Retrieve the status for this session. There are several status indicators based upon whether or not the user was able to successfully authenticate or is in the process of authentication. The state of authentication status can only be changed internal to the object itself.

        # status info
        my $status = $auth->status();

=head2 username()

The username is the name entered for authentication purposes and is retained throughout the life of the session. This is used to identify who the last person was to authenticate from the host where authentication was initiated.

        # username
        my $username = $auth->username();

=head2 place_cookie()

This method will return a header used to place a cookie with the browser initiating the authentication request.

        # place a cookie
        my $place_cookie_header = $auth->place_cookie();

=head2 remove_cookie()

This method return a header that will delete a cookie from the browser for the current session. This usually occurs when the user indicate that they would like their session terminated.

        # delete a cookie
        my $remove_cookie_header = $auth->remove_cookie();


=head2 authenticate()

This method is used to simply receive a message as a return value indicating the status of an authentication attempt. The two required parameters are username and password. If either of these is not present, then the method will return an error message.

	# authenticate
	my $return_code = $auth->authenticate(username => 'joe', password => 'password');


=head2 close_session()

This method will delete the session object from the database, and it will no longer be accessible using the session id.

        # close the session
        $auth->close_session()

=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>

=cut


{
		# Allowable object attributes with defaults
        my %_attr_data =
			(	auth_method				=> 'BASIC',
				crypt_password			=> undef,
				file					=> __FILE__
                );

		# Class methods used to operate on encapsulated data
		sub _attr_defaults {
			return \%_attr_data;
        }
        sub _standard_keys {
                keys %_attr_data;
        }
}

sub _encrypt_password {
	my $self = shift;
	my $password = shift;
	if (defined $password) {
		my $salt = substr($password, 0, 2);
		my $crypted_pw = crypt($password, $salt);
		return $crypted_pw;
	} else {
		croak "Password not indicated for encryption.\n";
	}
}

sub authenticate {
	my $self = shift;
	my %args = @_;
	if (defined $args{username} && defined $args{password} && $args{username} ne '' && $args{password} ne '' && $args{username} !~ /^\s/ && $args{password} !~ /^\s/) {
		my $patron = MyLibrary::Patron->new(username => $args{username});
		unless (defined $patron) {
			my $_auth_obj = $self->SUPER::_attr_hash();
			$_auth_obj->{${$self}}->{status_accessor}->($self, 'failed authentication - user not in patron table');
			$_auth_obj->{${$self}}->{_sess_ref}->param('status', $self->status());
			return 'username failure';
		}
		my $crypt_password = $self->_encrypt_password($args{password});
		if ($crypt_password eq $patron->patron_password()) {
			my $_auth_obj = $self->SUPER::_attr_hash();
			$_auth_obj->{${$self}}->{status_accessor}->($self, 'authenticated');
			$_auth_obj->{${$self}}->{crypt_password} = $crypt_password;
			$_auth_obj->{${$self}}->{username} = $args{username};
			$_auth_obj->{${$self}}->{user_id} = $patron->patron_id();
			$_auth_obj->{${$self}}->{_sess_ref}->param('crypt_password', $crypt_password);
			$_auth_obj->{${$self}}->{_sess_ref}->param('username', $args{username});
			$_auth_obj->{${$self}}->{_sess_ref}->param('user_id', $patron->patron_id());
			$_auth_obj->{${$self}}->{_sess_ref}->param('_logged_in', '1');
			$_auth_obj->{${$self}}->{_sess_ref}->param('status', $self->status());
			$_auth_obj->{${$self}}->{_sess_ref}->expire('_logged_in', '+1m');
			return 'success';
		} else {
			my $_auth_obj = $self->SUPER::_attr_hash();
			$_auth_obj->{${$self}}->{status_accessor}->($self, 'failed authentication - invalid password');
			$_auth_obj->{${$self}}->{_sess_ref}->param('status', $self->status());
			$_auth_obj->{${$self}}->{_sess_ref}->param('_logged_in', '0');
			return 'password failure';
		}
	} else {
		return 'error';
	}
}

1;
