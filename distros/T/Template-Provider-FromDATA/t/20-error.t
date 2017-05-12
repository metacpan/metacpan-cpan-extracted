use Test::More tests => 6;

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
    my $output;
    $template->process( \'ref', {}, \$output );
    like( $template->error, qr/not found/ );
}

{
    my $output;
    $template->process( 'testDNE', {}, \$output );
    like( $template->error, qr/not found/ );
}

__DATA__

__test__
template data
