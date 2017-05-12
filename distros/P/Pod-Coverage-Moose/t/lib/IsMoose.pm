=pod

=head2 IsMoose->baz

The baz method

=cut

package IsMoose;
use Moose;
use namespace::autoclean;

with 'MooseRole';

sub bar { }

sub baz { }

1;
