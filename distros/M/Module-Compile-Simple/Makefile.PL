use 5.006;
use inc::Module::Install;

name            'Module-Compile-Simple';
all_from        'lib/Module/Compile/Simple.pm';

clean_files     't/lib/*.pmc';

WriteAll;
