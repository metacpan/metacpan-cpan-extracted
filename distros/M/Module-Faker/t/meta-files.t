use strict;
use warnings;

use Test::More;

use Module::Faker::Dist;
use File::Temp ();
use CPAN::Meta;

my @expected = qw(
    Makefile.PL
    META.yml
    META.json
);

plan tests => 2 + @expected;

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file('./eg/Provides-Inner.yml');

isa_ok($dist, $MFD);

my $dir = $dist->make_dist_dir({ dir => $tmpdir });

for my $f ( @expected ) {
    ok(
    -e "$dir/$f",
    "there's a $f",
    );
}

my $meta = CPAN::Meta->load_file( "$dir/META.json" );
is_deeply(
    $meta->provides,
    {
        'Provides::Inner' => {
            file => 'lib/Provides/Inner.pm',
            version => 0.001,
        },
        'Provides::Inner::Util' => {
            file => 'lib/Provides/Inner.pm',
            version => 0.867,
        },
        'Provides::Outer' => {
            file => 'lib/Provides/Outer.pm',
        },
    },
    "provides is correct"
);

