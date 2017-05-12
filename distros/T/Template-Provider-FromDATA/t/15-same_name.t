use Test::More tests => 6;

use strict;
use warnings;

use lib 't/lib';

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

my $provider = Template::Provider::FromDATA->new( {
    CLASSES => [ 'My::Templates', 'My::Other::Templates' ]
} );
isa_ok( $provider, 'Template::Provider::FromDATA' );

my $template = Template->new( {
    LOAD_TEMPLATES => [ $provider ],
} );
isa_ok( $template, 'Template' );

{ # non-qualified
    my $output;
    $template->process( 'test', {}, \$output );
    is( $output, "template data\n" );
}

{ # qualified
    my $output;
    $template->process( 'My-Other-Templates/test', {}, \$output );
    is( $output, "other template data\n" );
}
