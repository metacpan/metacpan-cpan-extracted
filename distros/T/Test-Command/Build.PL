use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Command',
    license             => 'perl',
    dist_author         => 'Daniel B. Boorstein <danboo@cpan.org>',
    dist_version_from   => 'lib/Test/Command.pm',
    build_requires => {
        'Test::Simple' => 0.62,
    },
    add_to_cleanup      => [ 'Test-Command-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge          => {
       resources => {
          repository => 'https://github.com/danboo/perl-test-command',
          homepage   => 'https://metacpan.org/release/Test-Command',
          bugtracker => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Command',
       },
    },
);

$builder->create_build_script();
