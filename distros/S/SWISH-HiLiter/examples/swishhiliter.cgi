#!/usr/bin/perl -w 
#
# a CRUDE example for SWISH::HiLiter -- don't really use this
# takes two CGI parameters: q and index
   
use CGI qw(:all);
$| = 1;
print header();

print start_html();

my $index = param( 'index' ) || 'index.swish-e';

my $query = param( 'q' );

require SWISH::API;
my $swish = SWISH::API->new( $index );

$swish->RankScheme( 1 );

require SWISH::HiLiter;

my $hiliter = SWISH::HiLiter->new( swish=>$swish, query=>$query );

print "looking for '$query'\n";

my $results = $swish->Query( $query );

print "Sorry, no hits" unless $results->Hits;
      
while ( my $result = $results->NextResult )
{
	
	my $path 	= $result->Property( "swishdocpath" );
	my $title 	= $hiliter->light( $result->Property( "swishtitle" ) );
	my $snip 	= $hiliter->light( $hiliter->snip( $result->Property( "swishdescription" ) ) );
	my $rank 	= $result->Property( "swishrank" );
	my $file	= $result->Property( "swishreccount" );
        
	print "<p>$file. <a href='$path'>$title</a><br/>$snip<br />$rank</p>";
	
}


print end_html();

