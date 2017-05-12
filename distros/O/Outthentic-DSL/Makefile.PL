use inc::Module::Install;

# Define metadata
name           'Outthentic-DSL';

abstract       'Language to verify text output';

all_from       'lib/Outthentic/DSL.pm';

# Specific dependencies

requires    'JSON';

license     'perl';

repository  'https://github.com/melezhik/outthentic-dsl';

WriteAll;


