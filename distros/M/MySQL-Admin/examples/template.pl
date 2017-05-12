#!/usr/bin/perl -w
use lib("../lib");
use strict;
my @data = (
            {name => 'Header'},
            {
             name => 'link',
             text => "Website",
             href => "http://lindnerei.de"
            },
            {
             name => 'link',
             text => "Cpan",
             href => "http://search.cpan.org/~lze"
            },
            {name => 'Footer'}
           );
use Template::Quick;
my $temp = new Template::Quick(
                               {
                                path     => "./",
                                template => "template.html",
                                style=>"lze"
                               }
                              );
use CGI qw(header);
print header;
print $temp->initArray(\@data), $/;
use showsource;
&showSource($0);
print "template";
use showsource;
&showSource("./lze/template.html");

