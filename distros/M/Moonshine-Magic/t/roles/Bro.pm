package t::roles::Bro;

use parent 'UNIVERSAL::Object';

our %HAS;
BEGIN {
    %HAS = (
        bro_rank => sub { return 3; },
    );
}

sub true {
    return 1;
}

sub false {
    return 0;
}

sub bro_rank {
    return $_[0]->{bro_rank}
}

1;
