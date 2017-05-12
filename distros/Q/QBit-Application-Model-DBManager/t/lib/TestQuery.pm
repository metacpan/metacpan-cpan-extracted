package TestQuery;

use qbit;

use base qw(QBit::Class);

our $DATA;

sub all_langs {$_[0]}

sub get_all {
    return $DATA;
}

TRUE;
