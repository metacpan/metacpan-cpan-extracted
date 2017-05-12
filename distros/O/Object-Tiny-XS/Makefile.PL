use inc::Module::Install;

all_from      'lib/Object/Tiny/XS.pm';
requires      'Class::XSAccessor' => '0.11';

# Test-time dependencies (include as many as we can)
test_requires 'Test::More'      => '0.47';

license 'perl';

WriteAll;
