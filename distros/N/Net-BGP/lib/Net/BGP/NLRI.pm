#!/usr/bin/perl

package Net::BGP::NLRI;

use strict;
use Exporter;
use vars qw(
    $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @ORIGIN
    @BGP_PATH_ATTR_COUNTS
);

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.16';

## Module Imports ##

use Carp;
use IO::Socket;
use overload
	'<=>'  => \&_compare,
	'<'  => \&_lessthen,
	'>'  => \&_greaterthen,
	'==' => \&_equal,
	'!=' => \&_notequal,
	'eq' => \&_same,
	'ne' => sub { return ! &_same(@_) },
	'""' => sub { return shift; }; # Do nothing! Use asstring instead!
use Net::BGP::ASPath;

## BGP Path Attribute Count Vector ##

@BGP_PATH_ATTR_COUNTS = ( 0, 0, 0, 0, 0, 0, 0, 0, 0 );

## BGP ORIGIN Path Attribute Type Enumerations ##

sub IGP        { 0 }
sub EGP        { 1 }
sub INCOMPLETE { 2 }

my @ORIGINSTR = (
	'i', # IGP
	'e', # EGP
	'?'  # INCOMPLETE
	);

## Export Tag Definitions ##

@ORIGIN      = qw( IGP EGP INCOMPLETE );
@EXPORT      = ();
@EXPORT_OK   = ( @ORIGIN );
%EXPORT_TAGS = (
    origin => [ @ORIGIN ],
    ALL    => [ @EXPORT, @EXPORT_OK ]
);

## Public Class Methods ##

sub new
{
    my $class = shift();
    my ($arg, $value);

    my $this = {
        _as_path        => Net::BGP::ASPath->new,
        _origin         => IGP,
        _next_hop       => undef,
        _med            => undef,
        _local_pref     => undef,
        _atomic_agg     => undef,
        _aggregator     => [],
        _as4_aggregator => [],
        _communities    => [],
        _attr_mask      => [ @BGP_PATH_ATTR_COUNTS ]
    };

    bless($this, $class);

    while ( defined($arg = shift()) ) {
        $value = shift();

        if ( $arg =~ /aspath/i ) {
            $this->{_as_path} = ref $value eq 'Net::BGP::ASPath' ? $value : Net::BGP::ASPath->new($value);
        }
        elsif ( $arg =~ /origin/i ) {
            $this->{_origin} = $value;
        }
        elsif ( $arg =~ /nexthop/i ) {
            $this->{_next_hop} = $value;
        }
        elsif ( $arg =~ /med/i ) {
            $this->{_med} = $value;
        }
        elsif ( $arg =~ /localpref/i ) {
            $this->{_local_pref} = $value;
        }
        elsif ( $arg =~ /atomicaggregate/i ) {
            $this->{_atomic_agg} = $value;
        }
        elsif ( $arg =~ /aggregator/i ) {
            $this->{_aggregator} = $value;
        }
        elsif ( $arg =~ /communities/i ) {
            $this->{_communities} = $value;
        }
        else {
            croak("unrecognized argument $arg\n");
        }
    }

    return ( $this );
}

sub clone
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    $proto = shift unless ref $proto;

    my $clone = {};

    foreach my $key (qw(_origin _next_hop _med _local_pref _atomic_agg  ))
     {
      $clone->{$key} = $proto->{$key};
     }

    foreach my $key (qw(_aggregator _communities _attr_mask _as4_aggregator))
     {
      $clone->{$key} = [ @{$proto->{$key}}];
     }

    $clone->{_as_path} = defined $proto->{_as_path} ? $proto->{_as_path}->clone : undef;

    return ( bless($clone, $class) );
}

## Public Object Methods ##

sub aggregator
{
    my $this = shift();

    $this->{_aggregator} = @_ ? shift() : $this->{_aggregator};
    return ( $this->{_aggregator} );
}

