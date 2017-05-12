use inc::Module::Install 0.77;
use Module::Install::AutoManifest;
use Module::Install::ReadmeFromPod;

# See http://search.cpan.org/~falcone/Module-Install-RTx/lib/Module/Install/RTx.pm
use Module::Install::RTx;
RTx ('RT-Extension-SMSNotify');
# May work with older versions but not tested
requires_rt('4.0.7');

name 'RT-Extension-SMSNotify';

all_from       'lib/RT/Extension/SMSNotify.pm';
build_requires 'Module::Install::AutoManifest'  => '0.003';
build_requires 'Module::Install::ReadmeFromPod' => '0.20';
requires       'Carp'                           => 0;
requires       'SMS::Send'                      => '1.06';
requires       'Module::Install::RTx'           => '0.30';
test_requires  'Test::More'                     => '0.47';

readme_from 'lib/RT/Extension/SMSNotify.pm';

license 'perl';

auto_manifest;

homepage 'https://github.com/2ndQuadrant/rt-extension-smsnotify-perl';
bugtracker 'https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=RT-Extension-SMSNotify';
repository 'git://github.com/2ndQuadrant/rt-extension-smsnotify-perl.git';

auto_install();

WriteAll;
