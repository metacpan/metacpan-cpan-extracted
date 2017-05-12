use inc::Module::Install;
 
all_from 'lib/Spork.pm';
requires_from 'lib/Spork.pm';
ack_xxx;
readme_from;
version_check;
manifest_skip 'clean';
 
install_script 'bin/spork';
 
clean_files 't/spork';
 
WriteAll;
