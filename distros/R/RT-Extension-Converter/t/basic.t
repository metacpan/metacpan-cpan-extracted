use RT::Extension::Converter;
use Test::More tests => 7;

use lib 't/lib';

my $rt1 = RT::Extension::Converter->new( type => 'RT1' );
isa_ok($rt1,"RT::Extension::Converter::RT1");
isa_ok($rt1->config,"RT::Extension::Converter::RT1::Config");

# check some defaults
# check that we can blank out the password
is($rt1->config->dbuser,'root');
is($rt1->config->dbpassword,'password');
$rt1->config->dbpassword('');
is($rt1->config->dbpassword,'');


my $rt3 = RT::Extension::Converter->new( type => 'RT3' );
isa_ok($rt1,"RT::Extension::Converter::RT1");
isa_ok($rt1->config,"RT::Extension::Converter::RT1::Config");
