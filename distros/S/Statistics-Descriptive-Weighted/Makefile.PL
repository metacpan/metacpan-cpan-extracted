use inc::Module::Install;
    
perl_version('5.005');
all_from('lib/Statistics/Descriptive/Weighted.pm');
requires('Statistics::Descriptive' => 2.6);
WriteAll;
