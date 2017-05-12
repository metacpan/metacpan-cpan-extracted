use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::IkiWiki',
    license             => 'gpl',
    dist_author         => '"Victor Moral" <victor@taquiones.net>',
    dist_abstract       => "POD translator for ikiwiki's markdown source",
    dist_version_from   => 'lib/Pod/IkiWiki.pm',
    build_requires => {
        'Test::More'        => 0,
        'Test::NoWarnings'  => 0,
        'Pod::Parser'       => 0,
    },
    requires        =>  {
        'perl'          =>      0,
        'Pod::Parser'   =>      0,
    },
    script_files => [
        qw(scripts/pod2ikiwiki),
        ],
    add_to_cleanup      => [ 'Pod-IkiWiki-*' ],
    resources           =>  {
        license         =>  'http://www.gnu.org/licenses/gpl-3.0.txt',
        homepage        =>  'http://taquiones.net/software/factory/pod-ikiwiki.html',
        repository      =>  'http://taquiones.net/git/pod-ikiwiki',
    },
);

$builder->create_build_script();
