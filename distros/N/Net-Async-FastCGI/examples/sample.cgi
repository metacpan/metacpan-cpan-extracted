#!/usr/bin/perl
use strict; use warnings;
use CGI;

my $c = new CGI;

if(defined($c->param("foo"))) {
   print $c->header,
         $c->start_html("Thanks for submitting the Foobar Form!"),
         $c->h1("Foobar Form Results"),
         "<hr />",
         "<strong>Foorbar Form Results: ", $c->param('foo'), "<br />",
         "Thanks for submitting!</strong>",
         $c->end_html();
} else {
   print $c->header,
         $c->start_html("It's the Foobar Form!"),
         '<form method="POST">',
         '<input type="text" name="foo" value="bar" /><br />',
         '<input type="submit" value="Submit the Foobar Form!" />',
         '</form>',
         $c->end_html();
}
