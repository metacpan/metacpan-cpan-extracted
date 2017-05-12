use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        'perl'                            => '5.008001',
        'Amon2'                           => '3.54',
        'Text::Xslate'                    => '1.5006',
        'Test::More'                      => '0.98',
        'Amon2::DBI'                      => '0.06',
        'DBD::SQLite'                     => '1.33',
        'HTML::FillInForm::Lite'          => '1.09',
        'JSON'                            => '2.50',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'Plack::Middleware::Session'      => '0',
        'Plack::Session'                  => '0.14',
        'Test::WWW::Mechanize::PSGI'      => '0',
        'Time::Piece'                     => '1.20',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Task-Amon2',
    module_name => 'Task::Amon2',

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
