use  inc::Module::Install;
license('perl');
name('RT-Extension-RT2toRT3');
all_from('RT2toRT3.pm');
no_index( 'directory' => 'tools' );
no_index( 'directory' => 'examples' );
#requires("RT");  # RT is often somewhere not in @INC
install_script('rt-2.0-to-dumpfile');
install_script('dumpfile-to-rt-3.0');
WriteAll;
