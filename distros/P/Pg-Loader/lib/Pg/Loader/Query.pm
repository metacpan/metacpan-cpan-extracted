
# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Query;

use 5.010000;
use DBI;
use strict;
use warnings;
use Config::Format::Ini;
use Log::Log4perl qw( :easy );
use Pg::Loader::Columns;
use Pg::Loader::Misc;
use Data::Dumper;
use Text::CSV;
use base 'Exporter';

our $VERSION = '0.11';

our @EXPORT = qw(
	connect_db	  get_columns_names   primary_keys
	disable_indexes   enable_indexes      vacuum_analyze 
	update_string     pgoptions           create_tmp_table
	_truncate         _disable_triggers   _disable_indexes

);
sub _truncate {
        my ($dh, $table, $dry) = @_  ;
        INFO("\tTruncating $table")                ;
        $dh->do("truncate $table")   unless $dry   ;
}
sub _disable_triggers {
        my ($dh, $table, $dry) = @_  ;
        DEBUG( "\tDisabling triggers")             ;
        $dh->do( <<"")                unless $dry  ;
        ALTER TABLE $table DISABLE TRIGGER ALL

}
sub _disable_indexes {
        my ($dh, $table, $dry) = @_  ;
        disable_indexes( $dh, $table ) unless $dry
}

sub  create_tmp_table {
        my ($dh, $like) = @_ ;
        my  $sql = <<"";
         DROP TABLE IF EXISTS d;
         CREATE TEMP TABLE d (like $like including indexes)

        $dh->do( $sql )  or LOGDIE( $dh->errstr );
        #TODO delete next line
        DEBUG( 'created tmp table d' );
}


sub pgoptions {
        my ($dh, $s) = @_ ;
        for ( qw( datestyle client_encoding
                  lc_messages lc_numeric lc_monetary lc_time)) {
                next unless $s->{$_};
                $dh->do( "set $_ to ". $dh->quote($s->{$_} ));
        }
}

