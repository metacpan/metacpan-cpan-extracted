use strict;
use Test::More;
use Test::Exception;
use Pandoc::Version;

{
    my %same = (
        array   => [ [ 1, 17, 0, 4 ] ],
        list    => [ ( 1, 17, 0, 4 ) ],
        string  => ['1.17.0.4'],
        vstring => ['v1.17.0.4'],
    );

    foreach ( sort keys %same ) {
        my $version = new_ok 'Pandoc::Version', $same{$_}, "new from $_";
        is_deeply $version->TO_JSON, [qw(1 17 0 4)], "from $_";
    }

    my @invalid = (
        [{}], ['1..2'], ['abc'], ['1.9a'], ['0.-1'],
        [], [''], [undef]
    );

    foreach ( @invalid ) {
        throws_ok { Pandoc::Version->new(@{$_}) }
            qr{^invalid version number}, 'invalid version number';
    }
}

{
    my $version = bless [ 1, 17, 0, 4 ], 'Pandoc::Version';
    new_ok 'Pandoc::Version', [ $version ], 'copy constructor';
    is "$version", '1.17.0.4', 'stringify';
    is $version->number, 1.017000004, 'number';

    my %tests = (
        '1.9' => {
            eq => '1.9',
            gt => '1.10',
        }, 
        '1' => {
            eq => '1.0',
            gt => '1.0.1',
        },
        '1.17.0.4' => {
            eq => '1.17.0.4',
            gt => '1.18',
        }
    );

    foreach ( sort keys %tests ) {
        my $version = Pandoc::Version->new($_);

        my $eq = $tests{$_}{eq};
        my $gt = $tests{$_}{gt};

        ok $version == $eq, "$version == ".$eq;
        ok $version >= $eq, "$version >= ".$eq;
        ok $version <= $eq, "$version <= ".$eq;
        ok $version eq $eq, "$version eq ".$eq;
        ok $version ge $eq, "$version ge ".$eq;
        ok $version le $eq, "$version le ".$eq;

        if ( defined $gt ) {
            ok $version <  $gt, "$version < $gt";
            ok $version lt $gt, "$version lt $gt";
        }
    }
}

{
    my $version = Pandoc::Version->new('1.7.3');

    ok($version->match($_), "1.7.3 match $_") for qw(1 1.7 1.7.3 1.7.3.1);
    ok(!$version->match($_), "1.7.3 no match $_") for qw(1.6 1.8 2);
}

{
    my $version = Pandoc::Version->new('1.7');

    my @yes = qw(1.7 !=1.7.1 >1.6 >=1.7 <1.7.1 <=1.7.1 ==1.7);
    for (@yes, join ', ', @yes) {
        ok $version->fulfills($_), "fulfills $_";
    }

    my @no = qw(1.7,!=1.7 1.7.1 >1.7 >=1.7.1 <1.7 <=1.6 ==1.7.1);
    for (@no, join(', ', @yes, @no)) {
        ok !$version->fulfills($_), "!fulfills $_";
    }

    throws_ok { $version->fulfills('foo') }
        qr/^invalid version requirement: foo/, 'invalid version requirement';
}

done_testing;
