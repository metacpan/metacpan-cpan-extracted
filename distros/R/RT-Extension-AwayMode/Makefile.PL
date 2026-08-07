use inc::Module::Install;

RTx 'RT-Extension-AwayMode';
all_from 'lib/RT/Extension/AwayMode.pm';
license 'gpl_3';

resources(
    repository => 'https://github.com/firefart/RT-Extension-AwayMode.git',
    bugtracker => 'https://github.com/firefart/RT-Extension-AwayMode/issues',
    license    => 'https://opensource.org/licenses/gpl-3.0.html',
);

requires_rt('6.0.0');

WriteAll;
