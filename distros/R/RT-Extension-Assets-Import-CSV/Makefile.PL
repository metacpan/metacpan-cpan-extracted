use inc::Module::Install;

RTx 'RT-Extension-Assets-Import-CSV';

use Config;
my $perl_path = $Config{perlpath};
$perl_path .= $Config{_exe}
    if $^O ne 'VMS' and $perl_path !~ m/$Config{_exe}$/i;

substitute( {
        RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ),
        PERL        => $perl_path,
    },
    { sufix => ".in" },
    'bin/rt-assets-import-csv',
);

requires_rt '4.4.0';
requires 'Text::CSV_XS';

WriteAll;
