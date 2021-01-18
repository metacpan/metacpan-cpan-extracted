use inc::Module::Install;

RTx 'RT-Extension-Gravatar';

repository 'https://github.com/cloos/RT-Extension-Gravatar';

requires 'Crypt::SSLeay';
requires 'Digest::MD5';
requires 'LWP::UserAgent';

requires_rt '4.0.0';
rt_too_new '5.2.0';

no_index( 'package' => 'RT::User' );

substitute(
    { RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ) },
    { sufix => '.in' },
    'xt/lib/RT/Extension/Gravatar/Test.pm',
);

sign;
WriteAll;
