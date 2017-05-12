use strict;
use lib qw(lib t/lib);
use Test::More 'no_plan';
use Railsish::FormHelpers;

use Class::Implant;
implant "Railsish::FormHelpers";


can_ok("Railsish::FormHelpers", qw(form_tag submit_tag));

is( form_tag("/posts"), '<form action="/posts"></form>',
            'form_tag("/posts")');

is( form_tag("/posts", method => "put"), '<form action="/posts" method="put"></form>', 
            'form_tag("/posts", method => "put")');


#my $f = form_tag('/posts', method => 'put'), { submit_tag() };

#is( $f, '<form action="/posts" method="put"><input type="submit" value="submit"></form>',
#            'form_tag("/posts", method => "put"), { submit_tag() }');


is( submit_tag(), '<input type="submit" value="submit" />',
            'submit_tag()');


