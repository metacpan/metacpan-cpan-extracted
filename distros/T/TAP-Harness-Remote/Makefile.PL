use inc::Module::Install;

name ('TAP-Harness-Remote');
author ('Alex Vandiver <alexmv@bestpractical.com>');
version_from ('lib/TAP/Harness/Remote.pm');
abstract_from('lib/TAP/Harness/Remote.pm');
license('perl');
requires('Test::More');
requires('YAML');
requires('TAP::Harness' => 3.04);
auto_install();
&WriteAll;
