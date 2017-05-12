# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .
package Pg::Pcurse::Query2;
use v5.8;
use DBIx::Abstract;
use Carp::Assert;
use base 'Exporter';
use Data::Dumper;
use strict;
use warnings;
our $VERSION = '0.14';
use Pg::Pcurse::Query0;


our @EXPORT = qw( 
	tables_brief_desc     tables_brief 
	actual_tables_rows    estimated_tables_rows
);



sub estimated_tables_rows {
	# Output: a hashref like { tablename => row_size, ... }
	#         {tblname=>undef} when permissions inhibit read access
	#         {tblname=>0}     when table contains no rows

        my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
        my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        $schema = $dh->quote($schema);
        my $st = $dh->select({
                     fields => [qw( relname   reltuples)],
                     tables => 'pg_class,pg_namespace',
                     join   => 'pg_class.relnamespace =  pg_namespace.oid',
                     where  =>  ['pg_namespace.nspname', '=', $schema ,
                                'and', 'relkind', '=', q('r') ],
                   });
        $_ = { map {  @{$_}[0..1] } @{$st->fetchall_arrayref}  };
}


sub tables_brief_desc {
	 sprintf '%-26s %12s %12s    %6s %10s', 'NAME', 'tupl', 'est_tupl',
                                            'analyze', 'total_pages';
}

sub tables_brief {
	my ($o, $database , $schema) = @_;
        $database or $database = $o->{dbname} ;
	my $dh = dbconnect ( $o, form_dsn($o,$database)  ) or return;
        (my $st  = $dh->{dbh}->prepare(<<""))->execute($schema) or return ;
	select relname,
		greatest( last_vacuum,  last_autovacuum)  AS vacuum,
		greatest( last_analyze, last_autoanalyze) AS analyze,
		pg_total_relation_size(relid) AS rsi
	from pg_stat_all_tables
	where schemaname= ?
	order by 1

        my $actual    = actual_tables_rows( $o, $database , $schema) ;
        my $estimated = estimated_tables_rows( $o, $database , $schema) ;
	my @arr;
	while ( my $h = $st->fetchrow_hashref) {
                my $relname = $h->{relname};	

		push @arr, sprintf '%-26s %12s %12s   %8s   %8s', 
                                       $h->{relname}, 
		(defined $actual->{$relname} ? $actual->{$relname} 
                                            : 'not_read'),
		(defined $estimated->{$relname} ? $estimated->{$relname} 
                                            : 'no_estima'),
					to_h( $h->{analyze}), 
                                        #to_h( $h->{vacuum }) ;
                                         $h->{rsi}/8192 ;
        }
        [ @arr ];
}

sub actual_tables_rows {
	# Output: a hashref like { tablename => row_size, ... }
	#         {tblname=>undef} when permissions inhibit read access
	#         {tblname=>0}     when table contains no rows

	my ($o, $database , $schema ) = @_;
	#return ['system'] if $schema =~ /^ (pg_ | information_schema) /xo;
	my $dh  = dbconnect ( $o, form_dsn($o, $database ) ) or return;
	my $st  = $dh->select( 'tablename AS name', 
                               'pg_tables',
                               ['schemaname','=', $dh->quote($schema)]) 
                                        or return {} ;

	for my $relname ( map {@$_} @{ $dh->fetchall_arrayref} ) { 
		eval {($_{ $relname }) = $dh->select_one_to_array( 'count(1)',
                                                     "${schema}.${relname}");
		};
	}
	\%_ ;

}


1;
__END__
=head1 NAME

Pg::Pcurse::Query2  - Support SQL queries for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Query2;

=head1 DESCRIPTION

Support SQL queries for Pg::Pcurse


=head1 SEE ALSO

Pg::Pcurse, pcurse(1)

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut
