use inc::Module::Install;
name           'Test-DataLoader-MySQL';
author         'Takuya Tsuchida tsucchi@cpan.org';
license        'perl';
all_from       'lib/Test/DataLoader/MySQL.pm';
requires       'DBI';
requires       'DBD::mysql';
test_requires  'Test::More';
test_requires  'DBI';
recommends     'Test::mysqld' => '0.11';

author_tests   'xt';

author_requires 'Test::Perl::Critic';
author_requires 'Test::Synopsis';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Module::Used' => '0.1.4';

WriteAll;
