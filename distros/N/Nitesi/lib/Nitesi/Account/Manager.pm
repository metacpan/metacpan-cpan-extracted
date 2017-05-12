package Nitesi::Account::Manager;

use strict;
use warnings;

use Moo;

use Nitesi::Class;
use Nitesi::Account::Password;
use ACL::Lite 0.0002;

=head1 NAME

Nitesi::Account::Manager - Account Manager for Nitesi Shop Machine

=head1 SYNOPSIS

    $account = Nitesi::Account::Manager->new(provider_sub => \&account_providers, 
                                               session_sub => \&session);

    $account->init_from_session;

    $account->status(login_info => 'Please login before checkout',
                  login_continue => 'checkout');

    $account->login(username => 'shopper@nitesi.biz', password => 'nevairbe');

    $account->logout();

    if ($account->exists('shopper@nitesi.biz')) {
        $account->password(username => 'shopper@nitesi.biz', password => 'nevairbe');
    }

    $account->create(email => 'shopper@nitesi.biz');

    # use this with caution!
    $account->become('shopper@nitesi.biz');

=head1 DESCRIPTION

Nitesi's account manager transparently handles multiple providers for authentication,
account data and permissions checks.

=head1 METHODS

=head2 init

Initializer called by instance class method.

=cut

has password_manager => (
    is => 'rw',
    lazy => 1,
    default => sub {Nitesi::Account::Password->new;},
);

=head2 providers

List with account providers.

=cut

has providers => (
    is => 'ro',
);

has session_sub => (
    is => 'rw',
    lazy => 1,
    default => sub {sub {return 1;}},
);

sub BUILDARGS {
    my ($class, %args) = @_;
    my ($ret, @list, $init);

    $args{providers} = [];
    
    if ($args{provider_sub}) {
        # retrieve list of providers
        $ret = $args{provider_sub}->();
	
        if (ref($ret) eq 'HASH') {
            # just one provider
            @list = ($ret);
        }
        elsif (ref($ret) eq 'ARRAY') {
            @list = @$ret;
        }

        # instantiate provider objects
        for $init (@list) {
            push @$init, 'crypt', Nitesi::Account::Password->new;
            push @{$args{providers}}, Nitesi::Class->instantiate(@$init);
        }

        delete $args{provider_sub};
    }

    return \%args;
}

=head2 init_from_session

Reads user information through session routine.

=cut

sub init_from_session {
    my $self = shift;

    $self->{account} = $self->{session_sub}->()
        || {uid => 0, username => '', roles => []};

    $self->{acl} = ACL::Lite->new(permissions => $self->{account}->{permissions});

    return;
}

=head2 login

Perform login. Returns 1 in case of success and
0 in case of failure.

Leading and trailing spaces will be removed from
username and password in advance.

=cut

sub login {
    my ($self, %args) = @_;
    my ($success, $acct);

    $success = 0;

    # remove leading/trailing spaces from username and password
    $args{username} =~ s/^\s+//;
    $args{username} =~ s/\s+$//;

    $args{password} =~ s/^\s+//;
    $args{password} =~ s/\s+$//;

    my $id = 0;

    for my $p (@{$self->{providers}}) {
        if ($acct = $p->login(%args)) {
            $acct->{provider_id} = $id;
            $self->session_sub->('init', $acct);
            $self->{account} = $acct;
            $self->{acl} = ACL::Lite->new(permissions => $self->{account}->{permissions},
                                          uid => $acct->{uid});
            $success = 1;
            last;
        }
        $id++;
    }

    return $success;
}

=head2 logout

Perform	logout.


B<Example:>

	$account->logout();

=cut

sub logout {
    my ($self, %args) = @_;
    my ($provider);

    # log out if the user is authenticated, so skip it if uid is 0 (as
    # per doc of uid).
    if ($self->uid) {
        $provider = $self->{providers}->[$self->{account}->{provider_id}];

        if ($provider->can('logout')) {
            $self->{providers}->[$self->{account}->{provider_id}]->logout;
        }

        delete $self->{account};
        $self->{acl} = ACL::Lite->new;
    }

    $self->session_sub->('destroy');
}

=head2 create

Creates account and returns uid for the new account
in case of success.

B<Example:>

    $uid = $account->create(email => 'shopper@nitesi.biz');

The password is automatically generated unless you pass it to
this method.

B<Example:>

    $uid = $account->create(email => 'shopper@nitesi.biz',
                  password => 'nevairbe');

=cut

sub create {
    my ($self, %args) = @_;
    my ($password, $uid);
    
    # remove leading/trailing spaces from arguments
    for my $name (keys %args) {
        if (defined $args{$name}) {
            $args{$name} =~ s/^\s+//;
            $args{$name} =~ s/\s+$//;
        }
    }

    unless (exists $args{username} && $args{username} =~ /\S/) {
        $args{username} = lc($args{email});
    }

    # password is added after account creation
    unless ($password = delete $args{password}) {
        $password = $self->password_manager->make_password;
    }

    for my $p (@{$self->{providers}}) {
        next unless $p->can('create');

        if ($p->exists($args{username})) {
            die "Account already exists: ", $args{username};
        }

        if ($uid = $p->create(%args)) {
            $self->password(username => $args{username},
                            password => $password);
            last;
        }
    }

    return $uid;
}

=head2 delete

Delete account.

B<Example:>

	$account->delete('333');

=cut

sub delete {
    my ($self, $uid, $p);

    $self = shift;

    if (@_) {
        $uid = shift;
    }
    else {
        $uid = $self->uid;
    }

    for $p (@{$self->{providers}}) {
        if ($p->load($uid)) {
            return $p->delete($uid);
        }
    }

    return;
}

=head2 uid

Retrieve user identifier of the current user, returns 0 if current user
isn't authenticated.

