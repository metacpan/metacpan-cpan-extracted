package t::roles::MiamiSpace;

use parent 'UNIVERSAL::Object';

our %HAS;
BEGIN {
    %HAS = (
        miami => sub {
            return {
                space => {
                    rank => 9,
                }
            };
        }
    );
}

sub plus {
    return 1;
}

sub minus {
    return 0;
}

sub miamispace_rank {
    return $_[0]->{miami}->{space}->{rank};
}

1;


