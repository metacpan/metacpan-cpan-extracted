package MouseX::Getopt::Strict;
# ABSTRACT: only make options for attrs with the Getopt metaclass

use Mouse::Role;

with 'MouseX::Getopt';

around '_compute_getopt_attrs' => sub {
    my $next = shift;
    my ( $class, @args ) = @_;
    grep {
        $_->does("MouseX::Getopt::Meta::Attribute::Trait")
    } $class->$next(@args);
};

no Mouse::Role;

1;

=head1 DESCRIPTION

This is an stricter version of C<MouseX::Getopt> which only processes the
attributes if they explicitly set as C<Getopt> attributes. All other attributes
are ignored by the command line handler.

=cut