B<Example:>

	$account->uid();

=cut

sub uid {
    my $self = shift;

    return $self->{account}->{uid} || 0;
}

=head2 username

Retrieve username of the current user. Returns empty string if current user
isn't authenticated. If you want to retrieve other user username, use $account->load.

B<Example:>

	$account->username();

=cut

sub username {
    my $self = shift;

    return $self->{account}->{username};
}

=head2 roles

Retrieve roles of current user.

B<Example:>

	$account->roles();

=cut

sub roles {
    my $self = shift;

    wantarray ? @{$self->{account}->{roles}} : $self->{account}->{roles};
}

=head2 has_role

Returns true if user is a member of the given role.

B<Example:>

	if ($account->has_role('admin') { print "Congratulations, you are the admin" };

=cut

sub has_role {
    my ($self, $role) = @_;

    grep {$role eq $_} @{$self->{account}->{roles}};
}

=head2 permissions

Returns permissions as hash reference:

    $perms = $account->permissions;

Returns permissions as list:

    @perms = $account->permissions;

=cut

sub permissions {
    my ($self) = @_;

    return $self->{acl}->permissions;
}

=head2 status

Helps you to redirect users properly on pages available only to authenticated users.

B<Example:> Before login - Page available only if you are logged in (Step 1)

You are not logged in. You are on a page which is available only to those logged in.
You set the message for users not logged in and url of the page where you send them after successful login.

	$account->status(login_info => 'Please login before checkout', login_continue => 'checkout');

B<Example:> At Login page (Step 2)

You retrieve the login message to make clear to user why they need to login (to access the page from step 1) 

	$account->status('login_info');

B<Example:> After login (Step 3)

Retrieve the login_continue URL and send user to that URL (using redirect or something similar).

	$account->status('login_continue');

=cut

sub status {
    my ($self, @args) = @_;

    if (@args > 1) {
	# update status information
	$self->{account} = $self->session_sub->('update', {@args});
    }
    elsif (@args == 1) {
        if (exists $self->{account}->{$args[0]}) {
            return $self->{account}->{$args[0]};
        }
        else {
            return '';
        }
    }
}

=head2 exists

Check whether account exists.

B<Example:>

  if ($account->exists('shopper@nitesi.biz')) {
        print "Account exists\n";
  }

=cut

sub exists {
    my ($self, $username) = @_;

    return unless defined $username && $username =~ /\S/;

    for my $p (@{$self->{providers}}) {
	if ($p->exists($username)) {
	    return $p;
	}
    }
}

=head2 load

Returns account data for a given uid as hash.

B<Example:>

	$account->load('333');

=cut

sub load {
    my ($self, $uid) = @_;
    my ($data);

    for my $p (@{$self->{providers}}) {
        if ($data = $p->load($uid)) {
            return $data;
        }
    }
}

=head2 password

Changes password for current account:

    $account->password('nevairbe');

Changes password for other account:

    $account->password(username => 'shopper@nitesi.biz',
                    password => 'nevairbe');

=cut

sub password {
    my $self = shift;
    my ($provider, %args);

    if (@_ == 1) {
	# new password only
	unless ($self->{account}->{username}) {
	    die "Cannot change password for anonymous user";
	}

	$args{username} = $self->{account}->{username};
	$args{password} = shift;
    }
    else {
	%args = @_;

	unless ($provider = $self->exists($args{username})) {
	    die "Cannot change password for user $args{username}.";
	}
    }

    $provider->password($self->password_manager->password($args{password}),
			$args{username});
}

=head2 acl

ACL (Access list) check, see L<ACL::Lite> for details.

B<Example:>

	if ( $account->acl( check => 'view_prices') {
		print "You can see prices";
	}


B<Example:>

If you check multiple permissions at once, only one has to granted.
The check will return the name of the first granted one in the list (left to right).

	if ( $account->acl( check => [ qw/admin luka/ ] ) {
		print "This is Luka's account. Only Luka and administrators can see it".
	}

=cut

sub acl {
    my ($self, $function, @args) = @_;

    if ($self->{acl}) {
	if ($function eq 'check') {
	    $self->{acl}->check(@args);
	}
    }
}

=head2 value

Retrieve or set account data.

B<Example:> Retrieve city

	$city = $account->value( 'city');

B<Example:> Set city

	$city = $account->value( city => 'Ljubljana');

=cut

sub value {
    my ($self, $name, $value) = @_;

    if (@_ == 3) {
	# update value
	my ($username, $provider);

	$username = $self->{account}->{username};

	unless ($provider = $self->exists($username)) {
	    die "Cannot change value $name for user $username.";
	}

	$provider->value($username, $name, $value);
	$self->{account} = $self->session_sub->('update', {$name => $value});

	return $value;
    }

    if (exists $self->{account}->{$name}) {
	return $self->{account}->{$name};
    }
}

=head2 last_login

Returns time of last login (before the current one) in seconds
since epoch or undef if provider doesn't supply this information.

=cut

sub last_login {
    my ($self) = @_;

    return $self->{account}->{last_login};
}

=head2 become

Become any user you want:
    
    $acct->become('shopper@nitesi.biz');

Please use this method with caution.

Some parts of the system (DBI, LDAP,...) may choose not to support this method.

=cut

sub become {
    my ($self, $username) = @_;
    my ($p, $acct);

    my $id = 0;

    for $p (@{$self->{providers}}) {
        if ($p->can('become')) {
            if ($acct = $p->become($username)) {
                $acct->{provider_id} = $id;
                $self->session_sub->('init', $acct);
                $self->{account} = $acct;
                $self->{acl} = ACL::Lite->new(permissions => $self->{account}->{permissions},
                                              uid => $acct->{uid});
                return 1;
            }
        }

        $id++;
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
