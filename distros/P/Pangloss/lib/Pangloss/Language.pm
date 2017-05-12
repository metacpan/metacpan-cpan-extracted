=head1 NAME

Pangloss::Language - a language in Pangloss.

=head1 SYNOPSIS

  use Pangloss::Language qw( dirRTL dirLTR );
  my $language = new Pangloss::Language();

  $language->name( $text )
           ->iso_code( $text )
           ->direction( dirRTL )
           ->creator( $user )
           ->notes( $text )
           ->date( time )
           ->validate;

  # catch Pangloss::Language::Errors

  do { ... } if $language->is_ltr();

=cut

package Pangloss::Language;

use strict;
use warnings::register;

use Error;
use Pangloss::Language::Error;
use Pangloss::StoredObject::Error;

use base      qw( Pangloss::StoredObject::Common Pangloss::Collection::Item Exporter );
use accessors qw( iso_code direction );

our $VERSION   = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION  = (split(/ /, ' $Revision: 1.11 $ '))[2];
our @EXPORT_OK = qw( dir_LTR dir_RTL );

use constant dir_LTR => 'ltr';
use constant dir_RTL => 'rtl';

sub key {
    my $self = shift;
    return $self->iso_code();
}

sub is_ltr {
    my $self = shift;
    return ( $self->direction eq dir_LTR );
}

sub is_rtl {
    my $self = shift;
    return ( $self->direction eq dir_RTL );
}

sub validate {
    my $self   = shift;
    my $errors = shift || {};

    $errors->{eIsoCodeRequired()}   = 1 unless ($self->iso_code);
    $errors->{eDirectionRequired()} = 1 unless ($self->direction);

    return $self->SUPER::validate( $errors );
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    throw Pangloss::Language::Error( flag     => eInvalid,
				     language => $self,
				     invalid  => $errors );
}

sub copy {
    my $self = shift;
    my $lang = shift;

    $self->SUPER::copy( $lang )
         ->iso_code( $lang->iso_code )
	 ->direction( $lang->direction );

    return $self;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents a language in Pangloss.

It inherits from L<Pangloss::StoredObject::Common> and
L<Pangloss::Collection::Item>.

=head1 EXPORTS

Exports two constants on request for use with language direction:

  dir_LTR (left to right)
  dir_RTL (right to left)

=head1 METHODS

=over 4

=item $obj->iso_code()

set/get ISO code.

=item $obj->direction()

set/get language direction.

=item $bool = $obj->is_ltr(), $obj->is_rtl()

test if the language direction is the above.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Language::Error>, L<Pangloss::Languages>

=cut

