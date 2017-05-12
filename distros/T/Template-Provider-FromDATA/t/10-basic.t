use Test::More tests => 8;

use strict;
use warnings;

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

my $provider = Template::Provider::FromDATA->new;
isa_ok( $provider, 'Template::Provider::FromDATA' );

my $template = Template->new( {
    LOAD_TEMPLATES => [ $provider ]
} );
isa_ok( $template, 'Template' );

{
    my $output;
    $template->process( 'foo', {}, \$output );
    is( $output, "bar\n\n" );
}

{
    my $output;
    $template->process( 'baz', { qux => 'bar' }, \$output );
    is( $output, "bar\n\n" );
}

$template = Template->new( {
    LOAD_TEMPLATES => [ $provider ],
    WRAPPER        => 'wrapper'
} );
isa_ok( $template, 'Template' );

{
    my $output;
    $template->process( 'foo', {}, \$output );
    is( $output, "before\nbar\n\nafter\n" );
}

__DATA__

__foo__
bar

__baz__
[% qux %]

__wrapper__
before
[% content -%]
after
