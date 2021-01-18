use inc::Module::Install;

RTx 'RT-Extension-HistoryFilter';

repository 'https://github.com/cloos/RT-Extension-HistoryFilter';

requires_rt '4.0.0';
rt_too_new '5.2.0';

no_index( 'package' => 'RT::Transaction' );

substitute(
    { RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ) },
    { sufix => '.in' },
    'xt/lib/RT/Extension/HistoryFilter/Test.pm',
);

sign;
WriteAll;
