use Test::More tests => 9;

use strict;
use warnings;

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

my $provider = Template::Provider::FromDATA->new;
isa_ok( $provider, 'Template::Provider::FromDATA' );

my $template = Template->new( {
    LOAD_TEMPLATES => [ $provider ],
} );
isa_ok( $template, 'Template' );

{
    for( 1..5 ) {
        my $output;
        $template->process( 'foo', {}, \$output );
        is( $output, "bar\n" );
    }
}

__DATA__

__foo__
bar
