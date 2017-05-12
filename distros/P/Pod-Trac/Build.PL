use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Pod::Trac',
    license           => 'perl',
    dist_author       => 'franck cuny <franck.cuny@gmail.com>',
    dist_version_from => 'lib/Pod/Trac.pm',
    requires          => {
        'Test::More'            => 0,
        'version'               => 0,
        'Test::Perl::Critic'    => 0,
        'File::Util'            => 0,
        'URI::Escape'           => 0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Cookies'         => 0,
        'Pod::Simple::Wiki'     => 0,
        'Class::Accessor::Fast' => 0,

    },
    add_to_cleanup => [ 'Pod-Trac-*' ],
);

$builder->create_build_script();
