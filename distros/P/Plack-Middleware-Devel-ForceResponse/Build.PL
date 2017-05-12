use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Plack-Middleware-Devel-ForceResponse',
    module_name         => 'Plack::Middleware::Devel::ForceResponse',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/Devel/ForceResponse.pm',
    add_to_cleanup      => [ 'Plack-Middleware-Devel-ForceResponse-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-Devel-ForceResponse',
        bugtracker  => 'http://github.com/bayashi/Plack-Middleware-Devel-ForceResponse/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
