use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Name of this distribution
name            'Samba-LDAP';

# Get most of the details from the primary module
# (The filename argument below is optional if it is placed
# consistently with the "name" above.)
all_from        'lib/Samba/LDAP.pm';

# Minimum version of Perl needed, as returned 
# by Perl::MinimumVersion 0.11
perl_version    '5.006';

# In case license is missed
license         'gpl';

# What we need to Samba::LDAP to work
requires        'Readonly'              => '1.03';
requires        'Regexp::DefaultFlags'  => '0.01';
requires        'Class::Base'           => '0.03';
requires        'Config::Tiny'          => '2.05';
requires        'Net::LDAP'             => '0.33';
requires        'Crypt::SmbHash'        => '0.12';
requires        'Unicode::MapUTF8'      => '1.11';
requires        'Digest::MD5'           => '2.36';
requires        'Digest::SHA1'          => '2.11';
requires        'MIME::Base64'          => '3.07';
requires        'List::MoreUtils'       => '0.19';
requires		'UNIVERSAL::require'	=> '0.10';
requires		'File::Path'			=>	  '0';

# In order to build Samba::LDAP, we need
build_requires  'Test::More'         => '0.62';
build_requires  'Test::Distribution' => '1.23';

# Install our scripts
#install_script glob('scripts/*');
    
# Auto-install all dependencies from CPAN
auto_install;

# GPG Sign Distribution
sign;

# Generate the Makefile
WriteAll;
