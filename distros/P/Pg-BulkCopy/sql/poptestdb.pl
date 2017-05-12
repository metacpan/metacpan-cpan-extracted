#!/usr/bin/perl

=head1 Populate Test Database

This script randomly generates data and inserts it into spaghetti:marinara. It is useful when developing tests, the author left it here in case it was necessary to develop more tests in the future. Please ignore it. 

=cut


use strict ;
use warnings ;
# use Moose;
use feature ":5.10" ;
use Data::Random qw(:all);
use DBI ;


	my $dbistr = 'DBI:Pg:dbname=pg_bulkcopy_test;host=127.0.0.1' ; # replace with the string you need
	my $dbiuser = '' ; # if you configure hba_conf to allow trust locally this is superfluous
	my $dbipass = '' ; # if you configure hba_conf to allow trust locally this is superfluous
	my $conn = DBI->connect( $dbistr, $dbiuser, $dbipass ) or die "Error $DBI::err [$DBI::errstr]" ;
	

my $maxrows = 157 ;
my $counter = 0 ;
while ( $counter < $maxrows ) {
	my ( $flavor ) = rand_words( size => 1 ) ;
	$flavor =~ tr/\'//d ;
	my $keyseq = $counter++ ;
	my $somebgnt =  int(rand(9999999999)) ;
	my $sumsmlnt = int(rand(255)) ;
	my $ancient = rand_date( min => '1801-01-01' , max => 'now') ;
	my $whn = rand_time() ;
	my ($a, $b, $c) = rand_chars( set => 'upperalpha' , min=> 3, max => 3 );
	my ( $ntnnl ) = rand_words( size => 1 ) ;
	$ntnnl =~ tr/\'//d ;
	my $zbt = int(rand(25)) ;
	my @bgtxt = rand_words( size => $zbt ) ;
	for ( @bgtxt ) { $_ =~ s/\'/\\'/g }
	
	my $insert = qq %
	INSERT INTO testing( flavor, keyseq, somebgnt, sumsmlnt, ancient, whn, threekar , ntnnl, bgtxt )
    VALUES ( '$flavor', '$keyseq', $somebgnt, $sumsmlnt, '$ancient', '$whn', '$a$b$c', '$ntnnl', E'@bgtxt' ) ; % ;
    
    
	say "$counter -- $flavor === @bgtxt" ;
            
	my $DBH = $conn->prepare( $insert ) ;
	$DBH->execute ;  
	if ( $DBH->err ) { die $DBH->errstr } ; 
	} ;

#	$DBH = $conn->prepare( 'SELECT * FROM marinara;');
#	$DBH->execute or die $DBH->errstr  ;
#	my @row1 = $DBH->fetchrow_array or die $DBH->errstr  ;
#	my @row2 = $DBH->fetchrow_array ;
#	print "\n*\n*\nRetrieved These Rows (I just inserted 2 rows): \n@row1\n@row2\n*\n*\n" ;
#	
#	$DBH = $conn->prepare( 'SELECT count(*) FROM marinara;');
#	$DBH->execute or die $DBH->errstr  ;
#	@row1 = $DBH->fetchrow_array ;
#	if ( $row1[0] == 2 ) { print "Two records have been inserted to database.\n" } ;
#	
#	$DBH = $conn->prepare( 'TRUNCATE marinara;');
#	$DBH->execute or die $DBH->errstr  ;
#	
#	$DBH = $conn->prepare( 'SELECT count(*) FROM marinara;');
#	$DBH->execute or die $DBH->errstr  ;
#	@row1 = $DBH->fetchrow_array ;
#	if ( $row1[0] == 0 ) { print "Success, all rows are deleted and you can begin testing.\n" } ;




