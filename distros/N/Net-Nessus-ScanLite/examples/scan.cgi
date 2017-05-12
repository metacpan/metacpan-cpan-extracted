#!/usr/local/bin/perl -Tw
use strict;
use Net::Nessus::ScanLite;
use HTML::Template;
use Data::Dumper;
use CGI;
use vars qw( );
my $query = new CGI;

$ENV{PATH} = '';
$|=1;
print $query->header;

# Put the template where the cgi can read it.
my $template = "/tmp/results.tmpl"; 
# die_on_bad_params use this unless your getting all tmpl var's
my $t =  HTML::Template->new(filename => $template,die_on_bad_params => 0);

my $user = "nessus";
my $pwd  = "******";

my $nessus = Net::Nessus::ScanLite->new(
		host		=>  "nessus.host.net",
		port		=> 1241,
		ssl		=> 0,  # comment or set to 1 out if using ssl
		);
# Modify the following as seems fit.
$nessus->preferences( { host_expansion => 'none', safe_checks => 'yes', checks_read_timeout => 1 });
$nessus->plugin_set("10150;11111;10398;10859;10397;10114;10201");

my $addr = $ENV{REMOTE_ADDR};

$t->param("REMOTE_ADDR" => $addr);
$t->param("plugin_set",$nessus->plugin_set);
if( $nessus->login($user,$pwd) )
	{
	$nessus->attack($addr);
	$t->param( total_holes => $nessus->total_holes );
        $t->param( total_info => $nessus->total_info );
        $t->param( holes => $nessus->holes2tmpl );
        $t->param( info   => $nessus->info2tmpl);
        $t->param( duration => $nessus->duration . " secs." );
	}
else
	{
	$t->param("error" => $nessus->error );
	}
	
print $t->output;

