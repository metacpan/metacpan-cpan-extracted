use inc::Module::Install;

name 'RT-Extension-TimeWorkedReport';
all_from 'lib/RT/Extension/TimeWorkedReport.pm';
readme_from 'lib/RT/Extension/TimeWorkedReport.pm';
include 'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Extension-TimeWorkedReport' unless $ENV{DIST_BUILD};

WriteAll;
