use Test::More tests => 5;

use strict;
use warnings;

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
    $template->process( 'test', {}, \$output );
    is( $output, "template data\n" );
}

package My::Templates;

1;

__DATA__

__test__
template data
