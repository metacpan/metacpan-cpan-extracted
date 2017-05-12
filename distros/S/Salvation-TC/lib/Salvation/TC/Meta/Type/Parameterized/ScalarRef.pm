package Salvation::TC::Meta::Type::Parameterized::ScalarRef;

=head1 NAME

Salvation::TC::Meta::Type::Parameterized::ScalarRef - Класс для типа параметризованного ScalarRef.

=cut

use strict;
use warnings;
use boolean;

use base 'Salvation::TC::Meta::Type::Parameterized';

=head1 METHODS

=cut

=head2 iterate( ScalarRef $value, CodeRef $code )

=cut

sub iterate {

    my ( $self, $value, $code ) = @_;
    my $clone = undef;

    $code -> ( $$value, undef, \$clone );

    return \$clone;
}


1;

__END__
