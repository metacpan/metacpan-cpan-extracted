=head1 NAME

Pangloss::Concept::Error - errors specific to Concepts.

=head1 SYNOPSIS

  use Pangloss::Concept::Error;
  use Pangloss::StoredObject::Error;

  throw Pangloss::Concept::Error(flag => eExists, concept => $concept);
  throw Pangloss::Concept::Error(flag => eNonExistent, name => $name);
  throw Pangloss::Concept::Error(flag => eInvalid, concept => $concept,
                              invalid => {eNameRequired => 1});

  # with caught errors:
  print $e->concept->name;

=cut

package Pangloss::Concept::Error;

use strict;
use warnings::register;

use Pangloss::Concept;

use base      qw( Pangloss::StoredObject::Error );
use accessors qw( concept );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub new {
    my $class = shift;
    my %args  = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (my $name = delete $args{name}) {
	$args{concept} = new Pangloss::Concept()->name($name);
    }
    $class->SUPER::new(map { /^concept$/ ? '-concept' : $_; } %args);
}

sub stringify {
    my $self = shift;
    my $str  = $self->SUPER::stringify . ':concept';
    $str    .= '=' . $self->concept->key if $self->concept;
    return $str;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Concept Errors class.  Inherits interface from L<Pangloss::StoredObject::Error>.
May contain a L<concept> object associated with the error.

=head1 METHODS

=over 4

=item $e->concept

set/get Pangloss::Concept for this error.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Error>, L<Pangloss::Concept>, L<Pangloss::Concepts>

=cut

