use inc::Module::Install;

name          'Namespace-Dispatch';
all_from      'lib/Namespace/Dispatch.pm';
author        'shelling <navyblueshellingford@gmail.com>';
repository    'http://github.com/shelling/namespace-dispatch';
license       'MIT';
perl_version  '5.010';


requires      'UNIVERSAL::filename';

tests         't/*.t';
author_tests  'xt';

test_requires 'Test::More';
test_requires 'Modern::Perl';
test_requires 'Try::Tiny';

auto_include;
WriteAll;
