
# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader::Copy;

use 5.010000;
use DBI;
use Fatal qw(open);
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );
use strict;
use warnings;
use Pg::Loader::Query qw/ _truncate _disable_triggers _disable_indexes 
                          vacuum_analyze pgoptions/;
use Pg::Loader::Misc  qw/ error_check filter_ini insert_semantic_check
	                  reformat_values add_modules /;
use Pg::Loader::Columns qw/ requested_cols init_csv combine/;
use Pg::Loader::Log   qw/ log_rejected_data log_reject_errors/;
use Log::Log4perl  qw( :easy );
use SQL::Abstract;
use Storable qw( dclone );
use base 'Exporter';

our $VERSION = '0.17';

our @EXPORT = qw( copy_loader  load_2table _stop_input _no_pk_found) ;




sub _stop_input {
	my ($conf, $rows) = @_ ;
	($rows//0) >= ($conf->{count} // '1E10')   ;
}
sub _no_pk_found {
	my  ($ini,$section) = @_ ;
	my  $s = $ini->{$section};
	my $msg   = qq(\tTable $s->{table} )
	    . q(does not contain pk. Skipping...);
	WARN( $msg ) ;
	{    name => $section,  elapsed => 0,
	     rows => 0,         errors  => 'no pk',
	     size => $s->{copy_every},
	}
}
sub copy_loader {
	my ( $conf, $ini, $dh, $section ) = @_                 ;
	my   $s    =  $ini->{$section}                         ;
	my   $dry  =  $conf->{dry}                             ;
	INFO("COPY, as per [$section]")                        ;
        $ini->{$section}{table}      = $conf->{relation} if $conf->{relation} ;
        $ini->{$section}{copy_every} = 1                 if $conf->{every}    ;
	error_check(      $ini, $section        )                             ;
	filter_ini(       $ini->{$section}, $dh )                             ;
	insert_semantic_check( $ini->{section} )               ;
	reformat_values(  $ini->{$section}, $dh )              ;
	add_modules(      $ini->{$section}, $dh )              ;

	load_2table ( dclone($conf), dclone($ini), $dh, $section )  ;
}

sub load_2table {
	my ( $conf, $ini, $dh, $section ) = @_                ;
	my  $s = $ini->{$section}                             ;
	my ($dry , $r )= ( $conf->{dry}, $s->{copy_every} )   ;
	my ($file, $format, $null, $table) = 
                    @{$s}{'filename','format','null','table'} ;
	my ($col, @col) = requested_cols( $s )                ;
	INFO("\tData from $file")                             ;
	my $fd  = \* STDIN                                    ;
	open $fd, $file           unless  $file=~/^STDIN$/i   ;
	my $csv = init_csv( $s )                              ;
	$csv->column_names( @{$s->{copy}}  )                  ;

	local $dh->{ AutoCommit } = 0 ;
	$dh->begin_work;
	pgoptions( $dh, $s );	
	_truncate( $dh, $table, $dry )             if $conf->{truncate};
	_disable_triggers( $dh, $table, $dry)      if $conf->{disable_triggers};

	my ($t0, $data) =  ([gettimeofday], 'true')  ;
	my ( $rows, $total, $errors); 

	while ( $data ) {
	        ($rows,$data) = _insert($s, $dh, $col, $csv, 
                                  $fd, $section, $conf, @col );
		$rows > 0 ?  ($total+=$rows) : ($errors+=-$rows)             ;
	        last unless $data                                            ;
	        last if _stop_input($conf, $rows//0)                         ;
	}
	$total  ? $dh->commit : $dh->rollback;
	vacuum_analyze( $dh, $table, $dry )        if $conf->{vacuum};

	{ name    => $section,           elapsed => tv_interval($t0), 
	  rows    => $total//0,          errors  =>  $errors//0,
	  size    => $s->{copy_every},
        }
}


sub _insert {
	my ($s, $dh, $col, $csv, $fd, $section, $conf, @col ) = @_;
	my ( $format, $null, $table) = @{$s}{'format','null','table'};
	my ($dry , $r )= ( $conf->{dry}, $s->{copy_every} );

	$dh->pg_savepoint('every_block');
	my $defs = _disable_indexes( $dh, $table)     if $conf->{indexes};
	my $sql  =   qq( COPY $table $col FROM STDIN ) 
                   . ($s->{format} eq 'csv' ? ' CSV ' : "" )
                   . qq( DELIMITER '$s->{field_sep}'  NULL $s->{null} );

	DEBUG( "\t\t$sql" )                                   ;
	$dh->do( $sql )  if (! $dry)                          ;

	## Initialize $dh, and NDC
        local $dh->{ PrintError } = 0 ; 
	local $dh->{ RaiseError } = 1 ;
        $Log::Log4perl::NDC = $s->{copy_every};
	Log::Log4perl::NDC->remove ;

	my ($rows, $data) ;
	while ( $r -- ) {
	        $data = $csv->getline_hr ($fd) ;
		last unless $data;
		last if _stop_input($conf, $rows//0)              ;
		$_     = combine( $s, $csv, $data, @col )         ;
		Log::Log4perl::NDC->push( "$_\n" ) if $_;
		DEBUG( "\t\t$_" )                                 ;
		$rows += $dh->pg_putcopydata("$_\n") unless $dry  ;
	}

	eval {
		$dh->pg_putcopyend  ;
		enable_indexes( $dh,$table,$defs)  if $conf->{indexes};
		Log::Log4perl::NDC->remove;
		1;
	} || do {
		log_rejected_data( $s, $section );
		log_reject_errors( $s, $dh->errstr, $section );
		$dh->pg_rollback_to("every_block");
		return (-$rows//0, $data);
	};
	return ($rows//0, $data);
}


1;
__END__

=over

=item dist_abstract

=back

Perl extension for bulk inserts


=head1 NAME

Pg::Loader::Copy - The bulk inserts operation 

=head1 SYNOPSIS

  use Pg::Loader;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1), it loads and updates 
tables in a Postgres database. It is similar in function to 
the pgloader(1) python program (written by other authors) with
enhancements plus the ability to update tables.

=head2 EXPORT

Pg::Loader - Perl extension for loading and updating Postgres tables


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
