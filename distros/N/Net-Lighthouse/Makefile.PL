use inc::Module::Install;

name     'Net-Lighthouse';
all_from 'lib/Net/Lighthouse.pm';
author   'sunnavy <sunnavy@bestpractical.com>';
license  'perl';
repository 'git://github.com/bestpractical/net-lighthouse.git';

requires 'Any::Moose';
requires 'Params::Validate';
requires 'XML::TreePP';
requires 'LWP';
requires 'MIME::Base64';
requires 'DateTime';
requires 'URI::Escape';

if ( can_cc() ) {
    requires 'YAML::Syck';
}
else {
    requires 'YAML' unless can_use( 'YAML::Syck' );
}

if ( can_use('Mouse') && !can_use( 'Mouse', 0.28 ) || !can_use('Moose') ) {
    requires Mouse => 0.28;
}

test_requires 'Test::More';
test_requires 'Test::Mock::LWP';

auto_install;

WriteAll;

