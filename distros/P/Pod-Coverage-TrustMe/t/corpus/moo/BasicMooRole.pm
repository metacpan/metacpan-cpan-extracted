package BasicMooRole;
use Moo::Role;

sub mymethod { }

no Moo::Role;

1;
__END__

=for Pod::Coverage meta

=head1 METHODS

=head2 mymethod

This is covered
