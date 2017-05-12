use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    'module_name' => 'Mozilla::Mechanize',
    'dist_author' => 'Scott Lanning <slanning@cpan.org>',
    'license' => 'perl',

    'requires' => {
        'Gtk2::MozEmbed' => '0.04',
        'Mozilla::DOM' => '0.20',   # perlish list-returning methods
        'perl' => '5.8.0',
#        'Mime::Base64' => 0,
    },
    'build_requires' => {
        'Test::More' => '0.54',
    },

    'create_makefile_pl' => 'passthrough',
);

$build->create_build_script();
