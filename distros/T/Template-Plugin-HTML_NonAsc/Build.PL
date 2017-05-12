#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.008003;

use 5.008003;			# for sane Unicode handling

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::HTML_NonAsc',
    license             => 'perl',
    dist_author         => 'Johan Vromans <jv@cpan.org>',
    dist_version_from   => 'lib/Template/Plugin/HTML_NonAsc.pm',
    requires => {
        'HTML::Entities' => 0,
	'Template' => 0.22,
    },
    build_requires => {
        'Test::More' => 0,
        'HTML::Entities' => 0,
	'Template' => 0.22,
    },
    add_to_cleanup      => [ 'Template-Plugin-HTML_NonAsc-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
