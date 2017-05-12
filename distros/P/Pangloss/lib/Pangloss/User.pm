=head1 NAME

Pangloss::User - a user in Pangloss.

=head1 SYNOPSIS

  use Pangloss::User;
  my $user = new Pangloss::User();

  $user->id( $id )
       ->name( $full_name )
       ->privileges( Pangloss::User::Privileges->new )
       ->creator( $user )
       ->notes( $text )
       ->date( time )
       ->validate;

  # catch Pangloss::User::Errors

  do { ... } if $user->is_admin;
  do { ... } if $user->is_translator;
  do { ... } if $user->is_proofreader;

  # etc...

=cut

package Pangloss::User;

use strict;
use warnings::register;

use Error;
use Pangloss::User::Error;
use Pangloss::StoredObject::Error;
use Pangloss::User::Privileges;

use base      qw( Pangloss::StoredObject::Common
		  Pangloss::Collection::Item
		  OpenFrame::WebApp::User );
use accessors qw( name privileges );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.20 $ '))[2];

OpenFrame::WebApp::User->types->{pangloss} = __PACKAGE__;

sub init {
    my $self = shift;
    $self->privileges( new Pangloss::User::Privileges );
}

sub key {
    my $self = shift;
    return $self->id();
}

sub validate {
    my $self   = shift;
    my $errors = shift || {};

    $errors->{eIdRequired()} = 1 unless ($self->id);

    return $self->SUPER::validate( $errors );
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    throw Pangloss::User::Error( flag    => eInvalid,
				 user    => $self,
				 invalid => $errors );
}

sub copy {
    my $self = shift;
    my $user = shift;

    $self->SUPER::copy( $user )
         ->id( $user->id )
	 ->privileges->copy( $user->privileges );

    return $self;
}

sub is_admin {
    return shift->privileges->admin;
}

sub is_translator {
    my $privs = shift->privileges;
    return $privs->translate || $privs->admin;
}

sub is_proofreader {
    my $privs = shift->privileges;
    return $privs->proofread || $privs->admin;
}

sub can_add_concepts {
    my $privs = shift->privileges;
    return $privs->add_concepts || $privs->admin;
}

sub can_add_categories {
    my $privs = shift->privileges;
    return $privs->add_categories || $privs->admin;
}

sub can_translate {
    my $privs = shift->privileges;
    my $lang  = shift;
    return $privs->can_translate($lang) || $privs->admin;
}

sub can_proofread {
    my $privs = shift->privileges;
    my $lang  = shift;
    return $privs->can_proofread($lang) || $privs->admin;
}

sub not_admin {
    return ! shift->is_admin;
}

sub not_translator {
    return ! shift->is_translator;
}

sub not_proofreader {
    return ! shift->is_proofreader;
}

sub cant_add_concepts {
    return ! shift->can_add_concepts;
}

sub cant_add_categories {
    return ! shift->can_add_categories;
}

sub cant_translate {
    return ! shift->can_translate( @_ );
}

sub cant_proofread {
    return ! shift->can_proofread( @_ );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents a user in Pangloss.  A new user always has an empty set
of privileges.

This object inherits its interface from L<Pangloss::StoredObject> and
L<OpenFrame::WebApp::User>.

=head1 METHODS

=over 4

=item $obj->id

set/get user id (ie: login name).

=item $obj->name

set/get user full name.

=item privileges()

set/get user L<Pangloss::User::Privileges>.

=item is_admin()

test privileges to see if user is an admin.

=item is_translator(), is_proofreader()

test privileges to see if user can translate/proofread one or more
L<Pangloss::Languages>.

=item can_add_concepts(), can_add_categories()

test privileges to see if user can add concepts/categories.

=item can_translate( $lang ), can_proofread( $lang )

test privileges to see if user can translate/proofread the L<Pangloss::Language>.

=item not_admin()

test privileges to see if user is not an admin.

=item not_translator(), not_proofreader()

test privileges to see if user cannot translate/proofread any
L<Pangloss::Languages>.

=item cant_add_concepts(), cant_add_categories()

test privileges to see if user cannot add concepts/categories.

=item cant_translate( $lang ), cant_proofread( $lang )

test privileges to see if user cannot translate/proofread the given
L<Pangloss::Language>.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::User::Error>, L<Pangloss::User::Privileges>,
L<Pangloss::Users>, L<OpenFrame::WebApp::User>

=cut

