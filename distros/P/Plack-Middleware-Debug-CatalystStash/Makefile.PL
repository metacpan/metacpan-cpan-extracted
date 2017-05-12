use inc::Module::Install;

all_from('lib/Plack/Middleware/Debug/CatalystStash.pm');

requires 'Catalyst' => '5.90100';
requires 'Data::Dumper';
requires 'Class::Method::Modifiers';
requires 'HTML::Entities';
requires 'Plack::Middleware::Debug';

test_requires 'Test::More' => '0.94';
test_requires 'FindBin';
test_requires 'Catalyst::Test';

resources(
    'bugtracker'  => 'https://github.com/markwellis/plack-middleware-debug-catalyststash/issues',
    'repository'  => 'https://github.com/markwellis/plack-middleware-debug-catalyststash.git',
);

auto_install;
WriteAll;
