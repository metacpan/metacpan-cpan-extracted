use inc::Module::Install;

name     'PulseAudio';
all_from 'lib/PulseAudio.pm';
author   q{Evan Carroll <me@evancarroll.com>};
license  'perl';

build_requires 'Test::More';

requires 'Moose' => '2.0';
requires 'IPC::Run3';
requires 'MooseX::Types';
requires 'constant';
requires 'autodie';

requires_external_bin 'pacmd';
requires_external_bin 'env';

repository 'git://github.com/EvanCarroll/perl-pulseaudio.git';
homepage 'https://github.com/EvanCarroll/perl-pulseaudio';

auto_install;

WriteAll;

