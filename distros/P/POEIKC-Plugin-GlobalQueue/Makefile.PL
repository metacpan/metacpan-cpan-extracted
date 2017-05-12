use inc::Module::Install;
name 'POEIKC-Plugin-GlobalQueue';
all_from 'lib/POEIKC/Plugin/GlobalQueue.pm';

requires('POE');
requires('POE::Sugar::Args');
requires('POE::Component::IKC::ClientLite');
requires('Class::Inspector');
requires('Class::Accessor::Fast');
#requires('POEIKC::Daemon');
#requires('POEIKC::Client');

build_requires 'Test::More';

features(
    'poeikc daemon' => [
        -default => 0,
        recommends('POEIKC'),
    ],
);

use_test_base;
auto_include_deps;
WriteAll;
