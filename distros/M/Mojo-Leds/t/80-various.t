BEGIN {
    use Test::More;
}

our $version = '1.1';

package Skel;

our $VERSION = $version;
use Mojo::Base 'Mojo::Leds';


# This package defines a simple webpage which inherits from Mojo::Leds::Page.
# It do nothig else tocall the superclass's route method and returns its result.
package Skel::Page;
use Mojo::Base 'Mojo::Leds::Page';
sub route {
    my $s = shift;
    my $sr = $s->SUPER::route(@_);
    return $sr;
}

# This package defines a class page which inherits from Skel::Page.
# It return a text 'Hello World'.
package ClassPage;
use Mojo::Base 'Skel::Page';   
sub render_html {
    my $c = shift;
    return { text => 'Hello World' };
}

# class Skel with custom response for cust type extension
package Skel::Page::CustResponse;
use Mojo::Base 'Skel::Page';
sub route {
    my $s = shift;
    push @_, { cust => { text => 'Custom extension' } };
    my $sr = $s->SUPER::route(@_);
    return $sr;
}

# a page with custom response for cust type extension
package CustPage;
use Mojo::Base 'Skel::Page::CustResponse';   
sub render_html {
    my $c = shift;
    return { text => 'Hello World' };
}


package main;
use Mojo::Base -strict;
use Test::Mojo;

my $t = Test::Mojo->new('Skel');

my $app = $t->app;
my $r   = $app->routes;

$r->get('/classpage')->to( 'ClassPage', action => 'route' );
$t->get_ok('/classpage')->status_is(200)->content_like(qr/Hello World/i, 'Simple class page');

$r->get('/custresponse' => [ format => 1 ])->to( 'CustPage', action => 'route' );
$t->get_ok('/custresponse')->status_is(200)->content_like(qr/Hello World/i, 'Custom response with no extension');
$t->get_ok('/custresponse.html')->status_is(200)->content_like(qr/Hello World/i, 'Custom response with html extension');
$t->get_ok('/custresponse.cust')->status_is(200)->content_like(qr/Custom extension/i, 'Custom response with cust extension');

done_testing();