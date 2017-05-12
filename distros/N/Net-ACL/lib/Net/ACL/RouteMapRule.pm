#!/usr/bin/perl

# $Id: RouteMapRule.pm,v 1.23 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::RouteMapRule;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @ACL_ROUTEMAP_INDEX );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Rule );
$VERSION = '0.07';

## Module Imports ##

use Carp;
use Net::ACL::Rule qw( :rc :action );
use Net::BGP::NLRI;

## Constants For Argument numbering ##

sub ACL_ROUTEMAP_PREFIX     { 0; };
sub ACL_ROUTEMAP_ROUTESRC   { 1; };
sub ACL_ROUTEMAP_COMMUNITY  { 2; };
sub ACL_ROUTEMAP_ASPATH     { 3; };
sub ACL_ROUTEMAP_NEXTHOP    { 4; };
sub ACL_ROUTEMAP_LOCALPREF  { 5; };
sub ACL_ROUTEMAP_MED        { 6; };
sub ACL_ROUTEMAP_ORIGIN     { 7; };
sub ACL_ROUTEMAP_ATOMICAGG  { 8; };
sub ACL_ROUTEMAP_AGGREGATOR { 9; };

my @FIELDNAMES = ( qw(  - - communities as_path next_hop local_pref
			med origin atomic_aggregate aggregator) ); 

@ACL_ROUTEMAP_INDEX = qw (
	ACL_ROUTEMAP_PREFIX ACL_ROUTEMAP_ROUTESRC
	ACL_ROUTEMAP_COMMUNITY ACL_ROUTEMAP_ASPATH ACL_ROUTEMAP_NEXTHOP
	ACL_ROUTEMAP_LOCALPREF ACL_ROUTEMAP_MED ACL_ROUTEMAP_ORIGIN
	ACL_ROUTEMAP_ATOMICAGG ACL_ROUTEMAP_AGGREGATOR
	);

## Export Tag Definitions ##

@EXPORT      = ();
@EXPORT_OK   = ( @ACL_ROUTEMAP_INDEX );
%EXPORT_TAGS = (
    index	=> [ @ACL_ROUTEMAP_INDEX ],
    ALL		=> [ @EXPORT, @EXPORT_OK ]
);

## Public Object Methods ##

sub autoconstruction
{
 my $this = shift;
 my $class = ref $this || $this;

 my ($type,$ruleclass,$arg,@values) = @_;
 if ( $arg =~ /aspath prepend (.*)$/i )
  {
   return $this->SUPER::autoconstruction($type,undef,'Add',ACL_ROUTEMAP_ASPATH,$1);
  }
 elsif ( $arg =~ /^community(.*)$/i )
  {
   my $data = $1;
   $data =~ s/^ //;
   if ($type eq 'Match')
    {
     my @l;
     push(@l,$data) if $data ne '';
     push(@l,@{$values[0]}) if ref $values[0] eq 'ARRAY';
     if ($l[0] =~ /:/) # Communities 
      {
       return $this->SUPER::autoconstruction($type,undef,'Member',ACL_ROUTEMAP_COMMUNITY,@l);
      };
     my @lists;
     foreach my $l (@l)
      {
       push(@lists,{ Name => $l, Type=> 'community-list' });
      };
     return $this->SUPER::autoconstruction($type,undef,'List',ACL_ROUTEMAP_COMMUNITY,@lists);
    }
   else
    {
     my $list = [ split(/ /,$data) ];
     $list = $values[0] if $data eq '';
     return $this->SUPER::autoconstruction($type,undef,'Union',ACL_ROUTEMAP_COMMUNITY,$list);
    };
  }
 elsif (($arg =~ /^ip (address|next-hop) ((?:prefix-list )|)(.*)$/)
     || ($arg =~ /^(prefix|next[ _-]?hop|routesource)/i) && ($type eq 'Match'))
  {
   my ($index,$ltype);
   if (defined $2)
    {
     $index = $1 eq 'address' ? ACL_ROUTEMAP_PREFIX : ACL_ROUTEMAP_NEXTHOP;
     $ltype = $2 eq '' ? 'access-list' : 'prefix-list';
     $values[0] = $3;
    }
   else
    {
     $index = $1;
     $ltype = $index =~ /prefix/i ? 'prefix-list' : 'access-list';
     $index =
	$index =~ /prefix/i ? ACL_ROUTEMAP_PREFIX :
	$index =~ /routesource/ ? ACL_ROUTEMAP_ROUTESRC : ACL_ROUTEMAP_NEXTHOP;
     @values = @{$values[0]} if ref $values[0] eq 'ARRAY';
    }
   my @lists;
   foreach my $list (split(/ /,$values[0]))
    {
     if ($list =~ /^\d{3}$/)
      {
       push(@lists,{Name=>$list,Type=>'extended-access-list'});
      }
     else
      {
       push(@lists,{Name=>$list,Type=>$ltype});
      };
    };
   return $this->SUPER::autoconstruction($type,undef,'List',$index,@lists);
  }
 elsif (($arg =~ /next[ _-]?hop/i ) && ($type eq 'Set'))
  {
   return $this->SUPER::autoconstruction($type,undef,'Scalar',ACL_ROUTEMAP_NEXTHOP,@values);
  }
 elsif ( $arg =~ /MED/i )
  {
   return $this->SUPER::autoconstruction($type,undef,'Scalar',ACL_ROUTEMAP_MED,@values);
  }
 elsif ( $arg =~ /local[ _-]?pref(?:erence)?(?: (\d+))?$/i )
  {
   my $val = $1 || $values[0];
   return $this->SUPER::autoconstruction($type,undef,'Scalar',ACL_ROUTEMAP_LOCALPREF,$val);
  }
 elsif (($arg =~ /as[ _-]?path(?: (.*))?$/i ) && ( $type eq 'Match'))
  {
   my @lists;
   my @l = defined $1 ? $1 : ref $values[0] eq 'ARRAY' ? @{$values[0]} : @values;
   foreach my $list (@l)
    {
     push(@lists,{Name=>$list,Type=>'as-path-list'});
    };
   return $this->SUPER::autoconstruction($type,undef,'List',ACL_ROUTEMAP_ASPATH,@lists);
  }
 elsif (($arg =~ /(?:as[ _-]?path)|(?:prepend)$/i ) && ($type eq 'Set'))
  {
   return $this->SUPER::autoconstruction($type,undef,'Add',ACL_ROUTEMAP_ASPATH,@values);
  }
 if ($ruleclass =~ / /)
  {
   croak "Unknown RouteMap construction key '$arg'";
  };
 return $this->SUPER::autoconstruction($type,$ruleclass,$arg,@values);
}

