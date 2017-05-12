# Load the Module::Install bundled in ./inc/
use inc::Module::Install 0.65;

name 'MooseX-LazyLogDispatch';
all_from 'lib/MooseX/LazyLogDispatch.pm';

test_requires 'Test::More' => '0.42';
test_requires 'IO::Scalar' => '2.110';

requires 'Moose'                       => '0';
requires 'Log::Dispatch::Configurator' => '0';

# Rebuild README for maintainers
system("pod2text lib/MooseX/LazyLogDispatch.pm >README") if -e 'MANIFEST.SKIP';

auto_provides;
auto_install;
WriteAll;
