use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::App::DummyBox',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Plack/App/DummyBox.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Plack::Test' => 0,
        'HTTP::Request::Common' => 0,
        'MIME::Base64' => 0,
        'HTTP::Headers' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Carp' => 0,
        'Plack::Component' => 0,
        'Imager' => 0,
        'Image::Empty' => 0,
        'HTTP::Status' => 0,
        'HTTP::Date' => 0,
        'Plack::Request' => 0,
        'Plack::Util' => 0,
        'Plack::Util::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Plack-App-DummyBox-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Plack-App-DummyBox'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
