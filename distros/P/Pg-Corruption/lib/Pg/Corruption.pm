package Pg::Corruption;
use Data::Dumper;
use 5.012000; use strict; use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
	connect_db
	schema_name
	primary_keys
	dup_pks 
	attnum2attname
	tbl_byoid
	foreign_keys
	verify_one_fk
	dup_fks 
); 

our $VERSION = '0.02';

sub schema_name  {
    my ($canonical, $search) = @_ ;
    my ($schema, $table) = split /\./, $canonical||return, 2 ;
    unless ($table ) {
        $table  = $schema;
        $schema = $search || 'public';
	}
    ( $schema, $table );
}
sub connect_db {
        my $o   =  shift                                      ;
        my ($port, $host, $db) = @{$o}{qw/ port host db/}     ;
        my ($user, $pass)      = @{$o}{qw/ user pass/ }       ;
        $port    //=  5432                                    ;
        $host    //=  'localhost'                             ;
        $user    //=  getlogin                                ;
        $db      //=  'template1'                             ;
        my $dsn    =  "dbi:Pg:dbname=$db;host=$host;port=$port"  ;
           $dsn   .= ';options=--client_min_messages=ERROR'      ;
            $ENV{ PGSYSCONFDIR } //= $o->{pgsysconfdir} //''     ;
        if ( -f "$ENV{ PGSYSCONFDIR }/pg_service.conf") {
			warn( "Using PGSYSCONFIGDIR \n")         ;    
            $dsn = 'dbi:Pg:service='.$o->{service}   ;
			$user = $pass = ''                       ;
		}
        my $att  = { AutoCommit => 0 , pg_server_prepare => 1,
                     PrintError => 0 , Profile           => 0,
           };
        DBI->connect( $dsn, $user, $pass, $att) or die "$DBI::errstr\n";
}

sub primary_keys {
	my ($schema,$table, $dh, $o) = @_;
	(my $st = $dh->prepare(<<"")) ->execute("$schema.$table") or return ;
	SELECT C.oid, T.conkey
	FROM   pg_constraint T JOIN pg_class     C ON (T.conrelid     = C.oid)
	WHERE   C.oid = ?::regclass
	  AND contype   = 'p'

	return unless $st->rows;
	my $h = $st->fetchrow_hashref;
    attnum2attname($h->{oid},$dh,@{$h->{conkey}}) ;
}
sub dup_pks {
	my ($schema,$table, $pks, $dh, $o) = @_;
       #--AND attnum  IN  ( @{[join',',@cols]})
	$dh->begin_work;
	$dh->do(<<"");
	SET LOCAL ENABLE_INDEXSCAN     = on ;
	SET LOCAL ENABLE_BITMAPSCAN    = off;
	SET LOCAL ENABLE_INDEXONLYSCAN = off;

	(my $st = $dh->prepare(<<"")) ->execute() or say $dh->errstr ;
	    SELECT @{[join',',@$pks]} , count(*)
	    FROM   $schema.$table
	    GROUP BY  @{[join',',@$pks]}
	    HAVING count(*) > 1

	while (my ($h) = $st->fetchrow_hashref) {
		last unless keys %$h;
		$h->{$_} //= '\N' for keys %$h;
		say  join',',@{$h}{keys %$h}   unless $o->{quiet};
    }
	$dh->rollback;
	$st->finish;
	return $st->rows;
}

sub attnum2attname {
	my ($oid,$dh, @nums) = @_;
	return unless @nums;
	my $st = $dh->selectall_arrayref(<<"",{},$oid);
	SELECT  attname
	FROM  pg_attribute
	WHERE attrelid = ?  AND attnum IN  ( @{[join',',@nums]})

	map{@$_} @$st;
}
sub tbl_byoid {
	my ($oid,$dh) = @_;
	(my $st = $dh->prepare(<<""))->execute($oid)  or return;
	SELECT   nspname || '.' || relname  AS name
	FROM  pg_class C JOIN pg_namespace N ON (C.relnamespace = N.oid)
	WHERE C.oid = ?  

	return unless $st->rows;
	$st->fetchrow_hashref->{name};
}

sub foreign_keys {
	my ($schema,$table,$dh) = @_;
	(my $st = $dh->prepare(<<"")) ->execute("$schema.$table") or  return ();
	SELECT conrelid, confrelid, conkey ,  confkey
	FROM  pg_constraint
	WHERE conrelid = ?::regclass
        AND contype = 'f'

	return unless $st->rows;
	$dh->trace(0);
	my @result;
	while ( my ($r) =  $st->fetchrow_hashref) {
		last unless keys %$r;
		push @result, 
		{ relid  => "$schema.$table",
		  frelid => tbl_byoid($r->{confrelid},$dh),
		  key    => [ attnum2attname( $r->{conrelid},  $dh, @{$r->{conkey }}) ],
		  fkey   => [ attnum2attname( $r->{confrelid}, $dh, @{$r->{confkey}}) ],
        }
	}
	@result;
}
sub dup_fks {
	my ($fk, $dh, $o) = @_;
	return 'ok' unless @$fk;

	for (@$fk) {
		verify_one_fk(@{$_}{qw/ relid frelid key fkey/}, $dh,$o) or return;
	}

	#warn sprintf "Great! No fk corruption in \"%s\"\n",
    #                  $fk->[0]{relid}   unless $o->{quiet} ;
	'ok';
}
sub verify_one_fk {
	my ($rel, $frel, $k, $fk, $dh, $o) = @_;
	my ($att, $fatt) = ( @$k, @$fk);

	# assumes rel and $frel are not compound keys
	@$k > 1 and warn "Compound fk not supprted. Skipping table\n" unless $o->{quiet};
	return if @$k > 1 ;
	return unless $rel && $frel && @$k && @$fk ;

	$dh->begin_work;
	$dh->do(<<"");
	SET LOCAL ENABLE_INDEXSCAN     = on ;
	SET LOCAL ENABLE_BITMAPSCAN    = off;
	SET LOCAL ENABLE_INDEXONLYSCAN = off;

	(my $st = $dh->prepare(<<"")) ->execute() ;
	SELECT S.*, B.*
	FROM $rel S LEFT JOIN $frel B ON (S.$att = B.$fatt)
	WHERE B.$fatt IS NULL
	ORDER BY S.$att

	$dh->rollback;
	while (my ($h) = $st->fetchrow_hashref) {
		last unless keys %$h;
		$h->{$_} //= '\N' for keys %$h; 
	    say(  join',',@{$h}{keys %$h} )   unless $o->{quiet};
    }
	$st->rows or 'ok';
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Pg::Corruption - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Pg::Corruption;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Pg::Corruption, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

ioannis, E<lt>ioannis@macports.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by ioannis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
