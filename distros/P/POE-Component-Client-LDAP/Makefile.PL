# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Name of your distribution
name            'POE-Component-Client-LDAP';

# Get most of the details from the primary module
# (The filename argument below is optional if it is placed
# consistently with the "name" above.)
all_from        'lib/POE/Component/Client/LDAP.pm';

requires        'Net::LDAP'	=> '0.31';
requires	'Net::LDAP::ASN'	=> 0;
requires	'Convert::ASN1'	=> 0;
requires	'POE'	=> 0;
requires	'POE::Filter::Stream'	=> 0;
requires	'POE::Session'	=> 0;
requires	'POE::Kernel'	=> 0;
requires	'POE::Wheel::Null'	=> 0;
requires	'POE::Wheel::ReadWrite'	=> 0;
requires	'POE::Wheel::SocketFactory'	=> 0;
requires	'POE::Driver::SysRW'	=> 0;

# Do not index our example modules
no_index        directory           => 'scripts';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
