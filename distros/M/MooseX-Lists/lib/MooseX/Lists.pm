# $Id: Lists.pm,v 1.12 2010/01/17 09:31:08 dk Exp $
package MooseX::Lists;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:KARASIK';

use strict;
use warnings;
use Carp;
use Moose ();
use Moose::Exporter;

sub ArrayRef
{
	my $next = shift;
	my $self = shift;
	if ( 1 == @_ and $_[0] and ref($_[0]) eq 'ARRAY') {
		return $self->$next(@_);
	} elsif ( @_ ) {
		return $self->$next(\@_);
	} else {
		my $r = $self-> $next;
		return wantarray ? ( $r ? @$r : ()) : $r;
	}
}

sub array_writer
{
	my $next = shift;
	my $self = shift;
	return $self->$next(\@_);
}

sub HashRef
{
	my $next = shift;
	my $self = shift;
	if ( 1 == @_ and $_[0] and ref($_[0]) eq 'HASH') {
		return $self->$next(@_);
	} elsif ( @_ ) {
		confess "Odd numbers ef elements in anonymous hash" if @_ % 2;
		return $self->$next({@_});
	} else {
		my $r = $self-> $next;
		return wantarray ? ( $r ? %$r : ()) : $r;
	}
}

sub hash_writer
{
	my $next = shift;
	my $self = shift;
	confess "Odd numbers ef elements in anonymous hash" if @_ % 2;
	return $self->$next({@_});
}

sub anon_hash  {{}}
sub anon_array {[]}

sub has_list
{
	my ( $meta, $name, %options ) = @_;

	my ( $accessor,$writer,$default);
	if ( defined $options{isa}) {
		if ( $options{isa} =~ /^ArrayRef/) {
			$accessor = \&ArrayRef;
			$writer   = \&array_writer;
			$default  = \&anon_array;
		} elsif ( $options{isa} =~ /^HashRef/) { 
			$accessor = \&HashRef;
			$writer   = \&hash_writer;
			$default  = \&anon_hash;
		} else {
			die "bad 'isa' option: must begin with either 'ArrayRef' or 'HashRef'";
		}
	} else {
		$accessor = \&ArrayRef;
		$writer   = \&array_writer;
		$default  = \&anon_array;
	}

	$options{default} = $default unless defined $options{default};

	$meta-> add_attribute($name, %options);

	return if defined $options{is} and $options{is} eq 'bare';

	# hook the accessors
	my @accessors = 
		grep { defined } map { $options{$_} } qw(reader accessor);
	@accessors = $name unless @accessors;
	$meta-> add_around_method_modifier( $_, $accessor) for @accessors;
	$meta-> add_around_method_modifier( $options{writer}, $writer)
		if $options{writer};
}

Moose::Exporter-> setup_import_methods(
      with_meta         => [ 'has_list' ],
);

1;

__DATA__

=pod

=head1 NAME

MooseX::Lists - treat arrays and hashes as lists

=head1 SYNOPSIS

   package Stuff;

   use Moose;
   use MooseX::Lists;

   has_list a => ( is => 'rw', isa => 'ArrayRef');
   has_list h => ( is => 'rw', isa => 'HashRef' );

   has_list same_as_a => ( is => 'rw' );

   ...

   my $s = Stuff-> new(
   	a => [1,2,3],
	h => { a => 1, b => 2 }
   );


=head2 Mixed list/scalar context

   has_list a => ( is => 'rw', isa => 'ArrayRef');
   has_list h => ( is => 'rw', isa => 'HashRef' );

   ...

   my @list   = $s-> a;     # ( 1 2 3 )
   my $scalar = $s-> a;     # [ 1 2 3 ]

   $s-> a(1,2,3);           # 1 2 3
   $s-> a([1,2,3]);         # 1 2 3
   $s-> a([]);              # empty array
   $s-> a([[]]);            # []

   my %list = $s-> h;       # ( a => 1, b => 2 )
   my $sc   = $s-> h;       # { a => 1, b => 2 }

   $s-> h(1,2,3,4);         # 1 2 3 4
   $s-> h({1,2,3,4});       # 1 2 3 4
   $s-> h({});              # empty hash

=head2 Separated list/scalar context

   has_list a => ( 
   	is  => 'rw', 
	isa => 'ArrayRef',
	writer  => 'wa',
	clearer => 'ca',
	);
   has_list h => ( 
   	is  => 'rw', 
	isa => 'HashRef',
	writer  => 'wh',
	clearer => 'ch',
	);

    ...

   # reading part is identical to the above

   $s-> wa(1,2,3);          # 1 2 3
   $s-> wa([1,2,3]);        # [1 2 3]
   $s-> wa();               # empty array
   $s-> ca();               # empty array
   $s-> wa([]);             # []

   $s-> wh(1,2,3,4);        # 1 2 3 4
   $s-> wh({1,2,3,4});      # error, odd number of elements
   $s-> wh();               # empty hash
   $s-> ch();               # empty hash


=head1 DESCRIPTION

Provides asymmetric list access for arrays and hashes.

The problem this module tries to solve is to provide an acceptable API for
setting and accessing array and hash properties in list context.  The problem
in implementing such interface is when a handler accepts both arrays and
arrayrefs, how to set an empty array, and differentiate between a set-call with
an empty list or a get-call. Depending on the way a method is declared, two
different setting modes are proposed.

The first method, when C<writer> is not explictly set (default), tries
to deduce if it needs to dereference the arguments. It does so by checking
if the argument is an arrayref. This means that the only way to clear an
array or hash it to call it with C<[]> or C<{}>, respectively.

The second method is turned on if C<writer> was explicitly specified, which
means that if it is called with no arguments, this means an empty list.
This method never dereferences array- and hashrefs.

=head1 METHODS

=over

=item has_list

Replacement for C<has>, with exactly same syntax, expect for C<isa>, which must
begin either with C<ArrayRef> or C<HashRef>. If C<isa> is omitted, array 
is assumed.

When a method is declared with C<has_list>, internally it is a normal perl
array or hash. The method behaves differently if called in scalar or list
context.  See below for details.

=item ArrayRef

In get-mode, behaves like C<auto_deref>: in scalar context, returns direct
reference to the array; in the list context, returns defererenced array.

In set-mode without C<writer> specified, behaves asymmetrically: if passed one
argument, and this argument is an arrayref, treats it as an arrayref, otherwise
dereferences the arguments and creates a new arrayref, which is stored
internally.  I.e. the only way to clear the array is to call C<< ->method([]) >>.

In set-mode with C<writer> specified always treats input as a list.

=item HashRef

In get-mode, behaves like C<auto_deref>: in scalar context, returns direct
reference to the hash; in the list context, returns defereenced hash.

In set-mode without C<writer> specified behaves asymmetrically: if passed one
argument, and this argument is a hashref, treats it as a hashref, otherwise
dereferences the arguments and creates a new hashref, which is stored
internally.  I.e. the only way to clear the hash is to call C<< ->method({}) >>.

In set-mode with C<writer> specified always treats input as a list.

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 THANKS

Karen Etheridge, Jesse Luehrs, Stevan Little.

=cut
