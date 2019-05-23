package Pcore::Util::Hash;

use Pcore;
use Hash::Util qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Pcore::Util::Scalar qw[is_blessed_ref is_plain_arrayref is_plain_hashref];

sub merge {
    my $res = defined wantarray ? {} : shift;

    for my $hash_ref (@_) {
        _merge( $res, $hash_ref );
    }

    return $res;
}

sub _merge {
    my $a = shift;
    my $b = shift;

    for my $key ( keys $b->%* ) {
        if ( is_blessed_ref $a->{$key} && $a->{$key}->can('MERGE') ) {
            $a->{$key} = $a->{$key}->MERGE( $b->{$key} );
        }
        elsif ( is_plain_hashref $b->{$key} ) {
            $a->{$key} = {} if !is_plain_hashref $a->{$key};

            _merge( $a->{$key}, $b->{$key} );
        }
        elsif ( is_plain_arrayref $b->{$key} ) {
            $a->{$key} = [];

            $a->{$key}->@* = $b->{$key}->@*;
        }
        else {
            $a->{$key} = $b->{$key};
        }
    }

    return;
}

sub multivalue {
    require Pcore::Util::Hash::Multivalue;

    return Pcore::Util::Hash::Multivalue->new(@_);
}

sub randkey {
    require Pcore::Util::Hash::RandKey;

    return Pcore::Util::Hash::RandKey->new;
}

sub limited ($max_size) {
    require Pcore::Util::Hash::LRU;

    return Pcore::Util::Hash::LRU->new($max_size);
}

1;
__END__
=pod

=encoding utf8

=cut
