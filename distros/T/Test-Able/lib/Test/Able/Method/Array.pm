package Test::Able::Method::Array;

use strict;
use warnings;

=head1 NAME

Test::Able::Method::Array - Test-related method list

=head1 DESCRIPTION

This only exists, as a convenience, to provide overriding in a hash context.
Instead of having to do this:

 my ( $m ) = grep {
     $_->name eq 'test_on_x_and_y_and_z';
 } @{ $t->meta->test_methods };

one can do this:

 my $m = $t->meta->test_methods->{ 'test_on_x_and_y_and_z' };

=cut

use overload '%{}' => sub {
    my %methods;
    @methods{ map { $_->name; } @{ $_[ 0 ] } } = @{ $_[ 0 ] };
    return \%methods;
};

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
