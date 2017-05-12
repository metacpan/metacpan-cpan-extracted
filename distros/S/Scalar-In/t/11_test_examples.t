#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan( tests => 3 );

my @data = (
    {
        test   => '01_string_in',
        path   => 'example',
        script => '01_string_in.pl',
        params => '-I../lib -T',
        result => <<'EOT',
Scalar: 1001100111
Array reference: 10011001
Array: 1001100
Hash reference: 010
Hash: 010
EOT
    },
    {
        test   => '02_numeric_in',
        path   => 'example',
        script => '02_numeric_in.pl',
        params => '-I../lib -T',
        result => <<'EOT',
Scalar: 1001110011
Array reference: 10011001
Array: 100110
Hash reference: 010
Hash: 010
EOT
    },
    {
        test   => '03_renamed_import',
        path   => 'example',
        script => '03_renamed_import.pl',
        params => '-I../lib -T',
        result => <<'EOT',
eq: 1
==: 1
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{params} $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
