use strict;
use warnings;
use inc::Module::Install 0.76;
name 'Shipwright';
author 'sunnavy <sunnavy@bestpractical.com>';
all_from 'lib/Shipwright.pm';
repository 'git://github.com/bestpractical/shipwright.git';
perl_version '5.008008';

build_requires 'Test::More' => 0;
build_requires 'IPC::Cmd' => 0;

requires 'Module::Build' => 0;
requires 'App::CLI' => 0;
requires 'Algorithm::Dependency::Ordered' => 0;
requires 'Algorithm::Dependency::Source::HoA' => 0;
requires 'CPAN' => 1.9205;
requires 'CPAN::DistnameInfo' => 0;
requires 'Class::Accessor::Fast' => 0;
recommends 'Class::XSAccessor::Compat' => 0;
requires 'File::Temp' => 0.18;
requires 'File::Copy' => 0;
requires 'File::Copy::Recursive' => 0;
requires 'File::Spec' => 0;
requires 'File::Slurp' => 0;
requires 'IPC::Run3' => 0;
requires 'List::MoreUtils' => 0;
requires 'Log::Log4perl' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Module::CoreList' => 0;
requires 'UNIVERSAL::require' => 0;
requires 'version' => 0;
requires 'Module::Info' => 0;
requires 'YAML::Tiny' => 0;
requires 'IO::Uncompress::Bunzip2' => 0;
requires 'IO::Uncompress::RawInflate' => '2.012';
requires 'Archive::Tar' => 0;
requires 'Archive::Extract' => 0;
requires 'File::Compare' => 0;
requires 'File::Path' => 2.07;
requires 'File::Which' => 0;

no_index( directory => 't' );
no_index( directory => 'xt' );

install_script('bin/shipwright');
install_script('bin/shipwright-generate');
install_share;
auto_install;

tests('t/*.t t/*/*.t');
recursive_author_tests('xt/');
WriteAll;
