package OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::User;

use strict;
use Moose::Role;


sub setup_authdb
{
    my $class = shift;

    $class->load_components("EncodedColumn");
   
    # Alter the password column to enable encoded password.. 
    $class->add_columns
    (
        "+password",
        {
            encode_column => 1,
            encode_class  => 'Crypt::Eksblowfish::Bcrypt',
            encode_args   => { key_nul => 0, cost => 8 },
            encode_check_method => '_local_check_password',
        }
    );

    $class->many_to_many( roles         => 'users_roles',       'role'       );
    $class->many_to_many( parameters    => 'users_parameters',  'parameter'  );
}


sub check_password
{
    my $self = shift;
    # FIXME: is our database inconsistent?
    return 0 unless $self->status eq 'active' || $self->status eq 'enabled';
    my $schema = $self->result_source->schema;
    # see if the schema has been given a method for
    # checking the password
    my $result;
    if($schema->can('password_check') && $schema->password_check)
    {
        # look up ldap password.
        $result = $schema->password_check->check_password($self->username, @_);
    }
    else
    {
        $result = $self->_local_check_password(@_);
    }
    if($result)
    {
        $self->successful_login;
    }
    else
    {
        $self->failed_login;
    }
    return $result;
}

sub failed_login
{
    my $self = shift;
    $self->update({ last_failed_login => DateTime->now() });
}

sub successful_login
{
    my $self = shift;
    $self->update({ last_login => DateTime->now() });
}



sub getdata
{
    my $self = shift;
    my ($key) = @_;
    my $data = $self->find_related( 'users_data', { key => $key } );
    return undef unless $data;
    return $data->value;
}


sub setdata
{
    my $self = shift;
    my ($key, $value) = @_;
    my $data = $self->find_or_create_related( 'users_data', { key => $key } );
    $data->update( { value => $value } );
    return 1;
}


sub disable
{
    my $self = shift;

    if ( $self->status )
    {
        $self->update( { status => 'disabled' } );
        return 1;
    } 
    return 0;
}


sub enable
{
    my $self = shift;

    if ( $self->status )
    {
        $self->update( { status => 'enabled' } );
        return 1;
    } 
    return 0;
}


sub params_hash
{
    my $self = shift;

    my %hash;
    foreach my $rp ( $self->users_parameters )
    {   
        next unless defined $rp;
        next unless defined $rp->parameter;
        $hash{  $rp->parameter->parameter } = $rp->value;
    }

    return \%hash;
}


sub set_param_by_name
{
    my $self  = shift;
    my ( $param_name, $param_value ) = @_;

    # find the param..
    my $param = $self->result_source->schema->resultset('Parameter')->find( { parameter => $param_name } );

    # return undef, if we could find the param..
    return undef unless $param;

    # add to users parameter...
    $self->update_or_create_related( 'users_parameters', { value => $param_value, parameter_id => $param->id   } );

    return 1; 
}

sub get_parameter_value_by_name
{
    my $self = shift;
    my $val = $self->get_parameter_by_name(@_);
    return unless $val;
    return $val->value;
}

sub get_parameter_by_name
{
    my $self = shift;
    my $name = shift;

    my $param = $self->users_parameters->find({ 'parameter.parameter' => $name }, { join => [ 'parameter' ] });
    return $param;
}


sub delete_param_by_name
{
    my $self  = shift;
    my ( $param_name ) = @_;

    # FIXME: this code blows, use get_parameter_by_name instead.
    # find the param..
    my $param = $self->result_source->schema->resultset('Parameter')->find( { parameter => $param_name } );

    # return undef, if we could find the param..
    return undef unless $param;

    # delete to users parameter...
    $self->delete_related( 'users_parameters', { parameter_id => $param->id } );

    return 1; 
}


sub roles_modifiable
{
    my $self = shift;
    my $schema = $self->result_source->schema;

    # check to see if any of the current roles allow access to all
    if (grep { $_ } map { $_->can_change_any_role } $self->roles->all)
    {
        return $schema->resultset('Role');
    }
    my $allowed_roles = $self->roles->search_related('roles_allowed_roles');
    if($allowed_roles->count == 0)
    {
        # check to see if any allowed roles are setup
        # if not return all roles.
        if($schema->resultset('RoleAllowed')->count == 0 
            && $schema->resultset('RoleAdmin')->count == 0)
        {
            return $schema->resultset('Role');
        }
    }
    my $roles = $schema->resultset('Role')->search({ id => { in => $allowed_roles->get_column('role_allowed')->as_query }});

    return $roles;
}


sub can_modify_user
{
    my ($self, $username) = @_;
    my $schema = $self->result_source->schema;
    my $other_user = $schema->resultset('User')->find({ username => $username});
    die "Unable to find user '$username'" unless $other_user;
    my @roles = $other_user->roles->all;
    my @allowed = $self->roles_modifiable->all;
    my %allowed_hash = map { $_->role => 1 } @allowed;
    for my $role (@roles)
    {
        return 0 unless $allowed_hash{$role->role};
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::User

=head1 VERSION

version 6

=head2 setup_authdb

This need to be called as the User result class is being setup to 
finish the table setup.

=head2 check_password

The check_password function is usually called by Catalyst to determine
if the password is correct for a user.  It returns 0 for false and 1 for
true.  If the database schema has a check_password function that is used,
otherwise the standard Bcrypt function is used to check the hash stored
in the database.

=head2 getdata

=head2 setdata

=head2 disable

    Disables a users account.

=head2 enable

    Enables a users account.

=head2 params_hash

    Finds all a users parameters, matches them with the value and returns a nice Hash ref.

=head2 set_param_by_name

    Sets a users parameter by the parameter name.
    Returns:
        undef   - if the param could be found by name.
        1       - if the param was set successfully.

=head2 delete_param_by_name

    Deltes a users parameter by the parameter name.
    Returns:
        undef   - if the param could be found by name.
        1       - if the param was deleted successfully.

=head2 roles_allowed

Returns the list of roles this user is allowed to modify.

=head2 can_modify_user

This method returns true if the user is allowed to modify the user in question.

It determines this by checking the roles the current user is allowed to modify
to the roles the other user has.  If it's not allowed to modify a role that user
has then it will return false.

    $user->can_modify_user('colin');

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
