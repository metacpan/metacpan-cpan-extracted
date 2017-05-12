package NoSQL::PL2SQL::Perldata ;

use 5.008009;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL::Perldata ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '0.03';


# Preloaded methods go here.

sub refto {
	my $self = shift ;
	my $key = shift ;
	my $o = $self->{$key} ;

	my $refto = $o->{refto} ;
	return $refto? refto( $self, $refto ) || $refto: '' ;
	}

sub lastitem {
	my $self = shift ;
	my $key = shift ;
	my $o = $self->{$key} ;
	return [ refto => $key ] unless $o->{refto} ;

	my $ii = $key ;
	for ( my $i = $o->{refto} ; $i ; $i = $self->{ $i }->{item} ) {
		$ii = $i ;
		}

	return [ item => $ii ] ;
	}

sub descendants {
	my $self = shift ;
	my $key = shift ;
	my $o = $self->{$key} ;

	my $nosiblings = shift ;
	my @out = () ;

	push @out, descendants( $self, $o->{item} ) 
			if $o->{item} && ! $nosiblings ;
	push @out, descendants( $self, $o->{refto} )
			if $o->{refto} && $o->{reftype} ne 'scalarref' ;
	return ( @out, $key ) ;
	}

sub fetchextract {
	my $sqlobject = shift ;
	my $self = $sqlobject->{perldata} ;
	my $key = shift ;
	my @nvpflag = @_ ;
	my $o = $self->{$key} ;
	my @out = () ;
	my $out ;

	@out = fetchextract( $sqlobject, $o->{item}, @nvpflag ) 
			if $o->{item} ;
	my @inner = () ;

	return @out if $o->{deleted} ;
	my $item = item( $self, $o ) ;

	if ( grep $item->[0] eq $_, qw( item scalar ) ) {
		$out = bless { data => $item->[1], 
				top => $key, 
				reftype => 'item' }, $sqlobject->package ;
		map { $out->{$_} = $sqlobject->{$_} }
				@NoSQL::PL2SQL::members ;
		return @out, ( @nvpflag? $o->{ $nvpflag[0] }: () ), $out ;
		}
	elsif ( $item->[0] eq 'hashref' ) {
		tie my( %out ), $sqlobject, $key ;
		$out = \%out ;
		}
	elsif ( $item->[0] eq 'arrayref' ) {
		tie my( @out ), $sqlobject, $key ;
		$out = \@out ;
		}
	elsif ( $item->[0] eq 'scalarref' ) {
		tie my( $refout ), $sqlobject, $key, $item->[1] ;
		$out = \$refout ;
		}
	else {
		## Never supposed to hit this
		warn "Unknown: " .$key ;
		}

	bless $out, $o->{blesstype} if $o->{blesstype} ;
	return @out, ( @nvpflag? $o->{ $nvpflag[0] }: () ), $out ;
	}

sub item {
	my $self = shift ;
	my $o = shift ;

	$o = $self->{$o} unless ref $o ;

	return [ item => undef ] unless $o->{defined} ;

	return [ $o->{reftype}, undef ] unless 
			grep $_ eq $o->{reftype}, 
			  qw( item scalar scalarref string ) ;

	my $rv = [ $o->{reftype} ] ;
	$rv->[1] = $o->{intdata} *1 if defined $o->{intdata} ;
	$rv->[1] = $o->{floatdata} *1.0 if defined $o->{floatdata} ;
	$rv->[1] = $o->{stringdata} if defined $o->{stringdata} ;
	warn $rv->[1] = $o->{stringrepr} if @$rv == 1 && ! $o->{refto} ;

	$rv->[1] .= item( $self, $o->{chainedstring} )->[1] 
			if defined $o->{stringdata} && $o->{chainedstring} ;
	return $rv ;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::Perldata - Private Perl extension for NoSQL::PL2SQL

=head1 SYNOPSIS

The NoSQL::PL2SQL::Perldata package is private.  None of its functions are part of the public interface.

  use NoSQL::PL2SQL::Perldata ;

  $perldata = $db->perldata( $SQL_SELECT_STATEMENT ) ;
  ## $perldata == $tied->{perldata} 
  ## where $tied is any NoSQL::PL2SQL::Object

  %children = fetchextract( $tied, $refto, 'textkey' )
or
  %children = fetchextract( $tied, $refto, 'intkey' ) ;

An object that implements NoSQL::PL2SQL is always represented as a tree.  All of PL2SQL's operations consider a object member as a tree node.  In most cases, the nodes are NoSQL::PL2SQL::Object's.  Before being written to the RDB, the nodes are NoSQL::PL2SQL::Node's.  Perldata is yet another way of representing the data as a tree of nodes.

"perldata" specifically refers to a member of an Object instantiation.  This member is a hash reference containing copies of the underlying RDB records.  By using Perldata functions, Object nodes can access the entire tree framework.

For example, when container Object nodes are loaded, C<fetchextract()> is used to create the child nodes.  The $tied argument is a NoSQL::PL2SQL::Object that represents a container node.  $refto is the pointer to the child list.  'textkey' is used for hash containers and 'intkey' is used for array containers.  The 'intkey' and 'textkey' values are embedded within the Perldata and returned as the keys in the output; empty NoSQL::PL2SQL::Object objects are returned as the values.

  $recno = lastitem( $perldata, $refto ) ;

The C<lastitem()> function is used to maintain linked lists.  The record number identifying the list head is passed, and the record number of the final element is returned.

  @recnos = descendants( $perldata, $recno, $nosiblings = 1 ) ;
  pop @recnos ;
or
  @recnos = descendants( $perldata, $refto ) ;

The C<descendants()> function is used to anticipate orphaned records when the overloaded CLEAR function is called on a NoSQL::PL2SQL::Object node.  $recno is always returned as the last element.  The first approach should be used if $recno refers to a parent container, the second if $refto refers to a child node.

  $array = item( $perldata, $recno ) ;
or
  $array = item( $perldata, $perldata->{$recno} ) ;

$perldata->{$recno} refers to a set of nvp's that contain the RDB table record.  The C<item()> function returns two elements that represent the underlying value of that record:  The first refers to the datatype determined by XML::Dumper::pl2xml: 'hashref', 'arrayref', 'item', 'scalarref', or 'scalar'.  'hashref' and 'arrayref' are container type nodes, and the others are scalars.  The second returned element is the actual value, which is meaningless for container types.


=head1 DESCRIPTION

The NoSQL::PL2SQL::Perldata object is the raw data from the RDB table.  

An object that implements NoSQL::PL2SQL starts out as a set of related records in an RDB table.  When the object is loaded, these records are read into a NoSQL::PL2SQL::Perldata data structure; and the top node is returned as a tied NoSQL::PL2SQL::Object.  Gradually, a tree of NoSQL::PL2SQL::Objects is built up as elements of the object are accessed; using data from the underlying NoSQL::PL2SQL::Perldata object.

As of v1.0, all of the RDB table records are slurped at once, and stored in this NoSQL::PL2SQL::Perldata object.  The name perldata refers to the reftype that XML::Dumper::pl2xml assigns to the top node.  Since the resulting object is always maintained in this tree structure accessible through the top node, the name perldata has poetic significance.

Each NoSQL::PL2SQL::Object element contains a reference to a common Perldata member to access the RDB table data.  Many NoSQL::PL2SQL::Object methods are applied by traversing the child and/or sibling nodes in this data set instead of relying on the NoSQL::PL2SQL::Object tree. 

As of v1.0, the data set is never actually blessed, based on a decision that now seems rather silly.

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

C<lastitem()> returns an nvp

=back



=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item NoSQL::PL2SQL::Object

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
