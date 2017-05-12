=head1 NAME

Pangloss::Term - a word or phrase describing a concept.

=head1 SYNOPSIS

  use Pangloss::Term;
  my $term = new Pangloss::Term();

  $term->status( Pangloss::Status->new->approved )
       ->name( $text )
       ->concept( $concept )
       ->language( $language )
       ->creator( $user )
       ->notes( $text )
       ->date( time )
       ->validate;

  # catch Pangloss::Term::Errors

=cut

package Pangloss::Term;

use strict;
use warnings::register;

use Error;
use Pangloss::Term::Error;
use Pangloss::StoredObject::Error;
use Pangloss::Term::Status;

use base      qw( Pangloss::StoredObject::Common Pangloss::Collection::Item );
use accessors qw( concept language status );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];

sub init {
    my $self = shift;
    $self->status(new Pangloss::Term::Status()->pending);
}

sub key {
    my $self = shift;
    return join( ' : ', $self->concept, $self->language, $self->name );
}

sub get_concept_from_key {
    my $class = shift;
    my $key   = shift || return;
    return (split( / : /, $key ))[0];
}

sub get_language_from_key {
    my $class = shift;
    my $key   = shift || return;
    return (split( / : /, $key ))[1];
}

sub get_name_from_key {
    my $class = shift;
    my $key   = shift || return;
    return (split( / : /, $key ))[2];
}

#------------------------------------------------------------------------------

sub validate {
    my $self   = shift;
    my $errors = shift || {};

    $errors->{eStatusRequired()}   = 1 unless ($self->status);
    $errors->{eConceptRequired()}  = 1 unless ($self->concept);
    $errors->{eLanguageRequired()} = 1 unless ($self->language);

    return $self->SUPER::validate( $errors );
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    throw Pangloss::Term::Error( flag    => eInvalid,
				 term    => $self,
				 invalid => $errors );
}

sub copy {
    my $self = shift;
    my $term = shift;

    $self->SUPER::copy( $term )
         ->concept( $term->concept )
         ->language( $term->language )
	 ->status->copy( $term->status );

    return $self;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

In Pangloss, a I<term> (or I<keyword>) is a word or phrase that describes a
particular L<Pangloss::Concept> in a particular L<Pangloss::Language>.

New terms are created with a L<Pangloss::Term::Status> of I<pending>.

This class inherits its interface from L<Pangloss::StoredObject::Common> and
L<Pangloss::Collection::Item>.

=head1 METHODS

=over 4

=item $obj->concept()

set/get L<Pangloss::Concept> of this term.

=item $obj->language()

set/get L<Pangloss::Language> of this term.

=item $obj->status()

set/get the L<Pangloss::Term::Status> of this term.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Term::Error>, L<Pangloss::Term::Status>,
L<Pangloss::Terms>, L<Pangloss::Language>, L<Pangloss::Concept>,
L<Pangloss::User>

=cut
