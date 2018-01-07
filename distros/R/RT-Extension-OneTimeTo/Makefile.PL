use inc::Module::Install;

RTx('RT-Extension-OneTimeTo');

repository('https://github.com/bestpractical/rt-extension-onetimeto');

author_tests('xt');
no_index package => "RT::Extension::OneTimeTo::Test";

my ($loaded) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $loaded );
substitute(
    { RT_LIB_PATH => $lib_path },
    { sufix => '.in' },
    'xt/lib/RT/Extension/OneTimeTo/Test.pm',
);

requires_rt '4.2.0';
rt_too_new '4.6.0';

sign;
&WriteAll;
