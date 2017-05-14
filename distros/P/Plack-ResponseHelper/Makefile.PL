use inc::Module::Install;

name          'Plack-ResponseHelper';
version       '0.05';
author        'Oleg Komarov <komarov@cpan.org>';

all_from      'lib/Plack/ResponseHelper.pm';
requires      'Carp';
requires      'JSON' => '2.00';
requires      'Plack::Response';
test_requires 'Test::Deep';
test_requires 'Test::Exception';
test_requires 'Test::More' => '0.87';

no_index directory => 'eg';

WriteAll;
