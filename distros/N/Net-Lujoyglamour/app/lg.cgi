#!/usr/bin/perl

use lib qw( /home/jmerelo/proyectos/CPAN/Net-Lujoyglamour/lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Net::Lujoyglamour::WebApp;

my $base_dir = "/usr/lib/cgi-bin/lg/";
my $dsn = "dbi:SQLite:dbname=$base_dir/lg.sqlite3";
my $templates_dir = $base_dir;

my $app = new Net::Lujoyglamour::WebApp 
    PARAMS => { dsn => $dsn,
		domain => 'lugl.info' },
    TMPL_PATH => $templates_dir;

$app->run();

