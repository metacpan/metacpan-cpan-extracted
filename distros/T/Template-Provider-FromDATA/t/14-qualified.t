use Test::More tests => 5;

use strict;
use warnings;

use lib qw( t/lib );

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

my $provider = Template::Provider::FromDATA->new( {
    CLASSES => 'My::Templates'
} );
isa_ok( $provider, 'Template::Provider::FromDATA' );

my $template = Template->new( {
    LOAD_TEMPLATES => [ $provider ],
} );
isa_ok( $template, 'Template' );

{
    my $output;
    $template->process( 'My-Templates/test', {}, \$output );
    is( $output, "template data\n" );
}
