# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN
{
    use_ok( 'Template::Plugin::ListMoreUtils' );
    use_ok( 'Template::Plugin::ListMoreUtilsVMethods' );
}

my $object = Template::Plugin::ListMoreUtils->new();
isa_ok ($object, 'Template::Plugin::ListMoreUtils');
