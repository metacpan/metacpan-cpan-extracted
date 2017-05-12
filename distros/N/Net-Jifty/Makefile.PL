use inc::Module::Install;

name 'Net-Jifty';
all_from 'lib/Net/Jifty.pm';

requires 'Any::Moose' => '0.04';
requires 'LWP::UserAgent';
requires 'YAML';
requires 'URI';
requires 'Encode' => '2.41';

build_requires 'Test::More';
build_requires 'Test::MockObject';

feature 'Date loading' => -default => 0,
    'DateTime'          => 0;
feature 'Cascading directory config' => -default => 0,
    'Hash::Merge'                    => 0,
    'Path::Class'                    => 0,
    'Cwd'                            => 0;

feature 'Email address comparison' => -default => 0,
    'Email::Address'               => 0;
feature 'Hiding password entry' => -default => 0,
    'Term::ReadKey'             => 0;
auto_install;
WriteAll;

