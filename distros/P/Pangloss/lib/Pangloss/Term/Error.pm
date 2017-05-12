=head1 NAME

Pangloss::Term::Error - errors specific to Terms.

=head1 SYNOPSIS

  use Pangloss::Term::Error;
  use Pangloss::StoredObject::Error;

  throw Pangloss::Term::Error(flag => eExists, term => $term);
  throw Pangloss::Term::Error(flag => eNonExistent, name => $name);
  throw Pangloss::Term::Error(flag => eInvalid, term => $term,
                              invalid => {eTermNameRequired => 1});

  # with caught errors:
  print $e->term->name;

=cut

package Pangloss::Term::Error;

use strict;
use warnings::register;

use Pangloss::Term;

use base      qw( Exporter Pangloss::StoredObject::Error );
use accessors qw( term );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];
our @EXPORT   = qw( eStatusRequired eConceptRequired
		    eLanguageRequired );

use constant eStatusRequired   => 'term_status_required';
use constant eConceptRequired  => 'term_concept_required';
use constant eLanguageRequired => 'term_language_required';

sub new {
    my $class = shift;
    my %args  = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (my $name = delete $args{name}) {
	$args{term} = new Pangloss::Term()->name($name);
    }
    $class->SUPER::new(map { /^term$/ ? '-term' : $_; } %args);
}

sub isStatusRequired {
    return shift->is(eStatusRequired);
}

sub isConceptRequired {
    return shift->is(eConceptRequired);
}

sub isLanguageRequired {
    return shift->is(eLanguageRequired);
}

sub stringify {
    my $self = shift;
    my $str  = $self->SUPER::stringify . ':term';
    $str    .= '=' . $self->term->key if $self->term;
    return $str;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Term Errors class.  Inherits interface from L<Pangloss::StoredObject::Error>.
May contain a L<term> object associated with the error.

=head1 EXPORTED FLAGS

Validation errors:
 eStatusRequired
 eConceptRequired
 eLanguageRequired

=head1 METHODS

=over 4

=item $e->term

set/get Pangloss::Term for this error.

=item $bool = $e->isStatusRequired, $e->isConceptRequired,
$e->isLanguageRequired

Test if this error's flag is equal to the named flag.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Error>, L<Pangloss::StoredObject::Error>,
L<Pangloss::Term>, L<Pangloss::Terms>

=cut

