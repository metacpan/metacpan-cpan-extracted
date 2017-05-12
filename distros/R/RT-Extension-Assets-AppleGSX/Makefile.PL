use inc::Module::Install;


RTx 'RT-Extension-Assets-AppleGSX';
all_from 'lib/RT/Extension/Assets/AppleGSX.pm';
readme_from 'lib/RT/Extension/Assets/AppleGSX.pm';
license  'gplv2';

requires 'Class::Accessor::Fast';
requires 'LWP::UserAgent';
requires 'XML::SAX';
requires 'XML::Simple';

use Config;
my $perl_path = $Config{perlpath};
$perl_path .= $Config{_exe}
    if $^O ne 'VMS' and $perl_path !~ m/$Config{_exe}$/i;

substitute( {
        RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ),
        PERL        => $perl_path,
    },
    { sufix => ".in" },
    'bin/rt-apple-gsx-set-warranty',
);

sign;
WriteAll;
