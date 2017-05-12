use inc::Module::Install;

name 'RT-Extension-SavedSearchResults';
all_from 'lib/RT/Extension/SavedSearchResults.pm';
readme_from 'lib/RT/Extension/SavedSearchResults.pm';
include 'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Extension-SavedSearchResults' unless $ENV{DIST_BUILD};

WriteAll;
