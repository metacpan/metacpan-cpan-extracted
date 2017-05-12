use inc::Module::Install;

all_from 'lib/Regexp/Common/WithActions.pm';
readme_from 'lib/Regexp/Common/WithActions.pm';

requires 'Regexp::Common';

WriteAll;
