use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::Middleware::TMT',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/Middleware/TMT.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Builder' => 0,
        'Plack::Test' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request::Common' => 0,
    },
    requires => {
        'perl' => '5.8.5',
        'Plack::Middleware' => 0,
        'Plack::Request' => 0,
        'Plack::Util::Accessor' => 0,
        'Carp' => 0,
        'Text::MicroTemplate::File' => 0,
    },
    add_to_cleanup      => [ 'Plack-Middleware-TMT-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-Middleware-TMT'
      }
    },
);

$builder->create_build_script();
