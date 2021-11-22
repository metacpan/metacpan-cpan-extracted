package welcome::anotherPage;

use Mojo::Base 'Mojolicious::Controller';

sub route() {
    my $s      = shift;
    my $format = $s->accepts;
    $format = $format->[0] || 'html' if ( ref($format) eq 'ARRAY' );
    for ($format) {
        /^html?/ and $s->render( template => 'welcome/anotherPage' ) and next;
        /^json$/ and $s->render( json     => { anotherPage => 1 } )  and next;
        /^(\w+\.)?js$/ and $s->render( text => 'var a = 1' )         and next;
        $s->render( { text => '', status => 204 } );
    }
}

1;
