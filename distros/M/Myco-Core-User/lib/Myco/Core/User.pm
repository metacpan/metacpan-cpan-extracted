package Myco::Core::User;

##############################################################################
# $Id: User.pm,v 1.1.1.1 2006/03/01 21:00:55 sommerb Exp $
#
# See license and copyright near the end of this file.
##############################################################################

=pod

=head1 NAME

Myco::Core::User - Interface to Myco User Objects

=head1 VERSION

1.0

=cut

our $VERSION = 1.0;

=pod

=head1 SYNOPSIS

  use Myco::Core::User;

  # Constructors.
  my $user = Myco::Core::User->new;
  # See Myco::Entity for more.

  # Class Methods.

  # Instance Methods.
  my $person = $user->get_person;
  $user->set_person($person);
  my $login = $user->login;
  $login->set_login($login);
  $user->set_pass($pass);
  if ($user->chk_pass($pass)) {
      # Allow access.
  }

  $user->save;
  $user->destroy;

=head1 DESCRIPTION

This Class provides the basic interface to all Myco user objects. It offers
the ability to set and get the login name, and to set and check the password.
The password is double-MD5 hash encrypted for security.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use strict;
use warnings;
use Myco::Exceptions;

##############################################################################
# Programmatic Dependences
use Myco;
use Digest::MD5 ();
use Myco::Core::Person;
use Tangram::FlatHash;

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant SECRET => 'YOUR SECRET HERE';

##############################################################################
# Class Variables
##############################################################################
my $_errors = {};

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Myco::Entity Myco::Association);
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    access_list => { rw => [qw(admin)] },
    tangram => { table => 'myco_user', # watch those SQL reserved words!
	         bases => [qw(Myco::Association)] },
    ui => { displayname => sub { shift->get_displayname },
	    list => { layout => [qw(login)] },
            view => { layout => [qw(login)] }, },
  );

##############################################################################
# Function and Closure Prototypes
#############################################################################
## Use this closure to check that a reference is to a Myco::Core::Person object.
my $chk_person = sub {
    Myco::Exception::DataValidation->throw
        (error => "'${$_[0]}' is not a Myco::Core::Person object")
          unless UNIVERSAL::isa(${$_[0]}, 'Myco::Core::Person')
};
# Use this closure to check that login is at least 4 letters or digits
my $chk_login = sub {
    my $login = $ {$_[0]};
    Myco::Exception::DataValidation->throw
        (error => 'Login must be 4 or more characters')
          if $login !~ /([A-Za-z]|\d){4,}/;
};
# Use this closure to check that pass is at least 6 letters or digits
my $chk_pass = sub {
  my $pass = $ {$_[0]};
  Myco::Exception::DataValidation->throw
      (error => 'Login must be 6 or more characters')
	if $pass !~ /([A-Za-z]|\d){6,}/;
};

##############################################################################
# Queries
##############################################################################

=head1 QUERIES

Myco::Query::Meta::Query objects defining generic and reusable queries for
finding Myco::Core::User objects.

=head2 default query

  my $metadata = Myco::Core::User->introspect->get_queries;
  my $default_query = $metadata->{default};
  my @results = $default_query->run_query(login => 'doej');

Find a user object with a given unique login attribute.

=head2 by_person query

  my $metadata = Myco::Core::User->introspect->get_queries;
  my $default_query = $metadata->{by_person};
  my @results = $default_query->run_query(person => $p);

Find a user object with a person attribute set to a given Myco::Core::Person
object, $p.

=cut

my $queries = sub {
    my $md = $_[0]; # Metadata object
    $md->add_query( name => 'default',
                    remotes => { '$u_' => 'Myco::Core::User', },
                    result_remote => '$u_',
                    params => {
                               login => [ qw($u_ login) ],
                              },
                    filter => { parts => [ { remote => '$u_',
                                             attr => 'login',
                                             oper => 'eq',
                                             param => 'login', },
                                         ] },
                  );

    $md->add_query( name => 'by_person',
                    remotes => { '$u_' => 'Myco::Core::User', },
                    result_remote => '$u_',
                    params => {
                               person => [ qw($u_ person) ],
                              },
                    filter => { parts => [
                                           { remote => '$u_',
                                             attr => 'person',
                                             oper => '==',
                                             param => 'person' },
                                         ] },
                  );
};

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 2

=item *  Set attribute value

 $user->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *  Get attribute value

 $value = $user->get_attribute;

=back

Available attributes are listed below, using syntax borrowed from UML class
diagrams; for each showing the name, type, default initial value (if any),
and, following that, a description.

=over 4

=cut

##############################################################################

=item -person: ref(Myco::Core::Person) = Myco::Core::Person

The person object to which this user belongs. Access this object to output
name information about a user.

=cut

$md->add_attribute(name => 'person',
		   type => 'ref',
#                   access_list => { rw => [qw(admin)] },
		   synopsis => 'Person',
		   tangram_options => { check_func => $chk_person,
                                        required => 1,
                                        class => 'Myco::Core::Person' },
                  );


##############################################################################

=item -login: string(128) = undef

The userE<39>s login name.

=cut

$md->add_attribute( name => 'login',
                    type => 'string',
#                    access_list => { rw => [qw(admin)] },
                    synopsis => 'Login Name',
                    ui => { label => 'Login Name' },
                  );

