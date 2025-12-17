package BadHandle;
use strict;
use warnings;
use parent 'Tie::StdHandle';

sub TIEHANDLE {
    my ($class, $size, $fail_after) = @_;
    return bless {
        fail_after => $fail_after,
        chunk_size => $size,
    }, shift;
}

sub READ {
    my $self = $_[0];
    if ($self->{fail_after}--) {
        $_[1]= ( 'a' x $self->{chunk_size} );
        return 1;
    }
        
    $! = 17; # random non-0 error number
    return undef;
}

1;
