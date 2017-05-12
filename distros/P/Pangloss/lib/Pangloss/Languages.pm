=head1 NAME

Pangloss::Languages - a collection of Pangloss languages.

=head1 SYNOPSIS

  use Pangloss::Languages;
  my $languages = new Pangloss::Languages();

  try {
      my $language = $languages->get( $iso_code );
      $languages->add( $language );
      $languages->remove( $language );
      do { ... } foreach ( $languages->list );
  } catch Pangloss::Language::Error with {
      my $e = shift;
      ...
  }

=cut

package Pangloss::Languages;

use strict;
use warnings::register;

use Error;

use Pangloss::Language;
use Pangloss::Language::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Collection );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub iso_codes {
    return shift->keys;
}

sub error_key_nonexistent {
    my $self     = shift;
    my $iso_code = shift;
    throw Pangloss::Language::Error(flag     => eNonExistent,
				    iso_code => $iso_code);
}

sub error_key_exists {
    my $self     = shift;
    my $iso_code = shift;
    throw Pangloss::Language::Error(flag     => eExists,
				    iso_code => $iso_code);
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class contains a collection of L<Pangloss::Language> objects.  It inherits
its interface from L<Pangloss::Collection>.

The collection is keyed on $language->iso_code().

=head1 METHODS

=over 4

=item @iso_codes = $obj->iso_codes

synonym for $obj->keys()

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>,
L<Pangloss::Language>, L<Pangloss::Language::Error>

=cut
