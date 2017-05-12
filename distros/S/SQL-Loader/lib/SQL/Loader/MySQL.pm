package SQL::Loader::MySQL;

use strict;
use warnings;

use base qw( SQL::Loader );

our $VERSION = '0.01';

=head1 NAME

SQL::Loader::MySQL

=head1 SYNOPSIS

=head3 In Perl script

 use SQL::Loader::MySQL;
 SQL::Loader::MySQL->new(
   url => $schema_url,
   dbname	=> $dbname,
   dbuser	=> $dbuser,
   dbpass	=> $dbpass,
   print_http_headers => <boolean>,
   quiet	=> <boolean>
 )->run;

The database specified by $dbname must exist.

=head3 In URL specified

 <h2>$table_name</h2>

 ...

 <h3>Purpose</h3>

 ...

 <table>
   <tr>
     <td>$order</td>
     <td>$column_name</td>
     <td>$column_type</td>
     <td>$additional_info</td>
   </tr>
 </table>

For further details see README file.

=head1 DESCRIPTION

Screen scrape a database schema from a twiki ( or compatible ) web page and create it in a MySQL database.

=head1 INPUT PARAMETERS

 $schema_url - the url to scrape db schema from - required
 $dbname - name of database to use - required 
 $dbuser - database username - required
 $dbpass - database password - required 
 $print_http_headers ( boolean ) - Test $url server response only by requesting headers ( does not rebuild db )
 $quiet ( boolean ) - do not print any informational messages

=head1 SEE ALSO

L<SQL::Loader>

=head1 INHERITANCE

L<SQL::Loader>

=head1 METHODS

=cut

=head2 create

create a mysql table

=cut
sub create_table {
	my $self = shift;
	my ( $name, $cols ) = @_;

	my $dbname = $self->dbname();
	my $dbuser = $self->dbuser();
	my $dbpass = $self->dbpass();
	my $quiet = $self->quiet();
	my $dbh	= $self->dbh();

	my $rcount = 0;
	my $notype = 0;
	my $q;

	foreach my $rr (@{$cols}) {
		if ($rr->[2] =~ /^\s*$/ || $rr->[2] =~ /&nbsp\;/) { # cols with no type set yet are skipped -
																												# considered 'non-production' tables
			$notype = 1;
			next;
		}
		if ( $rcount == 0 ) {
			$q = "DROP TABLE IF EXISTS ".$name->[0].";";
			$dbh->do( $q ) || die $dbh->errstr;
 			$q = "CREATE TABLE ".$name->[0]." (";
		}
 		$q .= $rr->[1] . " " . uc( $rr->[2] );
		# set primary keys via 2 possible flags indicating to do so:
		if ( $rr->[1] eq 'id' ) {
			# 1: a field name 'id' is automatically made PK A_I
			$q .= " PRIMARY KEY AUTO_INCREMENT";
		}
		elsif ( $rr->[3] =~ /PK/ ) {
			# 2: if description of a field contains the case sensitive letters 'PK' it will be made a primary key
			$q .= " PRIMARY KEY";
		}
		$q .= ", " unless $rcount == scalar(@{$cols} - 1);
		$rcount++;
	}

	$q .= ");";

	unless ($notype) {
		print "RUNNING QUERY: $q\n" unless $quiet;
		$dbh->do( $q ) || die $dbh->errstr;
		unless ( $quiet ) {
			print "\n";
			print '*' x 100, "\n\n";
			print "OK", "\n\n";
			print '*' x 100, "\n\n";
		}
	}

	return 1;
}

=head2 connect_string

return dbh connect string.

=cut
sub connect_string {
	my $self = shift;
	my $dbname = $self->dbname();
	my $dbuser = $self->dbuser();
	my $dbpass = $self->dbpass();
	return ("dbi:mysql:$dbname","$dbuser","$dbpass");
}

1;

__END__

=head1 AUTHOR

Ben Hare for www.strategicdata.com.au

benhare@gmail.com

=head1 COPYRIGHT

(c) Copyright Strategic Data Pty. Ltd.

This module is free software. You can redistribute it or modify it under the same terms as Perl itself.

=cut