sub as_path
{
    my $this = shift();

    $this->{_as_path} = @_ ? (ref $_[0] eq 'Net::BGP::ASPath' ? shift : Net::BGP::ASPath->new(shift)) : $this->{_as_path};
    return $this->{_as_path};
}

sub atomic_aggregate
{
    my $this = shift();

    $this->{_atomic_agg} = @_ ? shift() : $this->{_atomic_agg};
    return ( $this->{_atomic_agg} );
}

sub communities
{
    my $this = shift();

    $this->{_communities} = @_ ? shift() : $this->{_communities};
    return ( $this->{_communities} );
}

sub local_pref
{
    my $this = shift();

    $this->{_local_pref} = @_ ? shift() : $this->{_local_pref};
    return ( $this->{_local_pref} );
}

sub med
{
    my $this = shift();

    $this->{_med} = @_ ? shift() : $this->{_med};
    return ( $this->{_med} );
}

sub next_hop
{
    my $this = shift();

    $this->{_next_hop} = @_ ? shift() : $this->{_next_hop};
    return ( $this->{_next_hop} );
}

sub origin
{
    my $this = shift();

    $this->{_origin} = @_ ? shift() : $this->{_origin};
    return ( $this->{_origin} );
}

sub asstring
{
    my $this = shift();
    return join("\t", map { defined $_ ? $_ : 'n/a'; }
	$this->next_hop, $this->med, $this->local_pref,
	((defined $this->as_path) ? $this->as_path : '') .
	' ' . 
	((defined $this->origin) ? $ORIGINSTR[$this->origin] : 'n/a')
	);
}

## Private Object Methods ##

sub _same
{
 my ($this,$other) = @_;

 return 0 unless defined $other;
 return 0 unless $other->isa('Net::BGP::NLRI');

 my %union;
 @{\%union}{keys %{$this}} = 1;
 @{\%union}{keys %{$other}} = 1;
 foreach my $key (keys %union)
  {
    return 0 unless $this->_same_field($other,$key);
  };

 return 1;
}

sub _same_field
{
 my ($this,$other,$key) = @_;
 my $x = $this->{$key};
 my $y = $other->{$key};
 return 0 if defined $x != defined $y;
 return 0 if ref $x ne ref $y;
 return 1 unless defined $x; # Both undefined - Equal!
 if ((! ref $x)
  || (ref $x eq 'Net::BGP::ASPath'))
  {
   return 0 unless $x eq $y;
  }
 elsif (ref $x eq 'ARRAY')
  {
   return 0 unless scalar @{$x} == scalar @{$y};
   my @x = sort @{$x};
   my @y = sort @{$y};
   foreach my $i (0 .. (scalar @{$x} - 1))
    {
     return 0 unless $x[$i] eq $y[$i];
    }
  }
 else
  {
   croak 'Object contains unknown value type (' . (ref $x) . ") in áttribute ($key) in comparison";
  };
 return 1;
}

sub _equal
{
 my ($this,$other) = @_;
 return 0 unless defined($other);
 return ($this->_compare($other) == 0) ? 1 : 0;
}

sub _notequal
{
 my ($this,$other) = @_;
 return 1 unless defined($other);
 return ($this->_compare($other) == 0) ? 0 : 1;
}

sub _lessthen
{
 my ($this,$other) = @_;
 return ($this->_compare($other) == -1) ? 1 : 0;
}

sub _greaterthen
{
 my ($this,$other) = @_;
 return ($this->_compare($other) == 1) ? 1 : 0;
}

sub _ifundef
{
 my ($this,$field,$default) = @_;
 return defined($this->{$field}) ? $this->{$field} : $default;
}

