use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

BEGIN {
    eval { require Test::Pod; require Test::Pod::Coverage; 1 }
        or plan skip_all => 'Install Test::Pod and Test::Pod::Coverage for author checks';
}

my $root = File::Spec->catdir($FindBin::RealBin, '..', '..');
my $module = File::Spec->catfile($root, 'lib', 'Perl', 'CodeMap.pm');
my $cli = File::Spec->catfile($root, 'bin', 'perl-codemap');

Test::Pod::pod_file_ok($module, 'module POD has no syntax errors');
Test::Pod::pod_file_ok($cli, 'CLI POD has no syntax errors');
Test::Pod::Coverage::pod_coverage_ok(
    'Perl::CodeMap',
    { also_private => [qr/^_/] },
    'document all public Perl::CodeMap methods',
);

done_testing;
