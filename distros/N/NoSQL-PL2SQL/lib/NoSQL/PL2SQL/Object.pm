package NoSQL::PL2SQL::Clone ;
our @ISA = qw( NoSQL::PL2SQL::Object ) ;
use strict;
use warnings;

sub update {
	my $self = shift ;
	my $data = $self->{globals}->{memory}->{ $self->objectkey }->[0] ;

	if ( $self->{reftype} eq 'hashref' ) {
		my %out = map { $_ => NoSQL::PL2SQL::Object::item( 
				$data->{$_} )->[1] || $data->{$_} } 
				keys %$data ;
		$self->{data} = \%out ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		my @out = map { NoSQL::PL2SQL::Object::item( $_ ) || $_ }
				@$data ;
		$self->{data} = \@out ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		$self->{data} = \$data ;
		}
	else {
		$self->{data} = $data ;
		}
	}

sub sqlclone {
	my $self = shift ;
	my $data = $self->{data} ;
	my $out ;

	if ( $self->{reftype} eq 'hashref' ) {
		my %o = map { $_ => innerclone( $data->{ $_ } ) } 
				keys %$data ;
		$out = $self->mybless( \%o ) ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		my @o = map { innerclone( $_ ) } @$data ;
		$out = $self->mybless( \@o ) ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		my $o = $$data ;
		$out = $self->mybless( \$o ) ;
		}
	else {
		$out = $data ;
		}

	for my $v ( values %{ $self->{globals}->{memory} } ) {
		my $item = NoSQL::PL2SQL::Object::item( $v->[0] ) ;
		delete $item->[1]->{clone} if $item && $item->[1] ;
		}

	return $out ;
	}

sub innerclone {
	return NoSQL::PL2SQL::Object::innerclone( @_ ) ;
	}

sub DESTROY {
	my $self = shift ;

	$self->{globals}->{lock} ||= new NoSQL::PL2SQL::Lock $self
			if $self->{data} && ! $self->{globals}->{rollback} ;
	}


package NoSQL::PL2SQL::Lock ;
use strict;
use warnings;

my @errors ;

sub new {
	my $package = shift ;
	my $o = shift ;
	my $dsn = $o->{sqltable} ;
	my $header = $o->{globals}->{header} ;
	my $out = [ $dsn, $header ] ;

  	my $lock = $dsn->new->update( undef => [ deleted => 1 ] )->{nvp} ;
	my $incr = $dsn->new->update( undef => 
			[ intdata => $header->{intdata} +1 ] )->{nvp} ;

	for ( my $ct = 0 ; ! setlock( $dsn, $lock, $header->{id} ) ; $ct++ ) {
		select undef, undef, undef, .200 ;  ## wait 5 seconds
		next if $ct < 50 ;

		## deadlock failure
		@errors = NoSQL::PL2SQL->sqlerror unless @errors ;
		NoSQL::PL2SQL::sqlcarp( $header->{objecttype}, $errors[7], 
				{ timestamp => time, 
				  recordid => $header->{id} },
				$o->sqlclone,
				sprintf "%s: %d", $errors[7], $o->{top} ) ;

		$o->{globals}->{rollback} = 1 ;
		return $out ;
		}

	my $updates = $dsn->sqlupdate( $incr, 
			[ id => $header->{id} ], 
			[ intdata => $header->{intdata} ] ) ;

	unless ( $updates *1 ) {
		$o->{globals}->{rollback} = 1 ;
		push @$out, $o->mybless( $o->sqlclone ) ;
		my $serial = $dsn->fetch( [ id => $header->{id} ] 
				)->{ $header->{id} }->{intdata} || 0 ;
  		$incr = $dsn->new->update( 
				undef => [ intdata => ++$serial ] )->{nvp} ;
		$dsn->sqlupdate( $incr, [ id => $header->{id} ] ) ;
		}

	return bless $out, $package ;
	}

sub setlock {
	my $dsn = shift ;
	my $lock = shift ;
	my $id = shift ;
	my $r = $dsn->sqlupdate( $lock, 
			[ id => $id ], 
			$dsn->exclude( [ deleted => 1 ] ) ) ;
	return $r *1 ;
	}

sub DESTROY {
	my $self = shift ;
	my $dsn = $self->[0] ;
	my $header = $self->[1] ;

	if ( @$self == 3 ) {
		## delete all records except header
		$dsn->delete( [ objectid => $header->{objectid} ], 
				[ objecttype => $header->{objecttype}, 1 ],
				$dsn->exclude( [ id => $header->{id} ] )
				) ; 

		## insert clone
		my @nodes = NoSQL::PL2SQL::Node->factory(
				0, $header->{objectid}, $self->[2] ) ;
		pop @nodes ;
		my ( $ll, $refs ) = NoSQL::PL2SQL::Node->insertall(
				$dsn, NoSQL::PL2SQL::Node->combine( @nodes )
				) ;

		## swap out new header
		my $refto = $dsn->new->update( undef, [ refto => $ll ] 
				)->{nvp} ;
		$dsn->sqlupdate( $refto, [ id => $header->{id} ] ) ;
		}

	my $unlock = $dsn->new->update( undef => [ deleted => 0 ] )->{nvp} ;
	$dsn->sqlupdate( $unlock, [ id => $header->{id} ] ) ;
	}


