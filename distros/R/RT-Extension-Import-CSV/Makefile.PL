use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-Import-CSV';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-import-csv';

requires_rt '5.0.0';
rt_too_new '6.2.0';
requires 'Text::CSV_XS';
requires 'Test::MockTime';

use Config;
my $perl_path = $Config{perlpath};
$perl_path .= $Config{_exe}
    if $^O ne 'VMS' and $perl_path !~ m/$Config{_exe}$/i;

substitute( {
        RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ),
        PERL        => $perl_path,
    },
    { sufix => ".in" },
    'bin/rt-extension-import-csv',
);

sign;
WriteAll;
