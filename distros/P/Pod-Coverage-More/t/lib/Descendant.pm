package Descendant;

use 5.036;
use warnings FATAL => q{all};

use parent 'Ancestor';

=head1 NAME

Descendant - overrides the hook that Ancestor documents

=cut

sub hook {
    my ( $self, $record ) = @_;
    $record->{seen} = 1;
    return;
}

1;
