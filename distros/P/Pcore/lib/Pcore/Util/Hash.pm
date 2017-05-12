package Pcore::Util::Hash;

use Pcore;
use Hash::Util qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use Pcore::Util::Scalar qw[blessed];

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

    foreach my $key ( keys $b->%* ) {
        if ( blessed( $a->{$key} ) && $a->{$key}->can('MERGE') ) {
            $a->{$key} = $a->{$key}->MERGE( $b->{$key} );
        }
        elsif ( ref( $b->{$key} ) eq 'HASH' ) {
            $a->{$key} = {} unless ( ref( $a->{$key} ) eq 'HASH' );

            _merge( $a->{$key}, $b->{$key} );
        }
        elsif ( ref( $b->{$key} ) eq 'ARRAY' ) {
            $a->{$key} = [];

            $a->{$key}->@* = $b->{$key}->@*;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]
        }
        else {
            $a->{$key} = $b->{$key};
        }
    }

    return;
}

sub multivalue {
    state $init = !!require Pcore::Util::Hash::Multivalue;

    return Pcore::Util::Hash::Multivalue->new(@_);
}

sub randkey {
    state $init = !!require Pcore::Util::Hash::RandKey;

    return Pcore::Util::Hash::RandKey->new;
}

sub limited ($max_size) {
    state $init = !!require Pcore::Util::Hash::Limited;

    return Pcore::Util::Hash::Limited->new($max_size);
}

1;
__END__
=pod

=encoding utf8

=cut
