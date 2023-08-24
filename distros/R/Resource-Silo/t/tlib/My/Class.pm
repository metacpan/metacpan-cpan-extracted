package My::Class;

=head1 NAME

My::Class - closes happily over whatever arguments are passed to new().

=cut

use strict;
use warnings;

sub new {
    my ($class, %opt) = @_;
    return bless \%opt, $class;
};

1;
