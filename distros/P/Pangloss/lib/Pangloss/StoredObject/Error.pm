=head1 NAME

Pangloss::StoredObject::Error - base class for stored object errors.

=head1 SYNOPSIS

  # abstract - cannot be used directly
  package SomeError;
  use base qw( Pangloss::StoredObject::Error );

  throw SomeError( flag => eExists, ... );
  throw SomeError( flag => eNonExistent, ... );
  throw SomeError( flag => eInvalid, invalid => { ... });

  # with caught errors:
  print $e->flag;
  do { ... } if $e->isExists;
  do { ... } if $e->isNonexistent;
  do { ... } if $e->isInvalid;

=cut

package Pangloss::StoredObject::Error;

use strict;
use warnings::register;

use base      qw( Exporter Pangloss::Error );
use accessors qw( invalid );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];
our @EXPORT   = qw( eExists eInvalid eNonExistent
		    eNameRequired eCreatorRequired eDateRequired );

use constant eExists      => 'object_exists';
use constant eInvalid     => 'object_invalid';
use constant eNonExistent => 'object_non_existent';

use constant eNameRequired    => 'object_name_required';
use constant eCreatorRequired => 'object_creator_required';
use constant eDateRequired    => 'object_date_required';

sub new {
    my $class = shift;
    local $Error::Depth = $Error::Depth + 1;
    my $self = $class->SUPER::new(map { /^invalid$/ ? '-invalid' : $_; } @_);
    $self->invalid({}) unless $self->invalid;
    return $self;
}

sub is {
    my $self = shift;
    my $test = shift;
    return 1 if ($self->flag eq $test);
    return 1 if (($test ne eInvalid) and $self->isInvalid and $self->invalid->{$test});
    return 0;
}

sub isInvalid {
    return shift->is(eInvalid);
}

sub isExists {
    return shift->is(eExists);
}

sub isNonExistent {
    return shift->is(eNonExistent);
}

sub isNameRequired {
    return shift->is(eNameRequired);
}

sub isCreatorRequired {
    return shift->is(eCreatorRequired);
}

sub isDateRequired {
    return shift->is(eDateRequired);
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Stored Object Errors class.  Inherits interface from L<Pangloss::Error>.
Introduces validation error flags.

=head1 EXPORTED FLAGS

Error flags:
 eExists
 eInvalid
 eNonExistent

Validation errors:
 eNameRequired
 eCreatorRequired
 eDateRequired

=head1 METHODS

=over 4

=item $e->invalid

set/get hash of validation error flags.

=item $bool = $e->is( $flag )

Test if this error's flag is equal to $flag.  if this is a validation error
also checks in the $e->invalid hash for $flag.

=item $bool = $e->isInvalid, $e->isExists, $e->isNonExistent,
$e->isNameRequired, $e->isCreatorRequired, $e->isDateRequired

Test if this error's flag is equal to the named flag.

=back

=head1 TODO

Refactor some of this out to OpenFrame::WebApp.

Write name(), date(), and creator() shortcuts to see if flag is associated
with the given instance variable.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Error>, L<Pangloss::StoredObject::Common>

=cut

