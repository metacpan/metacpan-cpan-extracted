use Test::More tests => 2;

use Template::Plugin::EnvHash;

my $object = Template::Plugin::EnvHash->new();
isa_ok ($object, 'Template::Plugin::EnvHash');

# Does it follow the template Plugin heirarchy?
isa_ok ($object, 'Template::Plugin');
