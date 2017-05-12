sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use inc::Module::Install;
name 'Plack-App-PgREST';
all_from 'lib/Plack/App/PgREST.pm';
readme_from 'lib/Plack/App/PgREST.pm';
build_requires 'Test::More' => 0.88;

requires 'methods';
requires 'Router::Resource';
requires 'Plack';
requires 'JSON::XS';
requires 'DBIx::Connector';
requires 'DBD::Pg';
requires 'Tie::IxHash';

auto_include_deps;
extra_tests;
auto_set_repository;
WriteAll;
