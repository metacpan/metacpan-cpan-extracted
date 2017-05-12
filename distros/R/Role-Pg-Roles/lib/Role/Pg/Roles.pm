package Role::Pg::Roles;
$Role::Pg::Roles::VERSION = '0.002';
use 5.010;
use Moose::Role;
use DBI;
use Digest::MD5 qw/md5_hex/;

has 'roles_dbh' => (
	is => 'ro',
	isa => 'DBI::db',
	lazy_build => 1,
);

sub _build_roles_dbh {
	my $self = shift;
	return $self->dbh if $self->can('dbh');
	return $self->schema->storage->dbh if $self->can('schema');
}

sub create_role {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my $role = $dbh->quote_identifier($args{role}) or return;
	my $sql = qq{
		CREATE ROLE $role
	};
	my @values;
	if (my $password = $args{password}) {
		$sql .= ' WITH ENCRYPTED PASSWORD ?';
		push @values, $password;
	}
	$self->roles_dbh->do($sql, undef, @values);
}

sub drop_role {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my $role = $dbh->quote_identifier($args{role}) or return;
	my $sql = qq{
		DROP ROLE $role
	};
	$self->roles_dbh->do($sql);
}

sub add_to_group {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my ($group, $member) = map {$dbh->quote_identifier($args{$_}) // return} qw/group member/;
	my $sql = qq{
		GRANT $group TO $member
	};
	$self->roles_dbh->do($sql);
}

sub remove_from_group {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my ($group, $member) = map {$dbh->quote_identifier($args{$_}) // return} qw/group member/;
	my $sql = qq{
		REVOKE $group FROM $member
	};
	$self->roles_dbh->do($sql);
}

sub check_user {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my ($user, $password) = map {$args{$_} // return} qw/user password/;
	my $sql = qq{
		SELECT 1 FROM pg_catalog.pg_authid
		WHERE rolname = ? AND rolpassword = ?
	};
	push my @values, $user, 'md5' . md5_hex($password . $user);
	return $self->roles_dbh->selectrow_arrayref($sql, undef, @values) ? 1 : 0;
}

sub roles {
	my ($self, %args) = @_;
	my $sql = q{
		SELECT rolname
		FROM pg_authid a
		WHERE pg_has_role(?, a.oid, 'member')
	};
	my @values = map {$args{$_} // return} qw/user/;

	return [ sort map {shift @$_} @{ $self->roles_dbh->selectall_arrayref($sql, undef, @values) } ];
}

sub member_of {
	my ($self, %args) = @_;
	my ($user, $group) = map {$args{$_} // return} qw/user group/;
	my $roles = $self->roles(user => $user);

	return grep {$group eq $_} @$roles;
}

sub set_role {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my $role = $dbh->quote_identifier($args{role}) or return;
	my $sql = qq{
		SET ROLE $role
	};
	$self->roles_dbh->do($sql);
}

sub reset_role {
	my ($self) = @_;
	my $sql = qq{
		RESET ROLE
	};
	$self->roles_dbh->do($sql);
}

sub set_password {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my $role = $dbh->quote_identifier($args{role}) or return;
	my $password = $dbh->quote($args{password}) or return;
	my $sql = qq{
		ALTER ROLE $role WITH ENCRYPTED PASSWORD $password
	};
	$self->roles_dbh->do($sql);
}

sub set_privilege {
	my ($self, %args) = @_;
	my $dbh = $self->roles_dbh;
	my $role = $dbh->quote_identifier($args{role}) or return;
	my $privilege = $dbh->quote_identifier($args{privilege}) or return;
	my $sql = qq{
		ALTER ROLE $role WITH $privilege
	};
	$self->roles_dbh->do($sql);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Role::Pg::Roles - Client Role for handling PostgreSQL Roles

=head1 VERSION

version 0.002

=head1 name

role::pg::roles

=head1 description

this role handles the use of roles in a postgresql database.

=head1 attributes

=head2 roles_dbh

role::pg::roles tries to guess your dbh. if it isn't a standard dbi::db named dbh, or
constructed in a dbix::class schema called schema, you have to return the dbh from
_build_roles_dbh.

=head1 METHODS

=head2 create_role

 $self->create_role(role => 'me', password => 'safety');

Creates a role. The role can be seen as either a user or a group.

An optional password can be added. The user (or group) is then created with an encrypted password.

=head2 drop_role

 $self->drop_role(role => 'me');

Drops a role.

=head2 add_to_group

 $self->add_to_group(group => 'group', member => 'me');

Adds a member to a group. A member can be a user or a group

=head2 remove_from_group

 $self->remove_from_group(group => 'group', member => 'me');

Removes a member from a group.

=head2 check_user

 my $roles = $self->check_user(user => 'me', password => 'trust me!');

Checks if there is a user with the given password

=head2 roles

 my $roles = $self->roles(user => 'me');

Returns an arrayref with all the roles the user is a member of.

=head2 member_of

 print "yep" if $self->member_of(user => 'me', group => 'group');

Returns true if user is member of group.

=head2 set_role

 $self->set_role(role => 'elvis');

Assume another role.

=head2 reset_role

 $self->reset;

Back to your old self.

=head2 set_password

 $self->set_password(role => 'elvis', password => 'King');

Set (a new) password.

=head2 set_privilege

 $self->set_privilege(role => 'elvis', privilege => 'createrole');

Add a privilege to (or remove from) a role.

Priviles can be any of

	SUPERUSER
	CREATEDB
	CREATEROLE
	CREATEUSER
	INHERIT
	LOGIN
	REPLICATION

To remove a privilege, prepend with "NO" (like NOCREATEROLE).

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2014, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Client Role for handling PostgreSQL Roles

