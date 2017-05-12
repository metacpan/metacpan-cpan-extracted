# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Net-Amazon-IAM';
all_from        'lib/Net/Amazon/IAM.pm';

# Specific dependencies
requires        'URI'                    => 0;
requires        'Carp'                   => 0;
requires        'JSON'                   => 0;
requires        'URI::Encode'            => 0;
requires        'XML::Simple'            => 0;
requires        'POSIX'                  => 0;
requires        'LWP::UserAgent'         => 0;
requires        'LWP::Protocol::https'   => 0;
requires        'Data::Dumper'           => 0;
requires        'Params::Validate'       => 0;
requires        'HTTP::Request::Common'  => 0;
requires        'AWS::Signature4'        => 0;
requires        'Moose'                  => 0;

no_index;

repository 'https://github.com/tsiganenok/net-amazon-iam';

auto_install;
WriteAll;
