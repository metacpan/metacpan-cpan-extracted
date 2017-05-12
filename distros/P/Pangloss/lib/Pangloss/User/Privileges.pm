=head1 NAME

Pangloss::User::Privileges - user privileges.

=head1 SYNOPSIS

  use Pangloss::User::Privileges;
  my $privs = new Pangloss::User::Privileges();

  $privs->admin( false )
        ->add_concepts( true )
        ->add_categories( true )
        ->add_translate_languages( @languages )
        ->add_proofread_languages( @languages );

  do { ... } if $privs->can_translate( $language );
  do { ... } if $privs->can_proofread( $language );
  do { ... } if $privs->admin();

  # etc.

=cut

package Pangloss::User::Privileges;

use strict;
use warnings::register;

use Scalar::Util qw( blessed );

use base      qw( Pangloss::StoredObject );
use accessors qw( admin    add_concepts    add_categories
		  translate_languages proofread_languages );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.17 $ '))[2];

#------------------------------------------------------------------------------
# Object initialization

sub init {
    my $self = shift;
    $self->translate_languages( {} )
         ->proofread_languages( {} );
}

#------------------------------------------------------------------------------

sub translate {
    my $self = shift;
    return scalar keys %{$self->translate_languages};
}

sub proofread {
    my $self = shift;
    return scalar keys %{$self->proofread_languages};
}


sub add_translate_languages {
    my $self = shift;

    foreach my $lang (@_) {
	my $key = $self->get_lang_key( $lang );
        $self->translate_languages->{$key} = 1;
    }

    return $self;
}

sub add_proofread_languages {
    my $self = shift;

    foreach my $lang (@_) {
	my $key = $self->get_lang_key( $lang );
        $self->proofread_languages->{$key} = 1;
    }

    return $self;
}

sub remove_translate_languages {
    my $self = shift;

    foreach my $lang (@_) {
	my $key = $self->get_lang_key( $lang );
        delete $self->translate_languages->{$key};
    }

    return $self;
}

sub remove_proofread_languages {
    my $self = shift;

    foreach my $lang (@_) {
	my $key = $self->get_lang_key( $lang );
        delete $self->proofread_languages->{$key};
    }

    return $self;
}

sub can_translate {
    my $self = shift;
    my $key  = $self->get_lang_key( shift );
    return $self->translate_languages->{$key} ? 1 : 0;
}

sub can_proofread {
    my $self = shift;
    my $key  = $self->get_lang_key( shift );
    return $self->proofread_languages->{$key} ? 1 : 0;
}

sub get_lang_key {
    my $self = shift;
    my $lang = shift;
    return blessed($lang) ? $lang->key : $lang;
}

sub copy {
    my $self  = shift;
    my $privs = shift;

    my %translate_langs = map( { $_ => $privs->can_translate($_) }
			       keys %{ $privs->translate_languages } );

    my %proofread_langs = map( { $_ => $privs->can_proofread($_) }
			       keys %{ $privs->proofread_languages } );

    $self->admin( $privs->admin )
         ->add_concepts( $privs->add_concepts )
         ->add_categories( $privs->add_categories )
         ->add_concepts( $privs->add_concepts )
         ->translate_languages( { %translate_langs } )
         ->proofread_languages( { %proofread_langs } );

    return $self;
}

1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents the privileges of a user in Pangloss.  A user with
special privileges can do one or more of:

    translate terms in a given language
    proofread terms in a given language
    add concepts
    add categories
    administrate Pangloss

New privileges are created with an empty list of translate/proofread languages.

This class inherits from L<Pangloss::StoredObject>.

=head1 METHODS

=over 4

=item add_concepts()

set/get 'add concepts' flag of the user.

=item add_categories()

set/get 'add categories' flag of the user.

=item admin()

set/get administration flag of the user.

=item translate_languages()

set/get hash of L<Pangloss::Language> keys the user is allowed to translate.

=item proofread_languages()

set/get hash of L<Pangloss::Language> keys the user is allowed to proofread.

=item translate(), proofread()

test to see if user can translate/proofread one or more <Pangloss::Language>s.

=item add_translate_languages( @langs ), add_proofread_languages( @langs )

add to the relevant list of languages.  accepts L<Pangloss::Language>s or their
keys.  returns this object.

=item remove_translate_languages( @langs ), remove_proofread_languages( @langs )

remove from the relevant list of languages.  accepts L<Pangloss::Language>s or
their keys.  returns this object.

=item can_translate( $lang ), can_proofread( $lang )

test to see if user can translate/proofread given L<Pangloss::Language>.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::User>, L<Pangloss::Language>

=cut

