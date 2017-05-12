use inc::Module::Install;

name 'Number-Base-DWIM';

all_from 'lib/Number/Base/DWIM.pm';

requires 'overload' => 0;

WriteAll;

