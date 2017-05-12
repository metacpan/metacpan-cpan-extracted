#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use Module::Build;

# TODO: Add version specifications for requirements

my $readme;
my $options = GetOptions (
    "readme" => \$readme,
);

my $module_file = "lib/Perl/PrereqInstaller.pm";
my @scripts = grep { -f and !-d } glob 'bin/*';

eval "use Pod::Markdown";
if ( ! $@ ) {
    require Pod::Markdown;
    my $readme_file = "README.md";
    pod2markdown( $module_file, $readme_file ) if $readme;
}

my $builder = Module::Build->new(
    module_name        => 'Perl::PrereqInstaller',
    dist_version_from  => $module_file,
    license            => 'perl',
    create_makefile_pl => 0,
    requires => {
        'perl'                => 5.006,
        "App::cpanminus"      => 0,
        "Carp"                => 0,
        "Cwd"                 => 0,
        "File::Basename"      => 0,
        "File::Find"          => 0,
        "Getopt::Long"        => 0,
        "Perl::PrereqScanner" => 0,
        "Text::Wrap"          => 0,
    },
    build_requires => {
        'Capture::Tiny' => 0,
        'Getopt::Long'  => 0,
        'Test::More'    => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    recommends => {
        # 'Devel::Cover'   => 0,    # To generate testing coverage report
        'Pod::Markdown'  => 0,    # To auto-generate README from POD markup
    },
    script_files   => [ @scripts ],
);

$builder->create_build_script;

exit;

sub pod2markdown {
    my ( $pod_file, $markdown_file ) = @_;
    open my $markdown_fh, ">", $markdown_file
        or die "Cannot open $markdown_file for writing: $!";

    my $travis_ci__badge
        = "https://travis-ci.org/mfcovington/Perl-PrereqInstaller.svg?branch=master";
    my $travis_ci_url
        = "https://travis-ci.org/mfcovington/Perl-PrereqInstaller";
    my $travis_ci_status
        = "[![Build Status]($travis_ci__badge)]($travis_ci_url)";

    my $coveralls_badge
        = "https://coveralls.io/repos/mfcovington/Perl-PrereqInstaller/badge.png?branch=master";
    my $coveralls_url
        = "https://coveralls.io/r/mfcovington/Perl-PrereqInstaller?branch=master";
    my $coveralls_status
        = "[![Coverage Status]($coveralls_badge)]($coveralls_url)";
    print $markdown_fh "$travis_ci_status $coveralls_status\n\n";

    my $parser = Pod::Markdown->new();
    $parser->output_fh($markdown_fh);
    $parser->parse_file($pod_file);
    close $markdown_fh;
}
