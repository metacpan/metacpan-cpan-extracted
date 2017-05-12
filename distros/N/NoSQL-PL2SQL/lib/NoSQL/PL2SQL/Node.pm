package NoSQL::PL2SQL::Node ;

use 5.008009;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL::Node ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '0.07';

# Preloaded methods go here.

## The objectid is optional.  If objectid is assigned automatically, 
## objectid = recno of perldata element.  Which is otherwise the last 
## element to be inserted.
sub factory {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $dsn = shift ;
	my $objectid = ! defined $_[0]? shift( @_ ):
			ref $_[0]? undef: shift( @_ ) ;
	my $o = shift ;
	my $ref = @_? shift( @_ ): '' ;

	my $globals = { objecttype => $ref || ref $o } ;
	$globals->{objectid} = $objectid if defined $objectid ;
	my @nodes = xml2sql( XML::Parser::Nodes->pl2xml( $o ), $globals ) ;
	return @nodes unless $dsn && $dsn->dbconnected ;

	unless ( defined $objectid ) {
		$nodes[-1]->sql( $dsn ) ;
		$objectid = $nodes[-1]->{sql}->{id} ;
		map { $_->{sql}->{objectid} = $objectid } @nodes ;
		}

	insertall( $dsn, combine( @nodes ) ) ;
	return $objectid ;
	}

sub xml2sql {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $parent = undef ;

	$parent = pop if @_ > 3 ;			## ARRAY
	my $globals = pop if ref $_[-1] eq 'HASH' ;	## HASH
	my $node = pop ;				## XML::Parser::Nodes
	my $key = pop ;					## scalar

	$globals ||= {} ;

	my $child = [ $key, $node ] ;
	my @out = map { xml2sql( @$_, $globals, $child ) } 
			$node->childnodes() ;
	push @out, new( __PACKAGE__, @$child, $parent, $globals ) if $parent ;
	return @out ;
	}

my @nok ;	## debugging artifact

my %typemap = (
	integer => "intdata",
	double => "doubledata",
	string => "stringdata",
	) ;

## From the schema
my @strings = qw(
	stringdata
	textkey
	objecttype
	blesstype
	reftype
	stringrepr
	) ;

my %strings = map { $_ => 1 } @strings ;

sub typemap {
	my @rv = map { $typemap{ typeis( $_ ) } || '' } @_ ;
	return wantarray? @rv: $rv[0] ;
	}

sub new {
	my $package = shift ;
	my $self = {} ;

	$self->{key} = shift ;
	$self->{xml} = shift ;
	my $parent = shift ;
	my $globals = shift ;

	$self->{parenttype} = $parent->[0] ;
	$self->{parentid} = $parent->[1]->getattributes->{memory_address}
			|| $parent->[0] || $self->{key} ;

	my $attribs = $self->{xml}->getattributes ;

	$self->{sql} = { %$globals } ;
	my @strings = ( $self ) ;
	my @text = $self->{xml}->gettext ;

## Needs to be a reliable detection of legitimate XML data
#	if ( grep $_ eq $self->{key}, qw( item string scalar scalarref ) ) {
	if ( @text == 1 ) {
		my $sv = $text[0] ;
		my $svtype = typemap( $text[0] ) ;
	
		if ( $svtype eq 'stringdata' ) {
			my @buff = stringsplit( $text[0] ) ;
			$self->{sql}->{$svtype} = shift @buff ;
	
			push @strings, map { stringfactory( $self,
					reftype => 'string',
					defined => 1,
					$svtype => $_,
					%$globals ) } @buff ;
			}
		elsif ( $svtype ) {
			$self->{sql}->{$svtype} = $text[0] ;
			}
		else {
			push @nok, $text[0] ;
			}
	
		my $text = $self->{xml}->gettext ;
		$text =~ s/'/\\'/sg ;
		$self->{sql}->{stringrepr} = $text ;
		}

	$self->{sql}->{reftype} = $self->{key} ;
	$self->{sql}->{blesstype} = $attribs->{blessed_package}
			if $attribs->{blessed_package} ;

	$self->{sql}->{textkey} = $attribs->{key}
			if ! exists $self->{sql}->{textkey}
			&& exists $attribs->{key}
			&& $self->{parenttype} eq 'hashref' ;
	$self->{sql}->{intkey} = $attribs->{key}
			if ! exists $self->{sql}->{intkey}
			&& exists $attribs->{key}
			&& $self->{parenttype} eq 'arrayref' ;
	$self->{sql}->{defined} = ! ( exists $attribs->{defined} 
			&& $attribs->{defined} eq 'false' ) ;
	
	map { bless $_, $package } @strings ;
	return reverse @strings ;
	}

