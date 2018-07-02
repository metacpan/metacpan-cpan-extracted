#!/usr/bin/perl -w
use CGI::Carp qw(fatalsToBrowser);
use lib qw(./lib);
use MySQL::Admin;

# use strict;
my $m_oCgi = MySQL::Admin->new();
print $m_oCgi->header;
print "inc" . $m_oCgi->param('include');
if ( $m_oCgi->param('include') ) {
    $m_oCgi->include();
    print "foo";
    print $m_oCgi->a( { href => "$ENV{SCRIPT_NAME}" }, 'next' );
    $m_oCgi->clearSession();
} else {
    my %vars = (
        user   => 'guest',
        action => 'main',
        file   => "./content.pl",
        sub    => 'main'
    );
    my $qstring = $m_oCgi->createSession( \%vars );
    print qq(Action wurde erzeugt.);
    print $m_oCgi->br(), $m_oCgi->a( { href => "$ENV{SCRIPT_NAME}?include=$qstring" }, 'next' );
} ## end else [ if ( $m_oCgi->param('include'...))]
use showsource;
&showSource($0);
