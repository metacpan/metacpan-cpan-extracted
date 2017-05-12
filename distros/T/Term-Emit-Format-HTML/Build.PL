use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Term::Emit::Format::HTML',
    license             => 'perl',
    dist_author         => 'Steve Roscio <roscio@cpan.org>',
    dist_version_from   => 'lib/Term/Emit/Format/HTML.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Term-Emit-Format-HTML-*' ],
);

$builder->create_build_script();
