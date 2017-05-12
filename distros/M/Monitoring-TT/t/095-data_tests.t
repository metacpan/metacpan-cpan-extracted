use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

# get test data folders
my @folders = glob('t/data/*');
my $tests   = `grep TestUtils::test_montt t/2*.t`;
my @tests   = $tests =~ m/test_montt\(\'([^']+)\'/gmx;

ok(scalar @folders > 0, 'got '.(scalar @folders).' folders');
ok(scalar @tests   > 0, 'got '.(scalar @tests  ).' tests');


my %tests = ();
for my $d (@tests) {
    $tests{$d} = $d;
}

for my $d (@folders) {
    next if $d =~ m|t/data/1\d+-input_|mx;
    fail('no test covers: '.$d) unless defined $tests{$d};
}

done_testing();
