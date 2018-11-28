# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::ZipBomb',
    VERSION_FROM => 'lib/Mojolicious/Plugin/ZipBomb.pm',
    AUTHOR       => 'Luc Didry <ldidry@cpan.org>',
    ABSTRACT     => 'Mojolicious Plugin to serve a zip bomb on configured routes.',
    PREREQ_PM    => {
        'Mojolicious'             => '8.03',
        'File::Share'             => 0
    },
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install' => 0,
    },
    test => {
        TESTS => 't/*.t'
    }
);

package MY;
use File::ShareDir::Install qw(postamble);
