use strict;
use warnings;
use Module::Build;

die 'OS unsupported! Sorry, but this system seems not to be a linux system!'
   unless $^O =~ /linux/i;

die 'OS unsupported! Stupid! RTFM and gimme me access to /proc ;-)'
   unless -r '/proc';

my $build = Module::Build->new(
    create_readme => 1,
    license       => 'perl',
    module_name   => 'Sys::Statistics::Linux',
    dist_author   => 'Jonny Schulz',
    sign          => 0,
    recommends    => {
        'YAML::Syck'  => 0,
    },
    requires      => {
        'Carp'        => 0,
        'POSIX'       => 0,
        'Test::More'  => 0,
        'Time::HiRes' => 0,
        'UNIVERSAL'   => 0,
    },
);

$build->create_build_script;