package NoSQL::PL2SQL::Object ;

use 5.008009;
use strict;
use warnings;
use Scalar::Util ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL::Object ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '0.08';

# Preloaded methods go here.

sub TIEHASH {
	my $self = shift ;
	my $out = bless { %$self }, $self->package ;
	$out->{top} = shift @_ if @_ ;
	$out->{reftype} = $out->record->{reftype} ;
	return $out ;
	}

sub TIEARRAY {
	my $self = shift ;
	my $out = bless { %$self }, $self->package ;
	$out->{top} = shift @_ if @_ ;
	$out->{reftype} = $out->record->{reftype} ;
	return $out ;
	}

sub TIESCALAR {
	my $self = shift ;
	my $out = bless { %$self }, $self->package ;
	$out->{top} = shift @_ if @_ ;
	$out->{data} = shift ;
	$out->{reftype} = $out->record->{reftype} ;
	return $out ;
	}

## sub destroy {}	## for ctags
## avoid running during global destruction
sub DESTROY {
	my $self = shift ;
	my @xml = () ;

	delete $self->{globals}->{clone} ;

	return if $self->{globals}->{rollback} ;
	return unless $self->{update} ;
	return if $self->{top} && ! $self->record ;	## deleted

	map { $self->{sqltable}->delete( $_ ) } @{ $self->{delete} || [] } ;

	if ( $self->{top} ) {
		@xml = $self->updates ;

		if ( ! exists $xml[-1]{sql}{reftype} ) {}
		elsif ( grep $_ eq $xml[-1]{sql}{reftype},
				qw( scalar scalarref ) ) {
			my @chain = $self->linklist('chainedstring') ;
			map { $_->{sql}->{id} = shift @chain if @chain }
					reverse @xml ;

			map { $self->{sqltable}->delete( $_ ) } @chain ;
			}
		}
	else {
		my $parent = $self->record( $self->{parent } ) ;
		my $r = $parent->{reftype} ;
		my $o = $r eq 'hashref'? { $self->{key} => $self->{data} }:
				$r eq 'arrayref'? [ $self->{data} ]:
				$r eq 'scalarref'? \$self->{data}:
				return warn ;
		@xml = NoSQL::PL2SQL::Node->factory( 0,
				$parent->{objectid}, $o, 
				$parent->{objecttype} ) ;
		pop @xml ;	## perldata
		pop @xml unless grep $_ eq $self->{reftype},
				qw( arrayref hashref ) ;

		$xml[-1]{sql}{intkey} = $self->{sequence}
				if exists $self->{sequence} ;
		}

	my @combined = NoSQL::PL2SQL::Node::combine( @xml ) ;

	## references a new element
	foreach my $memo ( grep $_->memory &&
			$self->{globals}->{adds}->{ $_->memory },
			@combined ) {
		my $src = $self->{globals}->{adds}->{ $memo->memory } ;

		map { $memo->{sql}->{$_} = $src->{$_} }
				qw( blesstype reftype refto ) ;
		$memo->{sql}->{refto} = $src->{id}
				if $memo->{sql}->{reftype} eq 'scalarref' ;
		}

	## references an existing element
	if ( my $mrec = $self->refrecord( 1 ) ) {
		splice @combined, 0, -1 ;

		my $src = $self->record( $mrec ) ;
		map { $combined[-1]{sql}{$_} = $src->{$_} }
				qw( blesstype reftype refto ) ;
		$combined[-1]{sql}{refto} = $mrec 
				if $combined[-1]{sql}{reftype} eq 'scalarref' ;
		}

	my ( $ll, $refs ) = NoSQL::PL2SQL::Node->insertall( 
			$self->{sqltable}, @combined ) ;
	map { $self->{globals}->{adds}->{$_} = $refs->{$_} } keys %$refs ;

	if ( $self->{parent} ) {
	 	my $last = NoSQL::PL2SQL::Perldata::lastitem( 
				$self->{perldata}, $self->{parent} ) ;
		$self->{sqltable}->update( $last->[1], 
				[ $last->[0] => $ll ] ) ;
		$self->record( $last->[1] )->{ $last->[0] } = $ll ;
		}
	}

sub self {
	my $self = shift ;
	$self->data ;
	return $self->refrecord || $self ;
	}

sub linklist {
	my $self = shift ;
	my $k = pop ;
	my $r = $self->record( @_ ) ;

	my @o = $r->{id} ;
	$o[0] *= -1 if $r->{deleted} && ! $k ;

	my $kk = $k || 'item' ;
	push @o, $self->linklist( $r->{$kk}, $k ) if $r->{$kk} ;
	return @o ;
	}

