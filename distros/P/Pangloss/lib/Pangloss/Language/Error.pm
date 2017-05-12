=head1 NAME

Pangloss::Language::Error - errors specific to Languages.

=head1 SYNOPSIS

  use Pangloss::Language::Error;
  use Pangloss::StoredObject::Error;

  throw Pangloss::Language::Error(flag => eExists, language => $language);
  throw Pangloss::Language::Error(flag => eNonExistent, iso_code => $iso_code);
  throw Pangloss::Language::Error(flag => eInvalid, language => $language,
                                  invalid => {eIsoCodeRequired => 1});

  # with caught errors:
  print $e->language->iso_code;

=cut

package Pangloss::Language::Error;

use strict;
use warnings::register;

use Pangloss::Language;

use base      qw( Exporter Pangloss::StoredObject::Error );
use accessors qw( language );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];
our @EXPORT   = qw( eIsoCodeRequired eDirectionRequired );

use constant eIsoCodeRequired   => 'language_iso_code_required';
use constant eDirectionRequired => 'language_direction_required';

sub new {
    my $class = shift;
    my %args  = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (my $iso_code = delete $args{iso_code}) {
	$args{language} = new Pangloss::Language()->iso_code($iso_code);
    }
    $class->SUPER::new(map { /^language$/ ? '-language' : $_; } %args);
}

sub isIsoCodeRequired {
    return shift->is(eIsoCodeRequired);
}

sub isDirectionRequired {
    return shift->is(eDirectionRequired);
}

sub stringify {
    my $self = shift;
    my $str  = $self->SUPER::stringify . ':language';
    $str    .= '=' . $self->language->key if $self->language;
    return $str;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Language Errors class.  Inherits interface from L<Pangloss::StoredObject::Error>.
May contain a L<language> object associated with the error.

=head1 EXPORTED FLAGS

Validation errors:
 eIsoCodeRequired
 eDirectionRequired

=head1 METHODS

=over 4

=item $e->language

set/get Pangloss::Language for this error.

=item $bool = $e->isIsoCodeRequired, $e->isDirectionRequired

Test if this error's flag is equal to the named flag.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Error>, L<Pangloss::Language>, L<Pangloss::Languages>

=cut


