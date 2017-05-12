use inc::Module::Install;

name ('TAP-Harness-Remote-EC2');
author ('Alex Vandiver <alexmv@bestpractical.com>');
version_from ('lib/TAP/Harness/Remote/EC2.pm');
abstract_from('lib/TAP/Harness/Remote/EC2.pm');
license('perl');
requires('Test::More');
requires('TAP::Harness' => 3.04);
requires('TAP::Harness::Remote' => 0.03);
requires('Net::Amazon::EC2');
auto_install();
&WriteAll;