sub record {
	my $self = shift ;
	my $k = @_? shift( @_ ): $self->{top} ;

	return $self->{perldata}->{ $k } if $k ;

	my @v = values %{ $self->{perldata} } ;
	return { %{ $v[0] } } ;		## clone is not writable
	}

sub topnode {
	my $self = shift ;
	my $top = @_? shift( @_ ): $self->{globals}->{top} ;

	my @ok = grep $_->[1] == $top, 
			values %{ $self->{globals}->{memory} } ;
	return $ok[0][0] ;
	}

## The copy creates a second reference to avoid inadvertant destruction
sub load {
	my $self = shift ;
	$self->{data} = shift ;
	$self->{copy} = shift if @_ ;
	$self->{ref} = $self->{data} ;

	return $self->{data} unless ref $self->{data} ;

	my @elements = $self->{reftype} eq 'hashref'? 
			  values %{ $self->{data} }:
			$self->{reftype} eq 'arrayref'? @{ $self->{data} }:
			$self->{reftype} eq 'scalarref'? ( ${ $self->{data} } ):
			warn "unknown reftype: " .$self->{reftype} ;

	foreach my $o ( grep ref $_, @elements ) {
		my @oo = @{ item( $o ) } ;
		next unless $oo[1]{top} ;

		my $k = $self->{globals}->{records}->{ $oo[1]{top} } ;
		my $rec = $self->{globals}->{memory}->{$k} if $k ;
		$self->{data} = $rec->[0] if $rec ;

		$self->{globals}->{records}->{ $oo[1]{top} } 
				= $self->objectkey ;
		$self->{globals}->{refcount}->{ $oo[1]{top} }++ ;

		my $refto = $oo[1]{reftype} eq 'scalarref'?
				$oo[1]->refto || $oo[1]->{top}: '' ;
		$oo[1]->loadscalarref( $refto ) 
				if $refto && ! exists 
				  $oo[1]->{globals}->{scalarrefs}->{$refto} ;

		next if $oo[1] == $o ;
		$oo[1]->memorymap( $o ) ;
		}

	return $self->{data} ;
	}

## refactoring?  may duplicate Perldata::fetchextract()
sub loadscalarref {
	my $self = shift ;
	my $refto = shift ;

	my $rr = $self->newelement( 
			NoSQL::PL2SQL::Perldata::item(
			  $self->{perldata}, $refto )->[1]
			) ;
	map { delete $rr->{$_} } 
			qw( parent last update globals ) ;
	$rr->{reftype} = $self->{reftype} ;
	$rr->{top} = $refto ;
	$self->{globals}->{scalarrefs}->{ $refto } = $rr ;
	$self->{globals}->{refcount}->{ $refto }++ ;
	}

sub memorymap {
	my $self = shift ;
	my $target = shift ;
	my $k = $self->objectkey ;
	my $top = @_? shift( @_ ): $self->{top} ;

	$self->{globals}->{memory}->{$k} = [ $target, $top ] ;
	Scalar::Util::weaken( $self->{globals}->{memory}->{$k}->[0] ) ;

	return $target ;
	}

sub data {
	my $self = shift ;
	my @inner = () ;
	my $blesstype = $self->record->{blesstype} ;
	my $refto = $self->record->{refto} ;

	my @args = @_ ;

	if ( $self->{reftype} eq 'hashref' ) {
		unless ( $self->{data} ) {
			@inner = NoSQL::PL2SQL::Perldata::fetchextract(
					$self, $refto, 'textkey' ) 
					if $refto ;

			$self->load( { @inner }, { @inner } ) ;
			bless $self->{data}, $blesstype if $blesstype ;
			}

		if ( @args ) {
			my $item = item( $self->{data}->{ $args[0] } ) ;
			return @args == 1? $item: $item->[ $args[1] ] ;
			}
		}

	elsif ( $self->{reftype} eq 'arrayref' ) {
		unless ( $self->{data} ) {
			@inner = NoSQL::PL2SQL::Perldata::fetchextract(
					$self, $refto, 'intkey' ) 
					if $refto ;
			my @sorter = () ;
			push @sorter, [ splice @inner, 0, 2 ] while @inner ;
			my @sorted = map { $_->[1] } 
					sort { $a->[0] <=> $b->[0] }
					@sorter ;

			$self->load( \@sorted, [ @sorted ] ) ;
			bless $self->{data}, $blesstype if $blesstype ;
			}

		if ( @args ) {
			my $item = item( $self->{data}->[ $args[0] ] ) ;
			return @args == 1? $item: $item->[ $args[1] ] ;
			}
		}

	elsif ( $self->{reftype} eq 'scalarref' ) {
		my $top = $self->record->{refto} || $self->{top} ;
		return @args == 2? $self->scalarref->[0]:
				@args == 1? $self->scalarref:
				$self->topnode( $top ) ;
		}

	else {
		return $self->{reftype} ;
		}

	return $self->{data} ;
	}

sub refto {
	my $self = shift ;
	return NoSQL::PL2SQL::Perldata::refto( 
			$self->{perldata}, $self->{top} ) ;
	}

