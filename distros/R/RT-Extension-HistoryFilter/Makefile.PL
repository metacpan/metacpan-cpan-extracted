use inc::Module::Install;

RTx 'RT-Extension-HistoryFilter';

repository 'https://github.com/cloos/RT-Extension-HistoryFilter';

rt_too_new '4.6.0';

no_index( 'package' => 'RT::Transaction' );

sign;
WriteAll;
