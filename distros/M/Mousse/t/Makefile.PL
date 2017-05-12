use inc::Module::Install;

name 'Foo';

all_from 'lib/Foo.pm';

use_mousse 'Foo::Mousse';
use_mousse 'Foo::Bar::Baz::Mousse';

# WriteAll;