sub sqlclone {
	my $tied = shift ;
	my $self = item( $tied )->[1] ;
	my $out = innerclone( $tied, $self ) ;

	for my $v ( values %{ $self->{globals}->{memory} } ) {
		my $item = item( $v->[0] ) ;
		delete $item->[1]->{clone} if $item && $item->[1] ;
		}

	delete $self->{clone} ;
	return $out ;
	}

sub innerclone {
	my $tied = shift ;

	my $self = @_? $_[0]: item( $tied )->[1] ;
	return $tied unless defined $self ;

	my $data = $self->data ;
	my $reference = NoSQL::PL2SQL::Object::item( $data )->[1] || 0 ;
	return $reference->{clone} if $reference && $reference->{clone} ;

	if ( $self->{reftype} eq 'hashref' ) {
		my %o = map { $_ => innerclone( $self->data->{ $_ } ) } 
				keys %$data ;
		return $self->{clone} = $self->mybless( \%o ) ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		my @o = map { innerclone( $_ ) } @$data ;
		return $self->{clone} = $self->mybless( \@o ) ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		my $o = ${ $self->data } ;
		return $self->mybless( \$o ) ;
		}

	return $self->{clone} = $self->{data} ;
	}

sub scalarref {
	my $self = shift ;
	my $data = $self->{globals}->{scalarrefs}->{ 
			$self->refto || $self->{top} }->{data} ;
	return [ $data, $self ] ;
	}

## what it is as a reference is not what it is as a standalone object

sub item {
	my $self = shift ;
	
	return [ $self, undef ] unless ref $self ;
	return [ $self, tied %$self ] if ref $self eq 'HASH' && tied %$self ;
	return [ $self, tied @$self ] if ref $self eq 'ARRAY' && tied @$self ;
	return [ $self, tied $$self ] if ref $self eq 'SCALAR' && tied $$self ;

	return [ $self, undef ] 
			if grep ref $self eq $_, qw( HASH ARRAY SCALAR ) ;
	return [ $self->{data}, $self ] if ref $self eq __PACKAGE__ ;

	return [ $self, tied %$self ] if $self->isa('HASH') && tied %$self ;
	return [ $self, tied @$self ] if $self->isa('ARRAY') && tied @$self ;
	return [ $self, tied $$self ] if $self->isa('SCALAR') && tied $$self ;

	return [ $self, undef ] ;
	}

sub update {
	my $self = shift ;
	my @sorted = () ;
	push @sorted, [ splice @_, 0, 2 ] while @_ ;
	map { $self->record->{ $_->[0] } = $_->[1] } @sorted ;
	$self->{update} = 1 ;
	$self->{globals}->{clone}->update
			if $self->{globals}->{clone} ;
	return $self ;
	}

sub mybless {
	my $self = shift ;
	my $o = @_? shift( @_ ): $self ;

	my $blesstype = $self->record->{blesstype} ;
	return $o unless ref $o && $blesstype ;
	return $o if grep $_ eq $blesstype, qw( SCALAR ARRAY HASH ) ;
	return bless $o, $blesstype ;
	}

sub resequence {
	my $self = shift ;
	map { $self->data( $_, 1 )->update()->{sequence} = $_ }
			0..$#{ $self->{data} } ;
	return $self->FETCHSIZE ;
	}

sub refcount {
	my $self = shift ;
	my $recid = @_? shift( @_ ): $self->{top} ;

	return --$self->{globals}->{refcount}->{ $recid } > 0? 
			(): ( $recid ) ;
	}

sub refrecord {
	my $self = shift ;
	return undef unless ref $self->{data} ;

	my $ii = item( $self->{data} ) ;
	return undef unless ref $ii->[1] eq ref $self ;

	my $k = $ii->[1]->objectkey ;
	my $v = $self->{globals}->{memory}->{$k} ;
	return undef unless $v ;		

	return $v->[ $_[0] ] if @_ ;

	my $rv = item( $v->[0] )->[1] ;
	return $rv->refrecord( @_ ) || $rv ;
	}

sub getkids {
	my $o = shift ;
	my @out = () ;
	return () unless ref $o ;

	@out = values %$o if ref $o eq 'HASH' ; 
	@out = @$o unless @out || ref $o ne 'ARRAY' ;
	return () if ref $o eq 'SCALAR' ;
	return () if ref $o eq __PACKAGE__ ;

	@out = values %$o unless @out || ! $o->isa('HASH') ;
	@out = @$o unless @out || ! $o->isa('ARRAY') ;
	return grep ref $_, map { item( $_ )->[1] } @out ;
	}

sub setreference {
	my $v = shift ;
	my $o = item( $v )->[1] ;

	if ( ref $o ne __PACKAGE__ ) {}
	elsif ( $o->{reftype} eq 'scalarref' ) {
		$o->{globals}->{refcount}->{ $o->{top} }++ ; 
		}
	else {
		map { $o->{globals}->{refcount}->{ $_->{top} }++ } 
				getkids( $o->data ) ;
		}

	return $v ;
	}

