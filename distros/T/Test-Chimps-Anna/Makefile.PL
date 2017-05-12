use inc::Module::Install;

# Define metadata
name            'Test-Chimps-Anna';
all_from        'lib/Test/Chimps/Anna.pm';

# Specific dependencies
requires('Bot::BasicBot');
requires('Jifty::DBI::Handle');
requires('Test::Chimps::Report');
requires('Test::Chimps::ReportCollection');
requires('YAML::Syck');

build_requires('Test::Dependencies');

auto_install;
WriteAll;
