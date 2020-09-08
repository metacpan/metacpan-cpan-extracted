use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-TravisCI';

no_index package => 'RT::Extension::TravisCI::Test';
license 'gplv2';

repository 'https://github.com/bestpractical/rt-extension-travisci';

requires_rt '5.0.0';
rt_too_new '5.2.0';

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );


substitute(
    {
        RT_LIB_PATH  => $lib_path,
    },
    {
        sufix => '.in',
    },
    qw(lib/RT/Extension/TravisCI/Test.pm),
);

sign;
WriteAll;
