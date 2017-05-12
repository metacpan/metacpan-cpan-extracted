use strict;
use warnings;
use Test::More;
use Test::Database::Driver;
use version;

# test version_matches() on a dummy driver

my @tests = (
    [ '', 'dbi:Dummy:' ],
    [ '', 'dbi:Dummy:bam=boff',             qw( bam boff ) ],
    [ '', 'dbi:Dummy:bam=boff;z_zwap=plop', qw( bam boff z_zwap plop ) ],
    [   'dbi:Dummy:bam=boff', 'dbi:Dummy:bam=boff;z_zwap=plop',
        qw( z_zwap plop )
    ],
    [   'dbi:Dummy:bam=boff',
        'dbi:Dummy:bam=boff;z_zwap=plop;zowie=sock',
        qw( z_zwap plop zowie sock )
    ],
);

@Test::Database::Driver::Dummy::ISA = qw( Test::Database::Driver );

plan tests => scalar @tests;

for my $t (@tests) {
    my ( $driver_dsn, $dsn, @args ) = @$t;
    my $driver = bless { driver_dsn => $driver_dsn },
        'Test::Database::Driver::Dummy';

    my $got = $driver->make_dsn(@args);
    is( $got, $dsn, $driver->driver_dsn() . ' ' . to_string(@args) );
}

sub to_string {
    my %args = @_;
    return
        '( ' . join( ', ', map {"$_ => $args{$_}"} sort keys %args ) . ' )';
}

