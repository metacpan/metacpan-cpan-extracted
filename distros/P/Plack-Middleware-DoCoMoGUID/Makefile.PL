use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::Repository;
name 'Plack-Middleware-DoCoMoGUID';
all_from 'lib/Plack/Middleware/DoCoMoGUID.pm';
readme_from 'lib/Plack/Middleware/DoCoMoGUID.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

requires 'Plack::Middleware';
requires 'HTML::StickyQuery::DoCoMoGUID';
requires 'URI';

build_requires 'Test::More';
build_requires 'Plack::Test';
build_requires 'HTTP::Request';
build_requires 'HTML::TreeBuilder::XPath';
build_requires 'Test::LoadAllModules';
build_requires 'Module::Install::ReadmeFromPod';

auto_set_repository;

WriteAll;
