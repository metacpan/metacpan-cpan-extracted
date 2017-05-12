use lib 'lib'; # bootstrap
use inc::Module::Install;
all_from 'lib/Module/Install/CPANfile.pm';
readme_from('lib/Module/Install/CPANfile.pm');
auto_set_repository();
auto_provides;
cpanfile;
WriteAll;