sub newelement {
	my $clone = shift ;
	my $self = bless {}, $clone->package ;
	map { $self->{$_} = $clone->{$_} } @NoSQL::PL2SQL::members ;

	$self->{parent} = $clone->{top} ;
	$self->{reftype} = 'item' ;
	$self->{data} = setreference( shift @_ ) if @_ ;
	$self->{update} = 1 ;
	$self->{globals}->{clone}->update
			if $self->{globals}->{clone} ;
	return $self ;
	}

sub equals {
	my $self = shift ;
	my @dd = ( $self->{data}, $self->{ref} ) ;
	$dd[1] = '' unless defined $dd[1] ;
	return ref $dd[0]? $dd[0] == $dd[1]: $dd[0] eq $dd[1] ;
	}

sub scalarok {
	my $self = shift ;

	return () unless $self->{top} ;
	return () if grep $self->{reftype} eq $_, 
			qw( scalarref arrayref hashref ) ;
	return () if ref $self->{data} ;
	return () if exists $self->{ref} ;
	return () if length $self->{data} > 512 ;

	my $item = NoSQL::PL2SQL::Perldata::item( 
			$self->{perldata}, $self->{top} )->[1] ;
	my @types = NoSQL::PL2SQL::Node::typemap( $self->{data}, $item ) ;
	return () unless $types[0] eq $types[1] ;

	## scalars are perfectly identical
	return ( undef ) unless $self->record->{defined} || defined $item ;
	return ( undef ) if $self->record->{defined} 
			&& defined $self->{data}
			&& $self->{data} eq $item ;

	## update scalar information
	$types[0] ||= 'stringrepr' ;
	return ( chainedstring => undef, 
			stringrepr => $self->{data},
			$types[0] => $self->{data}, 
			defined => defined $self->{data} ) ;
	}

sub updates {
	my $o = shift ;
	my $r = $o->record ;

	my %nvp = map { $_ => exists $r->{$_}? $r->{$_}: undef } 
				qw( id intkey deleted ) ;
	$nvp{intkey} = $o->{sequence} if exists $o->{sequence} ;

	my $self = bless { sql => \%nvp }, 'NoSQL::PL2SQL::Node' ;

	my %globals = map { $_ => $r->{$_} } qw( objectid objecttype ) ;

	if ( ! exists $o->{data} ) {}
	elsif ( $o->record->{deleted} ) {}
	elsif ( my @rewrite = $o->scalarok ) {
		my %rewrite = @rewrite > 1? @rewrite: () ;
		map { $self->{sql}->{$_} = $rewrite{$_} } keys %rewrite ;
		}
	elsif ( $o->equals( $o->{data}, $o->{ref} ) ) {}
		## existing container ##
	else {
		## scalar/container replacement ##
		my @xml = NoSQL::PL2SQL::Node->factory( 0,
				$globals{objectid}, 
				$o->{data}, 
				$globals{objecttype} ) ;
		pop @xml ;	## perldata element

		## pl2sql can't distinguish a scalarref
		$xml[-1]{sql}{reftype} = $o->{reftype}
				if $xml[-1]{sql}{reftype} eq 'scalar'
				&& $o->{reftype} eq 'scalarref' ;

		map { $nvp{$_} = undef } qw( intdata doubledata stringdata ) ;
		my $sql = $xml[-1]{sql} ;
		map { $nvp{$_} = $sql->{$_} } keys %$sql ;
		$xml[-1]{sql} = \%nvp ;

		foreach my $xml ( @xml ) {
			map { $xml->{sql}->{$_} = $globals{$_} } 
					keys %globals
					unless $xml == $xml[-1] ;
			}

		return @xml ;
		}

	return $self ;
	}

sub objectkey {
	my $self = shift ;
	return overload::StrVal( $self ) ;
	}

sub package {
	return __PACKAGE__ ;
	}

sub FETCH {
	my $self = self( shift @_ ) ;
	my $k = shift ;
	my $item = $self->data( $k ) ;

	return ref( $item->[0] )
			  && $item->[1]->{top} 
			  && $item->[1]->{reftype} eq 'scalarref'?
			$item->[1]->data: $item->[0] ;
	}

sub STORE {
	my $self = self( shift @_ ) ;
	my $v = pop ;
	my $k = shift( @_ ) if @_ ;
	my $element ;
	my $o ;

	if ( $self->{reftype} eq 'hashref' ) {
		$o = $self->{data}->{$k} = $self->{data}->{$k}?
				item( $self->{data}->{$k} )->[1]:
				$self->newelement ;
		$o->{key} = $k ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		my $seqflag = ! $self->{data}->[$k] ;
		$o = $self->{data}->[$k] = $self->{data}->[$k]?
				item( $self->{data}->[$k] )->[1]:
				$self->newelement ;

		map { $self->{data}->[$_] ||= $self->newelement() }
				0..$#{ $self->{data} } ;
		$self->resequence if $seqflag ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		$o = $self->{globals}->{scalarrefs}->{ 
				$self->refto || $self->{top} } ;
		$o->{globals}->{header} ||= $self->{globals}->{header} ;
		}
	else {
		warn $self->{reftype} ;
		}
	
	$o->CLEAR if grep $_ eq $o->{reftype}, qw( hashref arrayref ) ;
	$o->{data} = setreference( $v ) ;
	$o->update( deleted => undef ) ;

	return $o->{data} ;
	}

