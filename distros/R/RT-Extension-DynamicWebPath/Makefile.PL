use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-DynamicWebPath';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-dynamicwebpath';

requires_rt '4.4.0';
rt_too_new '5.2.0';

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );

substitute(
    {
        RT_LIB_PATH  => $lib_path,
    },
    {
        sufix => '.in'
    },
    'lib/RT/Extension/DynamicWebPath/Test.pm',
);

sign;
WriteAll;
