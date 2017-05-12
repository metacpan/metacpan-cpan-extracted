#!/usr/bin/perl

use strict ;
use warnings ;
use DBI ;

=head1 dbitest
This is a short test script to run after creating the pg_BulkCopy test database and tables. The object is to confirm that you can insert and delete from the tables through dbi. It doesn't do anything that is otherwise useful. 

=cut

	my $dbistr = 'DBI:Pg:dbname=pg_bulkcopy_test;host=127.0.0.1' ; # replace with the string you need
	my $dbiuser = '' ; # if you configure hba_conf to allow trust locally this is superfluous
	my $dbipass = '' ; # if you configure hba_conf to allow trust locally this is superfluous
	my $conn = DBI->connect( $dbistr, $dbiuser, $dbipass ) or die "Error $DBI::err [$DBI::errstr]" ;
	
	my $insert = qq %
	INSERT INTO testing( flavor, keyseq, somebgnt, sumsmlnt, ancient, whn, threekar, ntnnl, bgtxt )
    VALUES ('Tasty', 1, 2892343204823, 23, '05/07/1887', '14:00', 'ABC', 'This must have a value', 
            E'This is meant for a long string with escaped characters \\nThat was another line') ,
    ('Yummy', 2, 034932545, 192, '1906/07/05', '11:07', 'def', 'This has a value', E'Too Long!') ; % ;
     
            
	my $DBH = $conn->prepare( $insert ) ;
	$DBH->execute ;  
	if ( $DBH->err ) { die $DBH->errstr } ; 
	$DBH = $conn->prepare( 'SELECT * FROM testing;');
	$DBH->execute or die $DBH->errstr  ;
	my @row1 = $DBH->fetchrow_array or die $DBH->errstr  ;
	my @row2 = $DBH->fetchrow_array ;
	print "\n*\n*\nRetrieved These Rows (I just inserted 2 rows): \n@row1\n@row2\n*\n*\n" ;
	
	$DBH = $conn->prepare( 'SELECT count(*) FROM testing;');
	$DBH->execute or die $DBH->errstr  ;
	@row1 = $DBH->fetchrow_array ;
	if ( $row1[0] == 2 ) { print "Two records have been inserted to database.\n" } ;
	
	$DBH = $conn->prepare( 'TRUNCATE testing;');
	$DBH->execute or die $DBH->errstr  ;
	
	$DBH = $conn->prepare( 'SELECT count(*) FROM testing;');
	$DBH->execute or die $DBH->errstr  ;
	@row1 = $DBH->fetchrow_array ;
	if ( $row1[0] == 0 ) { print "Success, all rows are deleted and you can begin testing.\n" } ;
