#!/usr/bin/perl -w
use CGI::Carp qw(fatalsToBrowser);
use lib qw(lib);
use MySQL::Admin qw(:all);
use strict;
init();
print header;
if( param('include') ) {
    include().br();
    print a( { href => "$ENV{SCRIPT_NAME}" }, 'next' );
    clearSession();
} else {
    my %vars = (
        user   => 'guest',
        action => 'main',
        file   => "./content.pl",
        sub    => 'main'
    );
    my $qstring = createSession( \%vars );
    print qq(Action wurde erzeugt.);
    print br(),
        a( { href => "$ENV{SCRIPT_NAME}?include=$qstring" },
        'next' );
}
use showsource;
&showSource('./include-fo.pl');
