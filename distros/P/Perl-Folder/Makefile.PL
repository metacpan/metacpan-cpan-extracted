use inc::Module::Install;

name            'Perl-Folder';
all_from        'lib/Perl/Folder.pm';

requires        'perl' => '5.6.1';

# use_test_base;

perldoc;

WriteAll;
