use inc::Module::Install;

name('Parse-Apache-ServerStatus-Extended');
all_from('lib/Parse/Apache/ServerStatus/Extended.pm');

requires('Parse::Apache::ServerStatus');
requires('Web::Scraper');

auto_include;
auto_install;

WriteAll;
