use 5.020;
package Pg::BulkLoad;
$Pg::BulkLoad::VERSION = '2.031';
use feature qw/signatures postderef/;
no warnings qw/experimental uninitialized/;
use Try::Tiny;
use Path::Tiny;
use Carp;
use Data::Printer;
use Data::Dumper;

# ABSTRACT: Bulk Load for Postgres with ability to skip bad records.

sub new ( $Class, %args ) {
	for my $required ( qw/ pg errorfile/ ) {	
		unless ( $args{$required }) {			
			croak "missing mandatory argument $required";
		}
	}
	my $I = \%args;
	$I->{errcount} = 0;
	open( $I->{errors}, '>', $args{errorfile});
	bless $I;
	return $I;
}

sub _error ( $I, $msg, $row ) {
	$I->{errcount}++;
	my $ERR = $I->{errors};
	say $ERR $msg;
	say $ERR $row;
	if ( defined $I->{errorlimit}) {
		if ( $I->{errcount} >= $I->{errorlimit}) {
			say $ERR  "Exceeded Error limit with $I->{errcount} Errors";
			croak "Exceeded Error limit with $I->{errcount} Errors";
		}
	}
}

sub load ( $I, $file, $table, $format ) {
	my $loadedlines = 0;
	my $workfile = "/tmp/pgbulkloadwork.$format";
	my @data = path($file)->lines;
	path($workfile)->spew(@data);

	my $loopmax = scalar(@data);
	my $loopcnt = 0;
	my $loadq = undef;
	if ( $format eq 'csv') {
		$loadq = "copy $table from '$workfile' with ( format 'csv' )";
	} else {
		$loadq = "copy $table from '$workfile' with ( format 'text', null '' )";		
	}
	LOADLOOP: while ( $loopcnt < $loopmax ) {
		$loopcnt++;
		try {
			$I->{pg}->do( $loadq );
			$loopmax = 0; # break free of loop on success.
		} catch { 
			my $err = $I->{pg}->errstr;
			$err =~ m/\, line (\d+)/;
			my $badline = $1 -1 ; # array offset 0
			$I->_error( "Evicting Record from $file : $err", $data[$badline] );
			# remove badline
# uncoverable error trap left in for issue during devel.
			if ( $badline < 1 ) {
				my $diemsg = qq/badline out of range. load error was $err\n/;
				$I->_error( $diemsg );
				die $diemsg;
			}
			splice (@data, $badline, 1); 
			# make new array of goodlines before badline
			my @goodlines = splice (@data, 0, $badline -1  );
			# try to load just goodlines.	
			path($workfile)->spew(@goodlines);
			try { $I->{pg}->do( $loadq ) ; $loadedlines += scalar @goodlines }	
			catch { croak "retry load of good chunk failed can\'t continue\n"
				. $I->{pg}->errstr . "\n" } ;
			# write remaining data and repeat loopNN
			path($workfile)->spew(@data);
		};
 	}
	return $loadedlines + scalar( @data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::BulkLoad - Bulk Load for Postgres with ability to skip bad records.

=head1 VERSION

version 2.031

=head1 Pg::BulkLoad

Load Comma and Tab Delimited files into Postgres, skipping bad records.

=head1 Synopsis

 Shell> split -l 50000 -a 3 -d mydata.csv load
 Shell> myloadscript.pl load*

 === myloadscript.pl ===

 use Pg::BulkCopy;

 my $pgc = Pg::BulkLoad->new(  
 	pg => DBI->connect("dbi:Pg:dbname=$dbname", '', '', {AutoCommit => 0}),
	errorfile => '/tmp/pgbulk.error',
	errorlimit => 500,
 );

 .... # your code to read file names and possibly manipulate files contents prior to load.

 while ( @filelist ) {
     $pgc->load( $file, $_, 'csv' );
 }

=head2 new 

Takes arguments in hash format:

 pg => DBD::Pg database_handle (mandatory),
 errorfile => A file to log errors to (mandatory),
 errorcount => a limit of errors before giving up (optional)

=head2 load ($file, $table, $format )

Attempts to load your data. Takes 3 parameters: 

=over

=item $file

the file you're trying to load.

=item $table

the table to load to.

=item $format

either text or csv

=back

=head2 Reason

The Postgres 'COPY FROM' lacks a mechanism for skipping bad records. Sometimes we need to ingest 'dirty' data and make the best of it.

=head2 Method and Performance

Pg::BulkLoad attempts to load your file via the COPY FROM command if it fails it removes the error for the bad line from its working copy, then attempts to load all of the records previous to the error, and then tries to load the remaining data after the failure. 

If your data is clean the COPY FROM command is pretty fast, however if there are a lot of bad records, for each failure Pg::BuklLoad has to rewrite the input file. If your data has a lot of bad records small batches are recommended, for clean data performance will be better with a larger batch size. To keep this program simpler I've left chunking larger files up to the user. The split program will quickly split larger files, but you can split them in Perl if you prefer. Pg::BulkLoad does hold the entire data file in memory (to improve performance on dirty files) this will create a practical maximum file size.

=head2 Limitation of COPY

Since Pg::Bulkload passes all of the work to copy it is subject to the limitation that the source file must be readable via the file system to the postgres server (usually the postgres user). To avoid permissions problems Pg::Bulkload copies the file to /tmp for loading (leaving the original preserved if it has to evict records). Pg::BulkLoad needs to be run locally to the server, this means that your host for connection will almost always be localhost.

=head2 Other Considerations

The internal error counting is for the life of an instance not per data file. If you have 100 source files an error limit of 500 and there are 1000 errors in your source you will likely get about half the data loaded before this module quits. You should be prepared to deal with the consequences of a partial load.

=head2 History

My first CPAN module was Pg::BulkCopy, because I had this problem. I found something better that was written in C, so I deprecated my original module which needed a rewrite. Sometimes the utility I switched to doesn't want to compile, so I got tired of that, still had my original problem of getting a lot of data from an external source that has a certain amount of errors, and is creative in finding new ways get bad records past my preprocessor. Pg::BulkCopy wanted to be an import/export utility, Pg::BulkLoad only deals with the core issue of getting the good data loaded.

=head1 Testing

To properly test it you'll need to export DB_TESTING to a true value in your environment before running tests. When this variable isn't set the tests mock a database for a few of the simpler tests and skip the rest.

=head1 AUTHOR

John Karr <brainbuz@brainbuz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by John Karr.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
