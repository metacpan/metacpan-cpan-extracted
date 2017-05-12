=head1 NAME

Pangloss::Category::Error - errors specific to Categories.

=head1 SYNOPSIS

  use Pangloss::Category::Error;
  use Pangloss::StoredObject::Error;

  throw Pangloss::Category::Error(flag => eExists, category => $category);
  throw Pangloss::Category::Error(flag => eNonExistent, name => $name);
  throw Pangloss::Category::Error(flag => eInvalid, category => $category,
                               invalid => {eNameRequired => 1});

  # with caught errors:
  print $e->category->name;

=cut

package Pangloss::Category::Error;

use strict;
use warnings::register;

use Pangloss::Category;

use base      qw( Pangloss::StoredObject::Error );
use accessors qw( category );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];

sub new {
    my $class = shift;
    my %args  = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (my $name = delete $args{name}) {
	$args{category} = new Pangloss::Category()->name($name);
    }
    $class->SUPER::new(map { /^category$/ ? '-category' : $_; } %args);
}

sub stringify {
    my $self = shift;
    my $str  = $self->SUPER::stringify . ': category';
    $str    .= '=' . $self->category->key if $self->category;
    return $str;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Category Errors class.  Inherits interface from L<Pangloss::StoredObject::Error>.
May contain a L<category> object associated with the error.

=head1 METHODS

=over 4

=item $e->category

set/get L<Pangloss::Category> for this error.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Error>, L<Pangloss::StoredObject::Error>,
L<Pangloss::Category>, L<Pangloss::Categories>

=cut