sub _compare
{
 my ($this,$other) = @_;
 my $res;

 confess "compare with undef not possible" unless defined($other);
 confess "compare with invalidt object type" unless $other->isa('Net::BGP::NLRI');

 # If the path specifies a next hop that is inaccessible, drop the update.
 #   - NOT IMPLEMENTED

 # Prefer the path with the largest weight.
 #   - LOCAL ATTRIBUTE - Not part of BGP - PRODUCT SPECIFIC
 # $res = $this->{'_weight'} <=> $other->{'_weight'};
 # return $res unless $res == 0;

 # Prefer the path with the largest local preference.
 $res = $other->_ifundef('_local_pref',100) <=> $this->_ifundef('_local_pref',100);
 return $res unless $res == 0;

 # Prefer the path that was originated by BGP running on this router.
 #    - NOT IMPLEMENTED

 # Prefer the route that has the shortest AS_path.
 $res = $this->{_as_path} <=> $other->{_as_path};
 return $res unless $res == 0;

 # Prefer the path with the lowest origin type (where IGP is lower than EGP,
 # and EGP is lower than Incomplete).
 $res = $this->{'_origin'} <=> $other->{'_origin'};
 return $res unless $res == 0;

 # Prefer the path with the lowest MED attribute.
 $res = $this->_ifundef('_med',0) <=> $other->_ifundef('_med',0);
 return $res unless $res == 0;

 # Prefer the external path over the internal path.
 #    - NOT IMPLEMENTED

 # If the paths are still the same, prefer the path through the closest IGP
 # neighbor.
 #    - NOT IMPLEMENTED

 return 0;
}


## POD ##

=pod

=head1 NAME

Net::BGP::NLRI - Class encapsulating BGP-4 NLRI information

=head1 SYNOPSIS

    use Net::BGP::NLRI qw( :origin );

    # Constructor
    $nlri = Net::BGP::NLRI->new(
        Aggregator      => [ 64512, '10.0.0.1' ],
        AtomicAggregate => 1,
        AsPath          => Net::BGP::ASPath->new("64512 64513 64514"),
        Communities     => [ qw( 64512:10000 64512:10001 ) ],
        LocalPref       => 100,
        MED             => 200,
        NextHop         => '10.0.0.1',
        Origin          => INCOMPLETE,
    );

    # Object Copy
    $clone = $nlri->clone();

    # Accessor Methods
    $aggregator_ref   = $nlri->aggregator($aggregator_ref);
    $atomic_aggregate = $nlri->atomic_aggregate($atomic_aggregate);
    $as_path          = $nlri->as_path($as_path);
    $communities_ref  = $nlri->communities($communities_ref);
    $local_pref       = $nlri->local_pref($local_pref);
    $med              = $nlri->med($med);
    $next_hop         = $nlri->next_hop($next_hop);
    $origin           = $nlri->origin($origin);
    $string           = $nlri->asstring;

    # Preference comparisons
    if ($nlri1  < $nlri2) { ... };
    if ($nlri1  > $nlri2) { ... };
    if ($nlri1 == $nlri2) { ... };
    if ($nlri1 != $nlri2) { ... };
    @sorted = sort { $a <=> $b } ($nlri1, $nlri2, $nlri3, ... );

    # Comparison
    if ($nlri1 eq $nlri2) { ... };
    if ($nlri1 ne $nlri2) { ... };

=head1 DESCRIPTION

This module encapsulates the data used by BGP-4 to represent network
reachability information.  It provides a constructor, and accessor
methods for each of the well-known path attributes. An BGP-4 UPDATE
message includes this information along with a list of networks for
which the information should be used (and a list of network no longer
accessible). See B<Net::BGP::Update> for more infomration.

=head1 CONSTRUCTOR

I<new()> - create a new Net::BGP::NLRI object

    $nlri = Net::BGP::NLRI->new(
        Aggregator      => [ 64512, '10.0.0.1' ],
        AsPath          => Net::BGP::ASPath->new("64512 64513 64514"),
        AtomicAggregate => 1,
        Communities     => [ qw( 64512:10000 64512:10001 ) ],
        LocalPref       => 100,
        MED             => 200,
        NextHop         => '10.0.0.1',
        Origin          => INCOMPLETE,
    );

