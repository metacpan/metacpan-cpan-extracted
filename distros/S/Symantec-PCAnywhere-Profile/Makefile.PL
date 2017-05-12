# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Symantec-PCAnywhere-Profile';
all_from        'lib/Symantec/PCAnywhere/Profile.pm';

# Specific dependencies
requires		'Carp'				=> undef;
requires		'Compress::Zlib'	=> undef;
requires		'Digest::MD5'		=> undef;
requires		'MIME::Base64'		=> undef;
build_requires  'Test::More'        => '0.42';

auto_install;
WriteAll;

