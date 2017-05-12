use inc::Module::Install 0.77;
use Module::Install::AutoManifest;
use Module::Install::ReadmeFromPod;

name 'SMS-Send-RedOxygen';

all_from      'lib/SMS/Send/RedOxygen.pm';
requires      'Carp'            => 0;
requires      'SMS::Send'       => '1.06';
requires      'LWP'             => '5.69';
test_requires 'Test::More'      => '0.47';

readme_from 'lib/SMS/Send/RedOxygen.pm';

auto_manifest;

homepage 'https://github.com/ringerc/sms-send-redsms-perl';
bugtracker 'https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=SMS-Send-RedOxygen';
repository 'git://github.com/ringerc/sms-send-redsms-perl.git';

WriteAll;
