
use Test::More tests => 5;

use_ok('Tao::DBI::st_deep');

sub to_perl {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper(shift);
}

my $ctl = [ 'a' => 'a', 'y' => 'b', '*' => 'z' ];
my $hash = {
    a => 'string',
    y => 42,                 # number
    c => 'another string',

    #b => 6,
    d => [ 1, 2, 3 ],
    e => { k => 'v' },

};

# TODO: removing entries in original hash: maybe 'b' => undef

my $tr_hash = Tao::DBI::st_deep::tr_hash( $hash, $ctl );

my $out = {
    a => 'string',
    b => 42,
    z => {
        c => 'another string',
        d => [ 1, 2, 3 ],
        e => { k => 'v' }
    }
};

is_deeply( $tr_hash, $out, 'tr_hash() works' );

my $back = Tao::DBI::st_deep::tr_hash( $tr_hash, $ctl, 1 );

is_deeply( $back, $hash, 'tr_hash() inverse works' );

# now testing transforms

my $ctl2 = [ 'a' => 'a', 'y' => 'b', '*' => 'z:ddumper' ];

my $tr_hash2 = Tao::DBI::st_deep::tr_hash( $hash, $ctl2 );

my $out2 = {
    a => 'string',
    b => 42,
    z => to_perl(
        {
            c => 'another string',
            d => [ 1, 2, 3 ],
            e => { k => 'v' }
        }
    )
};

is_deeply( $tr_hash2, $out2, 'tr_hash() with transforms works' );

my $back2 = Tao::DBI::st_deep::tr_hash( $tr_hash2, $ctl2, 1 );

is_deeply( $back2, $hash, 'tr_hash() inverse with transforms works' );