sub stringsplit {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $text = shift ;

	my @buff = () ;
	push @buff, $1 while $text =~ s/^(.{512})//s ;
	push @buff, $text if length $text ;
	return @buff? @buff: ('') ;
	}

sub stringfactory {
	my $self = shift ;
	my $out = { key => 'string', xml => $self->{xml}, sql => { @_ } } ;
	return bless $out, ref $self ;
	}

sub reference {
	my $self = shift ;
	my $sql = shift ;

	map { $self->{sql}->{$_} = $sql->{$_} } 
			qw( blesstype reftype )
			if ref $sql ;
	return $self->{sql}->{reftype} ;
	}

sub memory {
	my $self = shift ;
	return undef unless $self->{xml} ;
	return $self->{xml}->getattributes->{memory_address} ;
	}

sub parentid {
	my $self = shift ;
	return 'string' if exists $self->{key} && $self->{key} eq 'string' ;
	return $self->{combine}?
			$self->{combine}->{parentid}:
			$self->{parentid} ;
	}

sub sql {
	my $self = shift ;
	my $dsn = shift ;

	return warn unless $dsn ;

	my $combine = exists $self->{combine}?
			$self->{combine}->{sql}: {} ;

	my @nvp = @_ ;
	push @nvp, map { $_ => exists $combine->{$_}? 
			$combine->{$_}:
			$self->{sql}->{$_}
			} keys %$combine, keys %{ $self->{sql} } ;

	my %nvp = @nvp ;
	$nvp{reftype} = $self->{sql}->{reftype}
			if exists $self->{sql}->{reftype} ;
	my $id = exists $nvp{id}? $nvp{id}: undef ;

	@nvp = %nvp ;
	my @nvpargs = () ;
	push @nvpargs, [ splice @nvp, 0, 2 ] while @nvp ;
	map { push @$_, $strings{ $_->[0] } || 0 } @nvpargs ;

	my $results = $dsn->update( $id, @nvpargs ) ;
	$self->{sql}->{id} = $results->{id} ;
	return $results->{sqlresults} ;
	}

sub combine {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my @records = @_ ;
	my @out = () ;

	while ( @records ) {
		push @out, shift @records ;

		last unless @records ;
		next unless $records[0]{key} eq 'item' ;

		my @gd = $records[0]{xml}->getdata ;
		next unless @gd ;
		die if @gd > 1 ;
		
		$out[-1]{combine} = shift @records ;
		}

	return @out ;
	}

