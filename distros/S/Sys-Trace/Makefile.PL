use inc::Module::Install;
  
# Define metadata
name           'Sys-Trace';
all_from       'lib/Sys/Trace.pm';
license        'wtfpl';
repository     'git://github.com/dgl/perl-Sys-Trace';
bugtracker     'http://github.com/dgl/perl-Sys-Trace/issues';
 
# Specific dependencies
requires       'Text::Balanced' => '0';
no_index       directory   => "t",
               directory   => "My";
 
WriteAll;
