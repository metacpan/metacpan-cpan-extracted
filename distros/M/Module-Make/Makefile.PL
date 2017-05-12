use inc::Module::Install;

die "NOT YET READY FOR PUBLIC USE"
  unless $ENV{IAMINGY};

name        'Module-Make';
all_from    'lib/Module/Make.pm';

requires    perl => '5.6.1';
requires    'Class::Field' => '0';
requires    'IO::All' => '0.37';
requires    'XXX' => '0';

clean_files 't/output';

WriteAll;