sub connect_db {
        my $pgsql   =  shift                                       ;
        my ($port, $host, $base) = @{$pgsql}{'port','host','base'} ;
        $port    //=  5432                                         ;
        $host    //=  'localhost'                                  ;
        $base    ||   usage()                                      ;
        my ($user, $pass) = @{$pgsql}{'user','pass'}               ;
        my $dsn    =  "dbi:Pg:dbname=$base;host=$host;port=$port"  ;
	$dsn .=';options=--client_min_messages=WARNING'            ;
        $ENV{ PGSYSCONFDIR } //= $pgsql->{pgsysconfdir} //''       ;
	if ( -f "$ENV{ PGSYSCONFDIR }/pg_service.conf") {
		DEBUG( "Using PGSYSCONFIGDIR ")            ;	
                $dsn = "dbi:Pg:service=$pgsql->{service}"  ;
		$user = $pass = ''                         ;
	}
        my $att  = { AutoCommit => 0 , pg_server_prepare => 1,
                     PrintError => 0 , Profile           => 0,
		   };
        DBI->connect( $dsn, $user//getlogin,$pass,$att) or die "$DBI::errstr\n";
}

sub vacuum_analyze {
        my ($dh, $table, $dry) = @_  ;
        local $dh->{ AutoCommit } = 1;
        local $dh->{ RaiseError } = 0;
        local $dh->{ PrintError } = 0;
	my ($msg, $rv)  = ("\tVacuum analyze $table", 1);
	unless ($dry) { 
		$rv  = $dh->do("VACUUM ANALYZE $table") ; 
	}
	INFO $rv//'' ? $msg : $msg . '.....FAILED' ;
	$rv;
}

sub disable_indexes {
        my ( $dh, $schema, $table) = ($_[0], schema_name( $_[1]  ));
	(my $st = $dh->prepare(<<""))->execute() ;
		SELECT  indexrelid::regclass::text  AS name, 
			indisprimary                AS pk,
		        pg_get_indexdef(indexrelid) AS def
		FROM  pg_index  I
		 join pg_class  C    ON ( C.oid = I.indrelid )
		 join pg_namespace N ON ( N.oid = C.relnamespace )
		WHERE relname      = @{[ $dh->quote($table) ]}
		 and  nspname      = @{[ $dh->quote($schema) ]}


	my  @definitions;
	#while ( my $idx = $st->fetchrow_hashref  ) {
	while ( my $idx = $st->fetchrow_arrayref  ) {
		my  $sql =  $idx->[1]
                       ? "ALTER table $table drop constraint ".$idx->[0]
                       : "DROP INDEX ".$idx->[0];
		DEBUG( "\t\t$sql" )                                         ;
		$dh->do( $sql )  and   INFO( "\t\tDisabled ".$idx->[0])   ; 
	 	push @definitions, 
                   { name =>$idx->[0],def =>$idx->[2], pk=>$idx->[1] };
	}
	\@definitions;
}
sub enable_indexes {
        my ( $dh, $schema, $table) = ($_[0], schema_name($_[1]));
	my @defs = @{$_[2]};
	for (@defs) { 
		my ($col) = $_->{def} =~ / (\( [,\w\s]+? \)) $/xo         ;
		$col    //= '';
		my $sql = $_->{pk} ? "ALTER TABLE $table add PRIMARY KEY $col"
				   : $_->{def};
		DEBUG( "\t\t$sql" )                                       ;
		$dh->do( $sql) and INFO( "\t\tCreated index $_->{name}" ) ;
	}
}

sub schema_name  {
	my ($canonical, $search) = @_ ;
	my ($schema, $table) = split /\./, $canonical, 2 ;
	unless ($table ) {
		$table  = $schema;
		$schema = $search || 'public'; 
        }
	( $schema, $table );
}


sub primary_keys  {
        # Input: name of table
        # Output: names of its columns that form primary key
        my ( $dh, $schema, $table) = ($_[0], schema_name( $_[1]  ));
	my $h = $dh->selectall_arrayref(<<"",{}, $schema, $table );
        SELECT column_name
        FROM information_schema.constraint_table_usage T
         join information_schema.constraint_column_usage using (constraint_name)        WHERE T.table_schema = ?
          and T.table_name = ?

	return unless $h;
	[ map  { $_->[0] }   @$h  ] ;
}


sub get_columns_names {
        # return ordered list of culumn names
        my ( $dh, $schema, $table) = ($_[0], schema_name( $_[1]  ));
        (my $st =  $dh->prepare(<<""))->execute( $table, $schema) ;
                select column_name, ordinal_position
                from information_schema.columns
                where table_name = ?
                and table_schema = ?
                order by 2;

        my $h = $st->fetchall_arrayref;
        map { ${$_}[0] }   @$h ;
}
sub _where_clause {
        my ($pk , $target, $from) = @_ ;
        my  $sql =  'WHERE ' ;
        $sql .= "$target.$_=$from.$_  and  "  for  @$pk;
        $sql =~ s/and\s*$//o , $sql;
}
sub _set_clause {
        my ($cols, $from) = @_ ;
	return unless @$cols;
        my  $sql =  'SET ' ;
        $sql .= "$_=$from.$_, "  for  @$cols;
	$sql =~ s/,\s*$/ /o; 
        $sql ;
}
sub update_string {
        my ( $from, $target, $set_cols, $where_cols ) = @_ ;
        my $sql  = "UPDATE $target ";
           $sql .=  _set_clause( $set_cols, $from ) ;
           $sql .= "FROM  $from   "  ;
           $sql .= _where_clause( $where_cols, $target, 'd');
}



1;
__END__

=head1 NAME

Pg::Loader::Query - Helper module for Pg::Loader

=head1 SYNOPSIS

  use Pg::Loader::Query;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1), which loads tables to
a Postgres database. It is similar in function to the pgloader(1)
python program (written by other authors).


=head2 EXPORT


Pg::Loader::Query - Helper module for Pg::Loader


=head1 SEE ALSO

http://pgfoundry.org/projects/pgloader/  hosts the original python
project.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
   
