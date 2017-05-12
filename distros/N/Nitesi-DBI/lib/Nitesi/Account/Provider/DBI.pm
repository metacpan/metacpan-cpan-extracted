package Nitesi::Account::Provider::DBI;

use strict;
use warnings;

use Moo;
use Nitesi::Query::DBI;

=head1 NAME

Nitesi::Account:Provider::DBI - DBI Account Provider for Nitesi Shop Machine

=cut

=head1 ATTRIBUTES

=over 4

=item dbh

DBI handle (required).

=item crypt

L<Account::Manager::Password> instance (required).

=item fields

List of fields (as array reference) to be retrieved from the
database and put into account data return by login method.

=back

=cut

has dbh => (
    is => 'rw',
);

has crypt => (
    is => 'rw',
);

has fields => (
    is => 'rw',
);

has sql => (
    is => 'ro',
    lazy => 1,
    default => sub {my $self = shift;
                    Nitesi::Query::DBI->new(dbh => $self->{dbh});
                },
);

=head1 METHODS

=head2 login

Check parameters username and password for correct authentication.

Returns hash reference with the following values in case of success:

=over 4

=item uid

User identifier

=item username

Username

=item roles

List of roles for this user.

=item permissions

List of permissions for this user.

=back

=cut

sub login {
    my ($self, %args) = @_;

    my $ret = $self->_account_retrieve(\%args);

    if ($ret) {
        if (defined $self->{inactive} && $ret->{$self->{inactive}}) {
            # disabled user
            return 0;
        }

        if ($self->crypt->check($ret->{password}, $args{password})) {
            # initialize account and return data
            return $self->_account_init($ret);
        }
    }

    return 0;
}

=head2 create

Creates an account.

=cut
    
sub create {
    my ($self, %args) = @_;
    my ($values, $password, $uid);

    $values = {%args};

    $password = delete $values->{password};

    $args{created} ||= \['now()'];
        
    $uid = $self->sql->insert('users', {%args});
    return $uid;
}

=head2 delete

Deletes an account.

=cut

sub delete {
    my ($self, $uid) = @_;
    my ($ret);
    
    $ret = $self->sql->delete(table => 'users',
                                where => {uid => $uid});

    return $ret;
}

=head2 roles

Returns list of roles for supplied user identifier.

=cut

sub roles {
    my ($self, $uid, %args) = @_;
    my (@roles);

    if ($args{map}) {
	my (%map, $record, $role_refs);

	$role_refs = $self->sql->select(fields => [qw/roles.rid roles.name/],
			     join => [qw/user_roles rid=rid roles/],
			     where => {uid => $uid});

	for my $record (@$role_refs) {
	    $map{$record->{rid}} = $record->{name};
	}

	return \%map;
    }
    elsif ($args{numeric}) {
	@roles = $self->sql->select_list_field(table => 'user_roles', 
					     fields => [qw/rid/], 
					     where => {uid => $uid});
    }
    else {
	@roles = $self->sql->select_list_field(fields => [qw/roles.name/],
						 join => [qw/user_roles rid=rid roles/],
						 where => {uid => $uid});
    }

    return @roles;
}

=head2 permissions

Returns list of permissions for supplied user identifier
and array reference with roles.

=cut

sub permissions {
    my ($self, $uid, $roles_ref) = @_;
    my (@records, @permissions, $sth, $row, $roles_str);

    @permissions = $self->sql->select_list_field(table => 'permissions',
						   fields => [qw/perm/],
						   where => [{uid => $uid}, {rid => {-in => $roles_ref}}]);
	
    return @permissions;
}

=head2 value

Get or set value.

=cut

sub value {
    my ($self, $username, $name, $value, $uid);

    $self = shift;
    $username = shift;
    $name = shift;

    if ($uid = $self->exists($username)) {
	if (@_) {
	    # set value
	    $value = shift;

	    $self->sql->update(table => 'users',
				 set => {$name => $value},
				 where => {uid => $uid}); 

	    return 1;
	}

	# retrieve value
	$value = $self->sql->select_field(table => 'users',
					    field => $name,
					    where => {uid => $uid});

	return $value;
    }
    
    return;
}

=head2 password

Set password.

=cut

sub password {
    my ($self, $password, $username) = @_;
    my ($uid);

    if ($username) {
	if ($uid = $self->exists($username)) {
	    $self->sql->update('users', 
				 {password => $password}, 
				 {uid => $uid});

	    return 1;
	}
    }
}

=head2 exists

Check whether user exists.

=cut

sub exists {
    my ($self, $username) = @_;
    my ($results);

    $results = $self->sql->select_field(table => 'users',
					  fields => ['uid'],
					  where => {username => $username});

    return $results;
}

=head2 become

Become an user:

    $acct->become('our.customer@linuxia.de');

=cut

sub become {
    my ($self, $username) = @_;
    my ($record);

    if ($record = $self->_account_retrieve({username => $username})) {
        return $self->_account_init($record);
    }
}

=head2 load

Loads user with uid.

=cut

sub load {
    my ($self, $uid) = @_;
    my ($results);

    $results = $self->sql->select(table => 'users',
                                    where => {uid => $uid});

    if (@$results == 1) {
        return $results->[0];
    }

    return;
}

# helper function to get account hash
sub _account_retrieve {
    my ($self, $argref) = @_;
    my (@fields, %conds, $results);

    @fields = qw/uid username password last_login/;

    if (defined $self->{fields}) {
        push @fields, @{$self->{fields}};
    }
    if (defined $self->{inactive}) {
        push @fields, $self->{inactive};
    }

    $conds{username} = $argref->{username};

    $results = $self->sql->select(table => 'users',
                                    fields => join(',', @fields),
                                    where => \%conds);

    return $results->[0];
}

# helper function to populate account hash
sub _account_init {
    my ($self, $record) = @_;
    my ($roles_map, @permissions, %acct);

    # retrieve permissions
    $roles_map = $self->roles($record->{uid}, map => 1);
    @permissions = $self->permissions($record->{uid}, [keys %$roles_map]);

    if (defined $self->{fields}) {
		for my $f (@{$self->{fields}}) {
		    $acct{$f} = $record->{$f};
		}
    }

    $acct{uid} = $record->{uid};
    $acct{username} = $record->{username};
    $acct{roles} = [values %$roles_map];
    $acct{permissions} = \@permissions;
    $acct{last_login} = $record->{last_login} || 0;

    # update last login in database
    $self->sql->update(table => 'users',
                       where => {uid => $acct{uid}},
                       set => {last_login => time},
                       );

    return \%acct;
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
