package MyLibrary::Auth;

use MyLibrary::Patron;
use MyLibrary::Config;
use MyLibrary::DB;
use CGI::Session qw/-ip-match/;
use Carp qw(croak);

use strict;

=head1 NAME

MyLibrary::Auth

=head1 SYNOPSIS

        use MyLibrary::Auth;

		# create a new authentication object
		my $auth = MyLibrary::Auth->new();
		my $auth = MyLibrary::Auth->new(sessid => $sessid);

		# access session attributes
		my $sessid = $auth->sessid();
		my $status = $auth->status();
		my $username = $auth->username();
		
		# place session cookie
		$auth->place_cookie();

		# remove session cookie
		$auth->remove_cookie();	

		# close a session
		$auth->close_session();

=head1 DESCRIPTION

This is the user authentication system for MyLibrary. The parent module, Auth.pm, references several child modules that implement various types of authentication methods. The functionality associated with creating an authentication object and then performing auth functions against it is uniform for each type of authentication. This module encapsulates data somewhat tightly in order to protect the privacy and security of the user. This module assumes authentication through a web browser, however, the module could also be used for simple authentication in almost any context.

This system uses CGI sessions to maintain state. Several pieces of data are stored in the session ticket. Except for Basic authentication, the password for the user is never recorded. If this module is used for web authentication, then HTTPS should also be used for encryption. This authentication system is designed to be extensible. Several modules will be written that inherit from this parent class. Child classes include Kerberos, Basic and LDAPS as various means to perform authentication. However, the system can easily be extended to include other authentication means.

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

=head2 close_session()

This method will delete the session object from the database, and it will no longer be accessible using the session id.

	# close the session
	$auth->close_session()

=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>

=cut


# Stores references to hashes containing object data
my %_auth_obj;

	{
		# Allowable object attributes with defaults
		my %_attr_data =
			(	sessid			=> undef,
			  	status			=> 'not authenticated',
				user_id			=> undef,
				username		=> undef,
				session_expire	=> undef,
				file			=> __FILE__ 
			);
		# Class methods used to operate on encapsulated data
		sub _attr_defaults {
			my $sessid = shift;
			$_attr_data{'sessid'} = $sessid;
			return \%_attr_data;
		}

		sub _standard_keys {
			keys %_attr_data;
		}
	}


sub new {
	my ($self, %args) = @_;
	my $class = ref($self) || $self;
	my $dbh = MyLibrary::DB->dbh();
	if (my $sessid = $args{sessid}) {
		my $session;
		if ($MyLibrary::Config::DATA_SOURCE =~ /mysql/) {
			$session = CGI::Session->new("driver:mysql", $sessid, { Handle => $dbh });
		} else {
			$session = CGI::Session->new("driver:File", $sessid, {Directory=>$MyLibrary::Config::SESSION_DIR});
		}
		my $_attr_flds_ref = {};
		my $_session_params = $session->param_hashref();
		foreach my $attr (keys %$_session_params) {
		
			# changed, based on http://www.issociate.de/board/post/260444/Deprecated_perl_hash_reference_statement_problem.html --ELM
			#$_attr_flds_ref->{$attr} = %$_session_params->{$attr};
			$_attr_flds_ref->{$attr} = ${$_session_params}{$attr};

		}
		$_attr_flds_ref->{status_accessor} = sub {
			my $self = shift;
			my $status = shift;
			if (defined($status) && $status =~ /^not authenticated$|^authenticated$|^failed authentication - invalid username$|^failed authentication - invalid password$|^failed authentication - user not in patron table$|^expired$/) {
				return $_auth_obj{${$self}}->{status} = $status;
			} else {
				return $_auth_obj{${$self}}->{status};
			}
		};
		$_attr_flds_ref->{_sess_ref} = $session;
		$_attr_flds_ref->{_key} = rand
			until $_attr_flds_ref->{_key} && !exists $_auth_obj{$_attr_flds_ref->{_key}};
		$_auth_obj{$_attr_flds_ref->{_key}} = $_attr_flds_ref;
		return bless(\$_attr_flds_ref->{_key}, $class);		
	} else {
		my $session;
		if ($MyLibrary::Config::DATA_SOURCE =~ /mysql/) {
			$session = CGI::Session->new("driver:mysql", undef, { Handle => $dbh });
		} else {	
			$session = CGI::Session->new("driver:File", undef, {Directory=>$MyLibrary::Config::SESSION_DIR});
		}
		my $sessid = $session->id();
		my $_base_attr_fields = _attr_defaults($sessid);
		my $_attr_fields = $self->_attr_defaults();
		my $_attr_flds_ref = {%{$_base_attr_fields}, %{$_attr_fields}};
		foreach my $attr (keys %{$_attr_flds_ref}) {
			$_attr_flds_ref->{$attr} = $args{$attr} if defined $args{$attr};
			$session->param($attr, $_attr_flds_ref->{$attr});
		}
		$_attr_flds_ref->{status_accessor} = sub {
			my $self = shift;
			my $status = shift;
			if (defined($status) && $status =~ /^not authenticated$|^authenticated$|^failed authentication$|^expired$/) {
				return $_auth_obj{${$self}}->{status} = $status;
			} else {
				return $_auth_obj{${$self}}->{status};
			}
		};
		$_attr_flds_ref->{_sess_ref} = $session;
		$_attr_flds_ref->{_key} = rand
			until $_attr_flds_ref->{_key} && !exists $_auth_obj{$_attr_flds_ref->{_key}};
		$_auth_obj{$_attr_flds_ref->{_key}} = $_attr_flds_ref;
		return bless(\$_attr_flds_ref->{_key}, $class);
	}
}