sub insertall {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $dsn = shift ;
	my %ids = () ;
	my %refs = () ;
	my %scalars = () ;

	foreach my $self ( @_ ) {
		my $pid = $self->parentid || '' ;

		if ( $self->memory && exists $refs{ $self->memory } ) {
			$self->{key} = $self->reference( 
					$refs{ $self->memory } 
					) ;
			}
		$self->{key} ||= '' ;
				
		$self->{sql}->{refto} ||= $ids{ $self->memory } 
				|| $scalars{ $self->memory }
				|| 0 if $self->memory ;

		$self->{sql}->{item} = $ids{ $pid } || 0
				if exists $ids{ $pid } 
				  && $self->{key}
				  && $self->{key} ne 'string'
				  && $self->{key} ne 'scalar' ;

		if ( $self->{key} eq 'perldata' ) {
			$self->{sql}->{intdata} = 0 ;
			$self->{sql}->{deleted} = 0 ;
			$self->{sql}->{refto} = delete $self->{sql}->{item} ;
			}

		$self->{sql}->{chainedstring} = $ids{string}
				if exists $self->{sql}->{stringdata} ;

		$self->sql( $dsn ) ;
	
		$scalars{ $self->memory } ||= $self->{sql}->{id} 
				if $self->memory
				&& $self->{key} eq 'scalarref' ;
		$ids{string} = undef unless $self->{key} eq 'string' ;
		$ids{ $pid } = $self->{sql}->{id} ;
		$refs{ $self->memory } = $self->{sql} if $self->memory ;
		}

	return $dsn->lastinsertid, \%refs ;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::Node - Private Perl extension for NoSQL::PL2SQL

=head1 SYNOPSIS

The NoSQL::PL2SQL::Node package is private.  None of its methods or functions are part of the public interface.

  use NoSQL::PL2SQL::Node ;

  ## Functions with external callers

  my $recordid = NoSQL::PL2SQL::Node->factory( $dsn, $obj ) ;
  my $recordid = NoSQL::PL2SQL::Node->factory( $dsn, $objectid, $obj ) ;
  my $recordid = NoSQL::PL2SQL::Node->factory( $dsn, $objectid, $obj ) ;

  my @nodes = NoSQL::PL2SQL::Node->factory( undef, $objectid, $obj ) ;

  my @combined = combine( @nodes ) ;
  my( $lastrecno, $refs ) = insertall( $dsn, @combined ) ;

  my $datatype = typemap( $scalar ) ;


  ## Functions with only internal callers

  my @nodes = xml2sql( XML::Parser::Nodes->pl2xml( $o ), $globals = {} ) ;

  my $node = NoSQL::PL2SQL::Node->new( $xmlnodekey, $xmlnode,
		[ $parentxmlnodekey, $parentxmlnode ], $globals = {} ) ;

  my @text = stringsplit( $text ) ;

  my $node = $nodes[0]->stringfactory( %nvp_args ) ;

  my $reftype = $nodes[0]->reference( $refsource_sql ) ;

  my $ref = $nodes[0]->memory() ;

  my $parentid = $nodes[0]->parentid() ;

  my $sql = $nodes[0]->sql( $dsn ) ;


=head1 DESCRIPTION

The following sequence of operation describes how NoSQL::PL2SQL::Node objects are used and when their methods are called:

1. An object that implements NoSQL::PL2SQL starts out as an ordinary PL type complex data structure.  That object is converted into a tree of NoSQL::PL2SQL::Node objects and written into an RDB table; each node correlates to a table record.  NoSQL::PL2SQL::Node represents the PL -> SQL phase.

2. During the next metamorphosis, the node records are read from the RDB table and converted to NoSQL::PL2SQL::Object nodes.  When these nodes are tied, the result is indistinguishable from the original object.  NoSQL::PL2SQL::Object represents the SQL -> PL phase.

3. After the object has been modified, some of the tree nodes are NoSQL::PL2SQL::Object's and others are untied vanilla PL data structures.  When DESTROYed, the PL data elements are converted piecemeal into NoSQL::PL2SQL::Node's and written with the other records until the next iteration.

Phase 1 operation is executed with a single call to the factory method:  First, the object is converted into a XML::Parser::Nodes tree using C<< XML::Parser::Nodes->pl2xml() >>.  Each node in this tree is converted using the C<xml2sql()> function, which calls the C<new()> constructor after recursing through the child nodes.  (Consquently, the top node is last.)

The resulting set of nodes is passed through the C<combine()> function.  C<< XML::Parser::Nodes->pl2xml() >> creates an extra data node for every container node.  C<combine()> combines these two nodes and returns a smaller set, which are passed into C<insertall()>.  C<insertall()> does the hard work of converting child pointers into RDB references, as it calls the C<sql()> method of each Node.

During the Phase 1 operation, C<insertall()> encapsulates all the complexity required to link the nodes.  During the Phase 3 operation, C<insertall()> is run separately for each untied PL element, and needs to accomodate existing links.  The process for determining those link values is encapsulated within the NoSQL::PL2SQL::Object package instead.

In phase 3, C<factory()> only performs the first step of converting a PL element into a set of Nodes.  The <combine()> and <insertall()> functions are called externally, and some of C<insertall()>'s internal data is passed back to the caller.

C<stringsplit()> and C<stringfactory()> are called by the C<new()> constructor.   The C<stringsplit()> function splits arbitrary string $text into contingent 512 character substrings, or smaller.  The C<stringfactory()> method returns a new Node object by cloning the XML member.  The new object's SQL member is defined by the %nvp_args.

C<reference()>, C<memory()> and C<parentid()> are called by C<insertall()> to access a Node's internal properties.

A PL2SQL object may contain internal references- essentially, a child node is shared among several contaner nodes.  (Scalar references are a bit more complex.)  The C<reference()> performs a little extra houskeeping to ensure consistency.

The C<memory()> method returns the XML memory_address attribute, which indicates shared references.

The C<parentid()> method returns one of a variety of attributes to determine nodes that are siblings.

Each Node has an sql and an xml member.  The sql member is an associative array that matches the data structure of an RDB table record.  The xml member is an internal pointer to an XML::Parser::Nodes structure.

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

Fixed bug: C<stringsplit()> converted 0 length strings to undefined

=item 0.04	

Fixed bug: C<insertall()> updating deleted records broke scalar chains

=item 0.05	

C<insertall()> more durable approach for 0.04

=item 0.06	

C<insertall()> initializes the I<deleted> and I<intdata> properties of the header node sql record.

=item 0.07	

Added %scalars to C<insertall()> method.  Needs to be separate from the 
%refs set.

=back

=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item NoSQL::PL2SQL::DBI

=item XML::Parser::Node

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
