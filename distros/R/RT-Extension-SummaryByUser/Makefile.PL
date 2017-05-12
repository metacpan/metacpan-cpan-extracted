use inc::Module::Install;

RTx('RT-Extension-SummaryByUser');

requires 'DBIx::SearchBuilder' => '1.56';

rt_too_new('4.2.0');

sign();
WriteAll();
