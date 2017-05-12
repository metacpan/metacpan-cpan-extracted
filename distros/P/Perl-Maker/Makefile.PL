use inc::Module::Install;

all_from 'lib/Perl/Maker.pm';
readme_from;
manifest_skip;
version_check;
ack_xxx;

requires 'Mouse';
requires 'YAML::XS';
requires 'File::ShareDir';
requires 'IPC::Run';

install_script 'bin/perl-maker';

WriteAll;
