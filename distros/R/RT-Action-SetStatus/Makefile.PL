use inc::Module::Install;

RTx 'RT-Action-SetStatus';
all_from 'lib/RT/Action/SetStatus.pm';
readme_from 'lib/RT/Action/SetStatus.pm';
author   q{Kevin Falcone <falcone@bestpractical.com>};
license  'gplv2';

install_script('sbin/rt-create-setstatus-actions');

requires_rt('3.8.0');

my ($lp) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
substitute( { RT_LIB_PATH => $lib_path }, 'sbin/rt-create-setstatus-actions');

WriteAll;

