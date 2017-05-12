package RWDE::LoginUser;

use strict;
use warnings;

use RWDE::Configuration;

use Error qw(:try);
use RWDE::Exceptions;
use RWDE::RObject;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::LoginUser

Authentication class to facilitate logging in users. It is assumed that there is a primary field that a user
can be retrieved by, and a single password field upon which they authenticate with.

=cut

=head2 Authenticate()

Given the appropriate parameters (lookup field,lookup value) the desired record
is fetched from the database and the authentication method is executed.

Currently this method only really works when you are looking up by the class id, 
although there are plans to make this more flexible.

=cut

sub Authenticate {
  my ($self, $params) = @_;

  # If the method is not called in the instance context
  # the system has to do a lookup for the instance first
  RWDE::RObject->check_params({ required => ['lookup_value', 'password'], supplied => $params });

  my $lookup = $$params{lookup} || $self->get_lookup_field();

  my $term;

  #TODO replace these with one single call to a collective method that just knows what to do
  if ($lookup eq 'admin_login') {
    $term = $self->fetch_by_admin_login({ $lookup => $$params{lookup_value} });
  }
  elsif ($lookup eq 'login_email') {
    $term = $self->fetch_by_login_email({ $lookup => $$params{lookup_value}});
  }
  else {
    $term = $self->fetch_by_id({ $lookup => $$params{lookup_value}});
  }

  $term->authenticate($params);
  
  return $term;
}

=head2 authenticate()

Given a login capable object, attempt to authenticate the user represented by the object.

-Verify that the object is an instance
-Check the password and ensure it is correct
-Check the status and make sure the user is permitted to login

If any criteria fail the appropriate exception is thrown and should be caught and handled properly

If all of these criteria are met the lastlogin field is updated to represent this successful login

=cut

sub authenticate {
  my ($self, $params) = @_;

  $self->check_object();
  
  $self->check_password({ password => $$params{password} });
  
  $self->check_status();

  $self->lastlogin(RWDE::Time->now());

  $self->update_record();

  return;
}

=head2 check_password

Returns true if the 'password' stored in the params hash 
matches that of the current record, false for failed match 
or throws an exception otherwise.

BadPasswordException is thrown if the password is invalid

=cut

sub check_password {
  my ($self, $params) = @_;

  if (!defined($$params{password})) {
    throw RWDE::BadPasswordException({ info => "$self supplied incorrect password" });
  }

  elsif ($self->get_password() ne $$params{password}) {
    throw RWDE::BadPasswordException({ info => "$self supplied incorrect password" });
  }

  return ();
}

=head2 generate_randpass

Generate a random string that is 8 characters long. This is useful for assigning 
random passwords to new users, after which you require them to change it after first
login.

=cut

sub generate_randpass {
  my ($self, $params) = @_;

  my $passwordsize = 8;
  my @alphanumeric = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
  my $randpassword = join '', map { $alphanumeric[ rand @alphanumeric ] } 0 .. $passwordsize;

  return $randpassword;
}

1;