sub match
{
 my ($this,$prefix,$nlri,$peer) = @_;
 my $routesrc = '';
 $routesrc = $peer->peer_id if (ref $peer) && defined $peer->peer_id;
 return $this->SUPER::match($prefix,$routesrc,$this->_nlri2list($nlri));
}

sub query
{
 my ($this,$prefix,$nlri,$peer) = @_;
 my $routesrc = '';
 $routesrc = $peer->peer_id if (ref $peer) && defined $peer->peer_id;
 my ($rc,$newprefix,$newroutesrc,@res) =
	$this->SUPER::query($prefix,$routesrc,$this->_nlri2list($nlri));
 return ($rc,undef,undef,undef) if $rc eq ACL_DENY;
 croak 'Routemap is not allowed to change routesource'
	unless $routesrc eq $newroutesrc;
 return ($rc,$newprefix,$this->_list2nlri(@res),$peer);
}

## Private Object Methods ##

sub _nlri2list
{
 my ($this,$nlri) = @_;
 croak "Did't get an NLRI as argument" unless ref $nlri && $nlri->isa('Net::BGP::NLRI');
 my @arg = ();
 foreach my $field (@FIELDNAMES)
  {
   next if $field eq '-';
   push(@arg, $nlri->$field());
  };
 return @arg;
}

sub _list2nlri
{
 my ($this,@res) = @_;
 my $nlri = new Net::BGP::NLRI();
 foreach my $num (2 .. $#FIELDNAMES)
  {
   my $field = $FIELDNAMES[$num];
   $nlri->$field($res[$num-2]);
  };
 return $nlri;
}

## POD ##

=pod

=head1 NAME

Net::ACL::RouteMapRule - Class representing a BGP-4 policy route-map rule

=head1 SYNOPSIS

    use Net::ACL::RouteMapRule;

    # Constructor
    $rule = new Net::ACL::RouteMapRule(
	Action	=> ACL_PERMIT,
        Match	=> {
		ASPath		=> [ 'my-as-path-list' ],
		Community	=> [ 'my-community-list' ],
		Prefix		=> [ 'my-prefix-list' ],
		Next_hop	=> [ 'my-access-list' ],
		Routesource	=> [ 'my-access-list' ],
		MED		=> 20,
		Local_Pref	=> 200,
		Origin		=> IGP
		},
	Set	=> {
		ASPath		=> [ 65001, 65001 ],  # Prepend
		Community	=> [ qw( 65001:100 65001:200 ) ],
		Next_hop	=> '10.0.0.1',
		Local_Pref	=> 200,
		MED		=> 50,
		Origin		=> EGP,
		Weight		=> 42
		}
	);

    # Accessor Methods
    ($rc,$nlri) = $rule->query($prefix, $nlri);
    $rc = $rule->match($prefix, $nlri);

=head1 DESCRIPTION

This module represents a single route-map clause with a match part, a set part
and an action. This object is used by the
L<Net::ACL::RouteMap|Net::ACL::RouteMap> object. It inherits from
L<Net::ACL::Rule|Net::ACL::Rule>, with the only changed method being the
autoconstructor() method.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::RouteMapRule object

The method is inherited from the Net::ACL::Rule object. But since the
autoconstruction() method has been replaced, some extra named arguments below
Match and Set are understood:

=over 4

=item ASPath

When used in Match, the ASPath named argument should be a name of an ASPath
access-lists.

When used in Set, it should be the AS numbers that should be prepended. They
may be specified in anyway that the Net::BGP:ASPath->new() constructor allows
them.

=item Community

When used in Match, the Community named argument should be a community-list.

When used in Set, it should be a list of communities to set.

=item Prefix

The Prefix named argument can only be used under Match. It's value should be
a list of Net::ACL prefix-list names.

=item Next_hop

When used under Match, its value should be a list of names of access-lists.

When used under Set, its value should be an IP address.

=item Routesource

The Routesource named argument can only be used under Match. It's value should
be a list of Net::ACL access-list names.

=item Origin

The Origin named argument should have a value of either IGP, EGP or
INCOMPLETE, as exported by Net::BGP::NLRI C<:origin>.

=item Local_Pref

=item MED

=item Weight

The Local_Pref, MED and Weight named argument should have values of integers.

Weight can only be used in Set.

=back

=back

=head1 ACCESSOR METHODS

=over 4

=item query()

=item match()

The query() and match() methods take a Net::BGP::NLRI object as first argument
and a prefix as second, but does and return the same as the match() and query()
methods of the Net::ACL::Rule object.

=back

=head1 SEE ALSO

Net::ACL, Net::ACL::Rule, Net::ACL::RouteMap,
Net::BGP, Net::BGP::NLRI, Net::BGP::Router

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::RouteMapRule ##
 
1;
