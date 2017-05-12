package RDBAL;

use RDBAL::Config;

use vars qw( %Layer );

BEGIN {
    # DBI is a special case
    if (eval 'require DBI;') {
	eval 'use DBI;';
	eval 'use RDBAL::Layer::DBI;';
	map {
	    $Layer{"dbi:$_"} = 1;
	} DBI->available_drivers;
    }
    map {
	if ($_ !~ /^dbi:/) {
#	    print STDERR 'requiring '. $RDBAL::Config::middle_module{$_} .';'."\n";
	    if (eval 'require '. $RDBAL::Config::middle_module{$_} .';') {
		eval 'use '. $RDBAL::Config::middle_module{$_} .';';
#		print STDERR 'using RDBAL::Layer::'. $_ . ';'."\n";
		eval 'use RDBAL::Layer::'. $_ . ';';
		$Layer{$_} = 1;
	    }
	}
    } @RDBAL::Config::search_order;
    if (!defined(%Layer)) {
	die "Unable to find a RDBAL database module\n";
    }
}

sub Connect {
    my($username) = shift;
    my($password) = shift;
    my($server) = shift;
    my($preferred_layer) = shift;
    my($database) = shift;	# Optional, required for mSQL
    my($connection);
    my($driver);

    map {
	if (!defined($preferred_layer) && defined($Layer{$_})) {
	    $preferred_layer = $_;
	}
    } @RDBAL::Config::search_order;
    if (defined($preferred_layer) &&
	defined($Layer{$preferred_layer})) {
	if ($preferred_layer eq 'SybaseDBlib') {
	    $connection =
		new RDBAL::Layer::SybaseDBlib($username,$password,$server);
	} elsif ($preferred_layer eq 'ApacheSybaseDBlib') {
	    $connection =
		new RDBAL::Layer::ApacheSybaseDBlib($username,$password,$server);
	} elsif ($preferred_layer =~ /^Pg/) {
	    $connection =
		new RDBAL::Layer::Pg($username,$password,$server,$database);
	} elsif ($preferred_layer eq 'ODBC') {
	    $connection =
		new RDBAL::Layer::ODBC($username,$password,$server);
	} elsif ($preferred_layer =~ /^dbi:/) {
	    ($driver) = $preferred_layer =~ /^dbi:(.*)/;
	    $connection =
		new RDBAL::Layer::DBI($username,$password,$server,$driver,$database);
	}
    } else {
	if ($Layer{'ApacheSybaseDBlib'}) {
	    $connection =
		new RDBAL::Layer::ApacheSybaseDBlib($username,$password,$server);
	} elsif ($Layer{'SybaseDBlib'}) {
	    $connection =
		new RDBAL::Layer::SybaseDBlib($username,$password,$server);
	} elsif ($preferred_layer =~ /^Pg/) {
	    $connection =
		new RDBAL::Layer::Pg($username,$password,$server,$database);
	} elsif ($Layer{'ODBC'}) {
	    $connection =
		new RDBAL::Layer::ODBC($username,$password,$server);
	} else {
	    map {
		if (/^dbi:/ && $Layer{$_}) {
		    if (!defined($driver)) {
			($driver) = /^dbi:(.*)/;
		    }
		}
	    } @RDBAL::Config::search_order;
	    $connection =
		new RDBAL::Layer::DBI($username,$password,$server,$driver,$database);
	}
    }
    return $connection;
}

1;
__END__

=head1 NAME

RDBAL - Relational DataBase Abstraction Layer class (ReDBALl)

=head1 SYNOPSIS

     use RDBAL;
     
     $connection = RDBAL::Connect('username', 'password', 'server');

     $connection->Query("SQL query"); #	Execute an SQL select and return the results in an array

     $connection->Sql("SQL command(s)"); #	Execute an arbitrary SQL command

     $connection->PrintTable(); #	print the results of the most recent select

     $connection->PrintTables(); #	print the results of one or more selects

     $connection->ColumnNames(); #	get column names for results table

     $connection->ColumnTypes(); #	get column data types for results table

     $connection->ColumnLengths(); #	get column lengths for results table

=head1 DESCRIPTION

RDBAL is a perl module to work with a SQL Relational database.  A middle layer
driver may be written for any database connection layer.  It is also possible
to write middle layer drivers which would parse SQL statements and implement
them in some arbitrary fashion.

Currently available are: Pg (PostgreSQL), Apache::Sybase::DBlib, Sybase::DBlib, ODBC middle
layer drivers, and dbi:Sybase.

The presence of a given middle layer driver may be checked by checking to see if: $RDBAL::Layer{'Pg'}, $RDBAL::Layer{'ApacheSybaseDBlib'}, $RDBAL::Layer{'SybaseDBlib'}, $RDBAL::Layer{'ODBC'}, or $RDBAL::Layer{'dbi:Sybase'} is defined.

=head1 FUNCTIONS

=head2 $connection = RDBAL::Connect('username', 'password', 'server', ['preferred_layer']);

Create/get a connection to a database (server).  

Username and password are mandatory for database servers which require logins.
For Win32::ODBC, server is the name of an existing DSN.

Possible values for preferred_layer are (in the order of default preference):

=over 4

=item Pg

=item ApacheSybaseDBlib

=item SybaseDBlib

=item ODBC

=item dbi:Sybase

=item dbi:Oracle

=back

=head2 $connection->Query("SQL query")

Execute an SQL select and return the results in an array.

=head2 $connection->Sql("SQL command(s)")

execute an arbitrary SQL command.

=head2 $connection->RowCount()

Fetch the number of rows that were affected by the previous SQL command.

=head2 @row = $connection->NextRow();

fetch the next row from a result set

=head2 $bool_regular_row = $connection->Regular_Row();

see if the row just fetched is a regular data set row

=head2 $bool_no_more_result_sets = $connection->More_Results();

see if there are any more result sets

=head2 $connection->PrintTable()

Print the results of the most recent select.

=head2 $connection->PrintTables()

Print the results of one or more selects.

=head2 $connection->ColumnNames()

Get column names for results table.

=head2 $connection->ColumnTypes()

Get column data types for results table.

=head2 $connection->ColumnLengths()

Get column lengths for results table.

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

A small script which yields the problem will probably be of help.  If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 AUTHOR INFORMATION

Brian H. Dunford-Shore   brian@ibc.wustl.edu

Copyright 1998, Washington University School of Medicine,
Institute for Biomedical Computing.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

Address bug reports and comments to:
www@ibc.wustl.edu

=head1 TODO

These are features that would be nice to have and might even happen someday (especially if YOU write it).

=over 4

=item Other types of database servers:

(mSQL, mySQL, etc.).

=back

=head1 SEE ALSO

B<Sybase::DBlib> -- http://www.ibc.wustl.edu/perl5/other/sybperl.html

B<Win32::odbc> -- http://www.ibc.wustl.edu/perl5/other/Win32/odbc.html

=head1 CREDITS

Thanks very much to:

B<David J. States> (states@ibc.wustl.edu)

and

B<Fyodor Krasnov> (fyodor@bws.aha.ru)

     for suggestions and bug fixes.

=head1 BUGS

You really mean 'extra' features ;).  None known.

=head1 COPYRIGHT

Copyright (c) 1997, 1998, 1999 Washington University, St. Louis,
Missouri. All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
