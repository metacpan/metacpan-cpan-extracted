use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Syntax::Highlight::HTML',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Syntax/Highlight/HTML.pm',
    requires => {
        'HTML::Parser' => '3.00',
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Syntax-Highlight-HTML-*' ],
);

$builder->create_build_script();