##############################################################################

=item -pass: string(32) = undef

The userE<39>s login password. Internally, it will be encrypted in a double-MD5
hash before being stored in the system.

=cut

$md->add_attribute( name => 'pass',
                    type => 'string',
#                    access_list => { rw => [qw(admin)] },
                    synopsis => 'Password',
                    ui => { label => 'Password',
                            widget => [ 'password_field' ], },
                  );

# These are designed to prevent direct access to the password.

sub get_pass {
    Myco::Exception::MNI->throw
        (error => 'unknown method/attribute '.__PACKAGE__.'->get_pass called');
}
sub pass {
    Myco::Exception::MNI->throw
        (error => 'unknown method/attribute '.__PACKAGE__.'->pass called');
}

sub set_pass {
    my ($self, $pass) = @_;
    $self->SUPER::set_pass(
               Digest::MD5::md5_hex(SECRET . Digest::MD5::md5_hex($pass)));
    Myco::Exception::DataValidation->throw
        (error => 'Password must be at least 6 characters')
          if ($pass && length $pass < 6);
}

=item -roles: hash (string(64} => int) = {}

The userE<39>s roles. These are stored in a hash, where the keys are the role
names and the values are an integer, usually "1". Mostly, you shouldnE<39>t
use the hash to get at the roles, though. See below for the methods specific
to Role access.

=cut

$md->add_attribute( name => 'roles',
                    type => 'flat_hash',
#                    access_list => { rw => [qw(admin)] },
                    synopsis => 'Roles',
                    tangram_options => { table => 'user_roles',
                                         key_type => 'string',
                                         key_sql => 'VARCHAR(64) NOT NULL',
                                         type => 'int',
                                         sql => 'INT NOT NULL DEFAULT 1', },
                  );
# This is designed to prevent direct access to roles
sub roles {
    Myco::Exception::MNI->throw
      (error => 'unknown method/attribute '.__PACKAGE__.'->roles called');
}

=back

##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=cut

=head2 chk_pass

  if ($user->chk_pass($pass)) {
      # Allow access.
  }

Checks the userE<39>s pass word or phrase. Returns true if the pass word or
phrase is correct, and false if it is not.

=cut

sub chk_pass {
  my ($self, $pass) = @_;
  # Use Class::Tangram::get() to get the password, because there won't yet
  # be a user when it's getting checked!
  my $oldpass = $self->SUPER::get_pass || return;
  return Digest::MD5::md5_hex(SECRET . Digest::MD5::md5_hex($pass)) eq
    $oldpass ? 1 : 0;
}

##############################################################################

=head2 get_roles

  my @roles = $user->get_roles;
  my $roles_aref = $user->get_roles;

Returns a list (in an array context) or an anonymous array (in a scalar
context) of all the roles assigned to the user.

=cut

sub get_roles {
    if ($_[0]->SUPER::get_roles) {
	wantarray ?
	  sort keys %{ $_[0]->SUPER::get_roles } :
	    [ sort keys %{ $_[0]->SUPER::get_roles } ];
    }
}

##############################################################################

=head2 add_roles

  $user->add_roles(@roles);

Adds the listed roles to the user. If any role in @roles does not actually
exist as a role, then C<add_roles()> will throw an exception.

=cut

sub add_roles {
    my $self = shift;
    my $roles = $self->SUPER::get_roles;
    $self->SUPER::set_roles($roles = {}) unless $roles;
}

##############################################################################

=head2 del_roles

  $user->del_roles(@roles);

Deletes the listed roles from the user.

=cut

sub del_roles {
    my $self = shift;
    my $roles = $self->SUPER::get_roles;
    delete @{$roles}{@_};
}

##############################################################################

=head2 get_roles_hash

  $user->get_roles_hash;

Returns an anonymous hash of all of the roles assigned to the user. The hash
keys are the role names, and the values are a simple integer (usually one).
This is the internal representation of the roles in the User object, and
normally this method will only be used internally.

=cut

# This absolutely must use the Class::Tangram::get() method. To do otherwise
# will likely cause a problem with deep recursion in Myco::Entity.
# That's why it's best that this method only be used internally -- no one else
# should have permission to use it, really, anyway (except in chk_pass(),
# above).
sub get_roles_hash { $_[0]->SUPER::get_roles }


##############################################################################

=head2 get_displayname

  $user->get_displayname;

Returns the displayname of the person (first and last name) associated with a user.

=cut

sub get_displayname {
  my $self = shift;
  return $self->get_person->displayname;
}

##############################################################################

=head2 find_user

  my $u = Myco::Core::User->find_user($person);

Finds a user, given a Myco::Core::Person. This is a simple wrapper around the
'by_person' query contained in the Myco::Core::User query.

=cut

sub find_user {
  my $self = shift;
  my $p = shift;
  my ($u) = __PACKAGE__->introspect->get_queries->{by_person}->run
    (person => $p);
  return $u;
}


##############################################################################
# Throw a fatal Exception if $_errors is not empty


##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class( queries => $queries );

1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Charles Owens <charles@mycohq.com>, David Wheeler <david@wheeler.net>, and
Ben Sommer <ben@mycohq.com>

=head1 SEE ALSO

L<Myco|Myco>,
L<Myco::Entity|Myco::Entity>,
L<Myco::Core::Person|Myco::Core::Person>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,

=cut