sub sessid {
	my $self = shift;
	return $_auth_obj{${$self}}->{sessid};
}

sub status {
	my $self = shift;
	if ($_auth_obj{${$self}}->{status_accessor}->($self) eq 'authenticated') {
		unless ($self->_logged_in()) {
			$_auth_obj{${$self}}->{status_accessor}->($self, 'expired');
			return $_auth_obj{${$self}}->{status_accessor}->($self);
		}
		return $_auth_obj{${$self}}->{status_accessor}->($self);
	} else {
		return $_auth_obj{${$self}}->{status_accessor}->($self);
	}
}

sub user_id {
	my $self = shift;
	return $_auth_obj{${$self}}->{user_id};
}

sub username {
	my $self = shift;
	return $_auth_obj{${$self}}->{username};
}

sub _logged_in {
	my $self = shift;
	return $_auth_obj{${$self}}->{_sess_ref}->param('_logged_in');
}

sub place_cookie {
	my $self = shift;
	return $self->_header();	
}

sub remove_cookie {
	my $self = shift;
	return $self->_header(action => 'remove');
}

sub close_session {

	my $self = shift;
	my $session = $_auth_obj{${$self}}->{_sess_ref};
	$session->delete();
	return 1;

}

sub _header {
	my $self = shift;
	my %args = @_;
	my $session = $_auth_obj{${$self}}->{_sess_ref};
	my $expire_time;
	my $cgi = $session->{_SESSION_OBJ};
	unless ( defined $cgi ) {
		require CGI;
		$session->{_SESSION_OBJ} = CGI->new();
		$cgi = $session->{_SESSION_OBJ};
	}
	if (defined $args{action} && $args{action} eq 'remove') {
		$expire_time = '-1d';
	} else {
		$expire_time = '+10M';
	}
	my $cookie = $cgi->cookie(-name=>'mylib_sessid',-value=>$session->id(), -path=>$MyLibrary::Config::RELATIVE_PATH,
								-domain=>$MyLibrary::Config::COOKIE_DOMAIN, -expires=>$expire_time);
	return $cgi->header(
		-type   => 'text/html',
		-cookie => $cookie,
		@_
	);
}

sub _attr_hash {
	my $self = shift;
	my @caller = caller();
	if ($caller[0] eq 'main' || $caller[0] !~ /^MyLibrary::Auth::\w+/ || $caller[1] ne $_auth_obj{${$self}}->{file}) {
		croak "Illegal call to private MyLibrary::Auth method";
	}
	return \%_auth_obj;
}

1;