sub STORESIZE {
	my $self = self( shift @_ ) ;
	my $count = shift ;
	}

sub EXTEND {
	my $self = self( shift @_ ) ;
	$self->STORESIZE( @_ ) ;
	}

sub FETCHSIZE {
	my $self = self( shift @_ ) ;
	return scalar @{ $self->{data} } ;
	}

sub POP {
	my $self = self( shift @_ ) ;
	my $k = $self->FETCHSIZE -1 ;
	return $self->DELETE( $k, 1 ) ;
	}

sub PUSH {
	my $self = self( shift @_ ) ;
	my @add = map { $self->newelement( $_ ) } @_ ;

	push @{ $self->{data} }, @add ;
	return $self->resequence ;
	}

sub SHIFT {
	my $self = self( shift @_ ) ;
	my $k = 0 ;
	my $rv = $self->DELETE( $k, 1 ) ;

	$self->resequence ;
	return $rv ;
	}

sub UNSHIFT {
	my $self = self( shift @_ ) ;

	unshift @{ $self->{data} },
			map { $self->newelement( $_ ) } @_ ;
	return $self->resequence ;
	}

sub SPLICE {
	my $self = self( shift @_ ) ;
	my $offset = @_? shift( @_ ): 0 ;
	my $length = @_? shift( @_ ): $self->FETCHSIZE -$offset ;
	my @add = map { $self->newelement( $_ ) } @_ ;

	my @sample = ( 0..$#{ $self->{data} } ) ;
	my @gone = splice @sample, $offset, $length, map { \$_ } 
			0..$#add ;
	my @data = map { ref $_? $add[ $$_ ]: $self->{data}->[$_] } 
			@sample ;

	my @rv = map { $self->FETCH( $_ ) } @gone ;
	map { $self->DELETE( $_, 1 ) } reverse @gone ;

	$self->{data} = \@data ;
	$self->resequence ;
	return @rv ;
	}

sub DELETE {
	my $rv = FETCH( @_ ) ;
	my $self = self( shift @_ ) ;
	my $k = shift ;
	my $obliterate = shift ;

	$self->sqlclone ;	## need to expose all references

	my $item = $self->data( $k ) ;
	my $o = $item->[1] ;
	return undef unless $o ;

	$o->CLEAR unless $o->{reftype} eq 'item' ;
	$o->update( deleted => 1 ) if $obliterate ;

	if ( $self->{reftype} eq 'hashref' ) {
		$o->update( deleted => 1 ) ;
		delete $self->{data}->{$k} ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		$o->update( defined => 0 ) ;
		$obliterate?
				splice @{ $self->{data} }, $k, 1:
				delete $self->{data}->[$k] ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		$o->update( defined => 0 ) ;
		delete $self->{data} ;
		}

	delete $o->{update} unless $o->{top} ;
	return $rv ;
	}

sub CLEAR {
	my $self = self( shift @_ ) ;

	my @delete = NoSQL::PL2SQL::Perldata::descendants(
			$self->{perldata}, $self->{top}, 1 ) ;
	pop @delete ;

	my @deleteok = map { $self->refcount( $_ ) } @delete ;
	$self->{delete} = \@deleteok ;

	map { delete $self->{perldata}->{$_} } @{ $self->{delete} } ;
	}

sub EXISTS {
	my $self = self( shift @_ ) ;
	my $k = shift ;

	return exists $self->{data}->{$k} ;
	}

sub FIRSTKEY {
	my $self = self( shift @_ ) ;
	$self->{keys} = [ keys %{ $self->{data} } ] ;
	return $self->NEXTKEY ;
	}

sub NEXTKEY {
	my $self = self( shift @_ ) ;
	return shift @{ $self->{keys} } ;
	}

sub debug {
	do {
		no warnings ;
		my @cc = caller ;
		my $flag = sprintf '@%d> ', $cc[-1] ;
		push @NoSQL::PL2SQL::debug, $flag .join( '|', @_ ) ;
		} ;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::Object - Private Perl extension for NoSQL::PL2SQL

=head1 SYNOPSIS

The NoSQL::PL2SQL::Object package is private.  None of its methods or functions are part of the public interface.

Except for the TIE constructors, NoSQL::PL2SQL::Object methods are only called indirectly through the overloaded TIE operators and during destruction.  

  use NoSQL::PL2SQL::Object ;

  ## Constructors

  TIEHASH
  TIEARRAY
  TIESCALAR

  $blessedvalue = $tied->mybless( $value )

C<mybless()> is part of the constructor process, called immediately after the TIE constructor.

  ## Overloading Operators
  ## $tied refers to the first argument to these operators.

  my $tied = tied %$value ;	## $value is an object or element

  FETCH
  STORE
  STORESIZE
  EXTEND
  FETCHSIZE
  POP
  PUSH
  SHIFT
  UNSHIFT
  SPLICE
  DELETE
  CLEAR
  EXISTS
  FIRSTKEY
  NEXTKEY

  DESTROY

The following methods are used as part of initialization.

  my $value = $tied->data() ;
  my $value = $tied->data( $key ) ;
  my $value = $tied->data( $key, 0 ) ;
  my $tied = $tied->data( $key, 1 ) ;

  $tied->load() ;
  $tied->loadscalarref( $tied->refto || $tied->{top} ) ;
  $tied->memorymap() ;

An object that implements NoSQL::PL2SQL is represented as a tree of NoSQL::PL2SQL::Object nodes.  Each node is tied, so an operation on any object element calls one of the overloading operators, which actually performs the operation on its Object node.

When an object is retrieved using C<< NoSQL::PL2SQL->SQLObject() >>, data is fetched from the RDB, the top Object Node is created, tied, optionally blessed, and returned to the caller as a representation of the original object.  After this creation, the representation is nothing more than an empty top node Object.  (object refers to the instantiation of the caller application; Object refers to a NoSQL::PL2SQL::Object- thus, an Object is a node in a tree that represents an object.)

Creation and loading occur separately  Loading occurs when an object element is accessed.  If the element is a container, the child nodes are created.  If the element is a scalar, the Object is loaded with data.  C<data()> is called whenever an element is accessed, which in turn calls C<load()> if necessary.  C<memorymap()> is also called during load.  The memorymap keeps track of nodes with multiple parents- elements that are shared internal references.

A scalar reference is normally implemented as a data node.  However, if the reference is shared, subsequent nodes are created as containers.  If the first loaded node is a container, the data node is also loaded using C<loadscalarref()>.

The following methods are used as part of data access.

  my ( $value, $tied ) = @{ item( $value ) } ;
  my ( $value, $tied ) = @{ scalarref( $value ) } ;

  $self = $tied->self() ;
  $refitem = $tied->refrecord() ;
  $refto = $tied->refto() ;
  $nvp = $tied->record() ;
  $nvp = $tied->record( $recnumber ) ;

After loading a node, the C<data()> method may call the C<item()> or C<scalarref()> method.  C<data()> can return either an element, its tied Object node, or in the case of a scalarref, a deferenced value using the output of these methods.

Elements are accessed using the overloading function of its node's parent.  When elements are shared using internal references, their nodes have multiple parents.  For consistency, modifications should always be applied via the same parent.  In the overloading functions, therefore, the parent node (passed by the caller) may be replace with another parent using the C<self()> method.  Since references can be chained, C<self()> calls C<refrecord()> recursively.  In a scalar reference container, the data source is a node identified in the refto property.  To handle chained references, scalar references use the <refto()> method instead.

Most of an Object's properties are maintained in the original data structure returned by the RDB.  These properties can be accessed using the C<record()> method which returns the whole set as a hash reference. Nodes are linked, and the properties of a child or sibling node can be accessed by passing the refto or item link value as an argument.

When an element is modified, a node is either modified, added, deleted, or added and deleted (replaced), using the following operations:

=over 8 

=item 1.  The scalar data property is modified

=item 2.  A scalar is added

=item 3.  An untied object is added

=item 4.  A node reference is added

=item 5.  The node is deleted

=back

  ## modify internal data
  $tied->update( $sqlname => $sqlvalue, ... ) ;

  ## add a scalar, untied object, or reference
  $tiedarraycontainer->resequence() ;
  $item = $containeritem->newelement()

  ## add a reference
  $tied = $tied->setreference()
  @tied = $tied->getkids()

  ## delete a node
  my @idlist = $tied->linklist( $type ) ; ## $type is 'item' or 'string'
  my $tiedtop = $tied->topnode() ;
  my $tiedany = $tied->topnode( $recno ) ;
  $value = $tiedtop->sqlclone()
  $ct = $tied->refcount() ;

The C<update()> method affects the low level record data.  It also sets the update property to indicate that a change must be written back to the RDB.

C<newlement()> is called every time a node is added.  The new element may contain a scalar, untied object, or reference to another node.  When a reference is added, C<setreference()> is used to increment the reference count.  All of the nodes underneath the added reference's node must also be incremented.  C<getkids()> is called recursively to pull the complete set.

If an array element is added or deleted, the other elements need to be resequenced by calling the C<resequence()> method on the container, which in turn calls C<update()> on all of the child nodes to replace the index value.

When an element is deleted, PL2SQL will attempt to delete the affected node records from the RDB by identifying all the descendents in a container node using C<< NoSQL::PL2SQL::Perldata->descendants() >>; and all the linked nodes of a large scalar using the C<linklist()> method.  A reference count map is used so that referenced elements aren't destroyed.  C<refcount()> decrements the count and returns the result.

The referencecount map isn't accurate until all the nodes have been loaded.  So CLEAR calls C<sqlcount()>, which returns an untied copy of the element represented by the node $tied, and recursively loads all the descendant nodes.  In order to load all nodes, C<sqlclone()> must be called on the top node, using the C<topnode()> method.  Otherwise, C<topnode> can fetch any node using a $recno argument.

Changes to the original object are never written to the RDB until the object is destroyed.  When destroyed, the top Object node in the tree is destroyed along with its child nodes, until all the nodes have been destroyed.  Each node is written as it is destroyed.  The sequence is indeterminate, so the operation must be performed using only the node properties.

  my @nodes = $tied->updates() ;
  my $recno = $tied->lastitem() ;
  my $bool = $tied->equals() ;
  my @nvp = $tied->scalarok() ;

The DESTROY sequence is as follows:

=over 8

=item 1. Records belonging to deleted child nodes are deleted.

=item 2. The node is converted to a NoSQL::PL2SQL::Node object via the C<updates()> method.  If the node's data is an untied object, or large scalar, the conversion may result in a set of Node objects.

=item 3. C<< NoSQL::PL2SQL::Node::combine() >> and C<< NoSQL::PL2SQL::Node::insertall() >> methods are called on the node set.

=back

When an object is created, C<NoSQL::PL2SQL::Node::insertall()> keeps track of, and sets link values internally.  When an object is updated, DESTROY must perform this housekeeping.  The C<PL2SQL::Node::lastitem()> method is used, for example, to identify the last node in a linked list.

C<updates()> is responsible for generating Nodes that are eventually written into the RDB.  When returned Nodes have no "id" property, the SQL engine NoSQL::PL2SQL::DBI will create new records to accomodate them.  C<update()> performs two tests to minimize overhead:  C<equals()> is used to see if the Object's data has been modified; C<scalarok()> is used to see if a data node can be reused.

C<scalarok()> returns varying output depending on the complexity of the change.  If the value is completely unchanged, the result is an array containing a single undefined element.  If the value is significantly changed, new NoSQL::PL2SQL::Node's need to be generated, and the method returns an empty array.  If the value is slightly changed (eg a small scalar to another small scalar) the result is an nvp set that reflects the changed properties.

=head1 NoSQL::PL2SQL::Clone

NoSQL::PL2SQL::Clone is one of two helper classes that have been added in v1.2.  The purpose of this class is to override the destructor so that the C<DESTROY> method is called on what is otherwise a self-referencing object.

The C<Clone> instance is always a reference to the top node.  This destructor should always be called before any of the C<Object> nodes are destroyed.

=head1 NoSQL::PL2SQL::Lock

NoSQL::PL2SQL::Lock is the other helper class.  It's instantiated before the first node is destroyed and it's destruction method is called after the last C<Object> node is destroyed.

The C<Lock> instance is applied directly to that objects's record.  Requests to create a second instance on that record, from any PL2SQL client, are blocked until the existing instance is destroyed.

NoSQL::PL2SQL is designed to make incremental updates: Only changed object elements are updated when the object is destroyed.  But when a record is concurrently accessed, its state is indeterminate, and incremental updates cannot be successfully applied.  In that case, the C<Lock> object uses an incrementing header record to detect concurrent record access and performs a full update by writing all the nodes to the database instead. 

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -AXCO
	NoSQL::PL2SQL

=item 0.02	

Cleaned perldoc formatting issues

=item 0.03	

Fixed C<sqlclone()>

=item 0.04	

Removed lastitem() method.  C<PL2SQL::Perldata::lastitem()> is now called during C<DESTROY()>

=item 0.05	

Fixed: C<DESTROY()> method sometimes loses global values to build sql properties of new nodes.

=item 0.06

Fixed: C<DELETE()> override throws error on a missing key

=item 0.06

Added the C<package()> method to C<Object>, which functions the same as Perl's built-in C<ref> function, except it must be explicitly overridden in subclasses.

Added the C<objectkey()> method to C<Object> as a convenience.

Added the I<header> property to C<Object>.  The header references a data source table row that keeps track of locking activity.

Added the NoSQL::PL2SQL::Clone object.  When a PL2SQL object is created, its reference is saved as a global property within the C<memorymap()> operation.  To avoid a destruction deadlock, the reference is saved as a blessed C<Clone> object instead of an C<Object> object.  NoSQL::PL2SQL::Clone has the difficult job of cloning an object that's already been destroyed.

Added the NoSQL::PL2SQL::Lock object which blocks simultaneous record writes to the database.  The C<Lock> object also determines whether to perform a full or incremental update.

The C<sqlclone()> method creates a cloned copy for each container element.  When an element is an internal reference, C<sqlclone()> needs to return the referenced clone.  Some housekeeping code was added to implement this feature correctly.  The changes includes a new method, C<innerclone()>, which isolates the recursive operations.

=item 0.08

C<FETCH()> needs an exception for scalar references.  Performed a little refactoring among C<data()>, C<FETCH()>, and C<DELETE()> to isolate this requirement.

=back

=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item NoSQL::PL2SQL::Node

=item http://pl2sql.tqis.com/

=back


=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
