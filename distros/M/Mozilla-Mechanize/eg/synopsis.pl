#!/usr/bin/perl
# Code from the SYNOPSIS

use strict;
use warnings;

use Cwd 'getcwd';

use lib '../lib';
use Mozilla::Mechanize;

my $moz = Mozilla::Mechanize->new(visible=> 0);

my $cwd = getcwd();
$moz->get("file://$cwd/index.html");

print "got uri=", $moz->uri,  ", content=\n", $moz->content, $/;

$moz->follow_link( text => 'go away' );

print "followed link, uri=", $moz->uri,  ", content=\n", $moz->content, $/;

#$moz->form_name( 'myform' );
#$moz->set_fields(
#    username => 'yourname',
#    password => 'dummy'
#);
#$moz->click( 'login' );

$moz->submit_form(
    form_name => 'myform',
    fields    => {
        username => 'yourname',
        password => 'dummy',
    },
    button    => 'login',
);
