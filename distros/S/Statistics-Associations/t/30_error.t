use strict;
use Statistics::Associations;
use Test::More tests => 6;

my $asso = Statistics::Associations->new;

# argument of make_matrix() is not enough
{

    # no args
    eval { $asso->make_matrix(); };
    if ($@) {
        like(
            $@,
            qr/ERROR: undefined row_label is posted/,
            'make_matrix() returns error message-1'
        );
    }

    # one args
    eval { $asso->make_matrix("row"); };
    if ($@) {
        like(
            $@,
            qr/ERROR: undefined col_label is posted/,
            'make_matrix() returns error message-2'
        );
    }
}

# phi() is called without matrix
{
    my $matrix = [ [ 0, 0, 0, 3 ], [ 1, 0, 3, 4 ], [ 3, 0, 2, 9 ], ];
    eval { my $phi = $asso->phi(); };
    if ($@) {
        like(
            $@,
            qr/ERROR: invalid matrix is posted/,
            'phi() returns error message'
        );
    }
}

# contingency() is called without matrix
{
    my $matrix = [ [ 0, 0, 0, 3 ], [ 1, 0, 3, 4 ], [ 3, 0, 2, 9 ], ];
    eval { my $contingency = $asso->contingency(); };
    if ($@) {
        like(
            $@,
            qr/ERROR: invalid matrix is posted/,
            'contingency() returns error message'
        );
    }
}

# cramer() is called without matrix
{
    my $matrix = [ [ 0, 0, 0, 3 ], [ 1, 0, 3, 4 ], [ 3, 0, 2, 9 ], ];
    eval { my $cramer = $asso->cramer(); };
    if ($@) {
        like(
            $@,
            qr/ERROR: invalid matrix is posted/,
            'cramer() returns error message'
        );
    }
}

# chisq() is called without matrix
{
    my $matrix = [ [ 0, 0, 0, 3 ], [ 1, 0, 3, 4 ], [ 3, 0, 2, 9 ], ];
    eval { my $chisq = $asso->chisq(); };
    if ($@) {
        like(
            $@,
            qr/ERROR: invalid matrix is posted/,
            'chisq() returns error message'
        );
    }
}
