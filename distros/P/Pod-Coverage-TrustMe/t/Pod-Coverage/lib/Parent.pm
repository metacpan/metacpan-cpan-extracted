package Parent;
use GrandParent ();
use base 'GrandParent';
sub dummy {};

1;
__END__

=head1 NAME

Parent demo class

=head2 foo

you must implement this in a derived class

=cut

