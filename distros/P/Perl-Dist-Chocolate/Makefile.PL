use inc::Module::Install 0.77;

all_from      'lib/Perl/Dist/Chocolate.pm';
requires      'Perl::Dist::Strawberry' => '1.07';
test_requires 'Test::More'             => '0.42';
test_requires 'LWP::Online'            => '1.07';

WriteAll;
