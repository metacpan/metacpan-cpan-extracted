#!/usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use Module::Build;

# TODO: Add version specifications for requirements

my $readme;
my $options = GetOptions (
    "readme" => \$readme,
);

my $module_file = "lib/Number/RangeTracker.pm";
my @scripts = grep { -f and !-d } glob 'bin/*';

eval "use Pod::Markdown";
if ( ! $@ ) {
    require Pod::Markdown;
    my $readme_file = "README.md";
    pod2markdown( $module_file, $readme_file ) if $readme;
}

my $builder = Module::Build->new(
    module_name         => 'Number::RangeTracker',
    license             => 'perl',
    dist_author         => q{Michael F. Covington <mfcovington@gmail.com>},
    dist_version_from   => $module_file,
    release_status      => 'stable',
    configure_requires => {
        'Getopt::Long'  => 0,
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'            => 5.006,
        'Carp'            => 0,
        'List::MoreUtils' => 0,
        'List::Util'      => 0,
        'Mouse'           => 0,
        'Scalar::Util'    => 0,
    },
    recommends => {
        # 'Devel::Cover'   => 0,    # To generate testing coverage report
        'Pod::Markdown'  => 0,    # To auto-generate README from POD markup
    },
    add_to_cleanup     => [ 'Number-RangeTracker-*' ],
    create_makefile_pl => 0,
    script_files   => [ @scripts ],
);

$builder->create_build_script();

exit;

sub pod2markdown {
    my ( $pod_file, $markdown_file ) = @_;
    open my $markdown_fh, ">", $markdown_file
        or die "Cannot open $markdown_file for writing: $!";

    my $travis_ci__badge
        = "https://travis-ci.org/mfcovington/Number-RangeTracker.svg?branch=master";
    my $travis_ci_url
        = "https://travis-ci.org/mfcovington/Number-RangeTracker";
    my $travis_ci_status
        = "[![Build Status]($travis_ci__badge)]($travis_ci_url)";

    my $coveralls_badge
        = "https://coveralls.io/repos/mfcovington/Number-RangeTracker/badge.png?branch=master";
    my $coveralls_url
        = "https://coveralls.io/r/mfcovington/Number-RangeTracker?branch=master";
    my $coveralls_status
        = "[![Coverage Status]($coveralls_badge)]($coveralls_url)";
    print $markdown_fh "$travis_ci_status $coveralls_status\n\n";

    my $parser = Pod::Markdown->new();
    $parser->output_fh($markdown_fh);
    $parser->parse_file($pod_file);
    close $markdown_fh;
}
