use Test::Most;
use File::Spec;
use FindBin;

use lib 'bin';
do 'generate_wrap_config.pl';

use constant SAMPLE_DIR => "$FindBin::Bin/samples";

my @cases = (
    {
        name     => 'multiple packages',
        sample   => 'multiple_packages.pm',
        expected => [qw/
          Multi::foo
          Multi::One::foo
          Multi::Two::foo
          Multi::Three::foo
          Multi::Four::foo
          Multi::bar
          Multi::One::bar1
          Multi::Two::bar2
          Multi::Three::bar3
          Multi::Four::bar4
        /],
    },
    {
        name     => 'wrapped subroutines',
        sample   => 'wrapped.pm',
        expected => [qw/
          Wrapped::foo
          Wrapped::bar
          Wrapped::baz
        /],
    },
    {
        name     => 'imported subroutines',
        sample   => 'imported.pm',
        expected => [qw/
          Imported::foo
        /],
    },
    {
        name     => 'no packages',
        sample   => 'no_packages.pm',
        expected => [qw/
          main::foo
          main::bar
        /],
    },
    ({
        name     => 'multiple packages with block syntax',
        sample   => 'multiple_packages_block_syntax.pm',
        expected => [qw/
            Multi::foo
            Multi::bar
            Multi::Two::foo
            Multi::Two::bar2
            Multi::Three::foo
            Multi::Three::bar3
            Multi::One::foo
            Multi::One::bar1
        /],
    }) x ($^V ge v5.14),
);
plan tests => scalar @cases;

foreach (@cases) {
    my ($name, $sample, $exp) = @$_{qw[ name sample expected ]};
    my $sample_path = File::Spec->catfile(SAMPLE_DIR, $sample);
    my @got = OpenTracing::WrapScope::ConfigGenerator::list_subs($sample_path);
    cmp_deeply \@got, bag(@$exp), $name or diag explain \@got;
}