This is the constructor for Net::BGP::NLRI objects. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor. See RFC 1771 for the semantics of each
path attribute.

=head2 Aggregator

This parameter corresponds to the AGGREGATOR path attribute. It is expressed
as an array reference, the first element of which is the AS number (in the
range of an 16-bit unsigned integer) of the route aggregator, and the second
element is the aggregator's IP address expressed in dotted-decimal notation
as a string. It may be omitted, in which case no AGGREGATOR path attribute
will be attached to the UPDATE message.

=head2 AsPath

This parameter corresponds to the AS_PATH path attribute. The AS_PATH is
expressed as an B<Net::BGP::ASPath> object. If expressed otherwise, a
Net::BGP::ASPath object is tried constructed using the argument.

=head2 AtomicAggregate

This parameter corresponds to the ATOMIC_AGGREGATE path attribute. It is
a boolean value so any value which perl interprets as true/false may be
used. It may be omitted, in which case no ATOMIC_AGGREGATE path attribute
will be attached to the UPDATE message.

=head2 Communities

This parameter corresponds to the COMMUNITIES attribute defined in RFC 1997.
It is expressed as an array reference of communities which apply to the
route(s). The communities are encoded in a special format: AAAA:CCCC, where
AAAA corresponds to the 16-bit unsigned integer AS number, and CCCC is
a 16-bit unsigned integer of arbitrary value. But see RFC 1997 for the
semantics of several reserved community values. This attribute may be
omitted, in which case no COMMUNITIES attribute will be attached to the
UPDATE message.

=head2 LocalPref

This parameter corresponds to the LOCAL_PREF path attribute. It is expressed
as a 32-bit unsigned integer scalar value. It may be omitted, in which case
no LOCAL_PREF path attribute will be attached to the UPDATE message.

=head2 MED

This parameter corresponds to the MULTI_EXIT_DISC path attribute. It is expressed
as a 32-bit unsigned integer scalar value. It may be omitted, in which case
no MULTI_EXIT_DISC path attribute will be attached to the UPDATE message.

=head2 NextHop

This parameter corresponds to the NEXT_HOP path attribute. It is expressed as a
dotted-decimal IP address as a perl string. This path attribute is mandatory and
the parameter must always be provided to the constructor.

=head2 Origin

This parameter corresponds to the ORIGIN path attribute. It is expressed as an
integer scalar value, which can take the following enumerated values: IGP, EGP,
or INCOMPLETE. The preceding symbols can be imported into the program namespace
individually or by the :origin export tag. This path attribute is mandatory and
the parameter must always be provided to the constructor.

=head1 OBJECT COPY

I<clone()> - clone a Net::BGP::NLRI object

    $clone = $nlri->clone();

This method creates an exact copy of the Net::BGP::NLRI object with Path
Attributes fields matching those of the original object.

=head1 ACCESSOR METHODS

I<aggregator()>

I<as_path()>

I<atomic_aggregate()>

I<communities()>

I<local_pref()>

I<med()>

I<next_hop()>

I<origin()>

These accessor methods return the value(s) of the associated path attribute fields
if called with no arguments. If called with arguments, they set
the associated field. The representation of parameters and return values is the
same as described for the corresponding named constructor parameters above.

I<asstring()>

This accessor method returns a print-friendly string with some, but not all,
of the information containted in the object.

=head1 EXPORTS

The module exports the following symbols according to the rules and
conventions of the B<Exporter> module.

:origin
    IGP, EGP, INCOMPLETE

=head1 SEE ALSO

B<RFC 1771>, B<RFC 1997>, B<Net::BGP>, B<Net::BGP::Process>, B<Net::BGP::Peer>,
B<Net::BGP::Notification>, B<Net::BGP::ASPath>, B<Net::BGP::Update>

=head1 AUTHOR

Stephen J. Scheck <code@neurosphere.com>

=cut

## End Package Net::BGP::NLRI ##

1;
