#!/usr/bin/perl

# $Id: RouteMap.pm,v 1.18 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::RouteMapRule;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::RouteMapRule );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::RouteMapRule qw( :index );
use Carp;

## Public Object Methods ##

sub asconfig
{ # Don't check data - expect them to be constructed the right way!
 my $this = shift;
 my $name = shift;
 my $rules = '';

 # Add match rules
 foreach my $match (@{$this->{_match}})
  {
   if ($match->index == ACL_ROUTEMAP_ASPATH)
    {
     $rules .= "\n match as-path " . join(' ',$match->names);
    }
   elsif ($match->index == ACL_ROUTEMAP_COMMUNITY)
    {
     if ($match->isa('Net::ACL::Match::List'))
      {
       $rules .= "\n match community " . join(' ',$match->names);
      }
     else
      {
       $rules .= "\n match community " . $match->value;
      };
    }
   elsif ($match->index == ACL_ROUTEMAP_PREFIX)
    {
     my $type = $match->type eq 'prefix-list' ? 'prefix-list ' : '';
     $rules .= "\n match ip address $type" . join(' ',$match->names);
    }
   elsif ($match->index == ACL_ROUTEMAP_NEXTHOP)
    {
     $rules .= "\n match ip next-hop prefix-list " . join(' ',$match->names);
    }
   elsif ($match->index == ACL_ROUTEMAP_MED)
    {
     $rules .= "\n match metric " . $match->value;
    }
   else
    {
     carp "Unknown match index (" . $match->index . ") for Route-map match rule (" . (ref ($match->index)) . "). Cannot generate config line";
    }
  }

 # Add set rules
 foreach my $set (@{$this->{_set}})
  {
   if ($set->index == ACL_ROUTEMAP_ASPATH)
    {
     $rules .= "\n set aspath prepend " . $set->value;
    }
   elsif ($set->index == ACL_ROUTEMAP_COMMUNITY)
    {
     $rules .= "\n set community " . join(' ',@{$set->value});
    }
   elsif ($set->index == ACL_ROUTEMAP_MED)
    {
     $rules .= "\n set metric " . 
	($set->isa('Net::ACL::Set::Add') ? ($set->value < 0 ? '' : '+') : '') .
	$set->value;
    }
   elsif ($set->index == ACL_ROUTEMAP_LOCALPREF)
    {
     $rules .= "\n set local-preference " . $set->value;
    }
   else
    {
     carp "Unknown set index (" . $set->index . ") for Route-map set rule (" . (ref ($set->index)) . "). Cannot generate config line";
    }
  }

 my $seq = $this->seq;
 $seq = defined $seq ? " $seq" : '';
 
 # Put it all together and return!
 return "route-map $name " . $this->action_str . $seq . $rules . "\n";
}

## End of Net::ACL::File::RouteMapRule ##

package Net::ACL::File::RouteMap;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance ##

@ISA     = qw( Net::ACL::File::Standard );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File::Standard;
use Carp;

## Net::ACL::File Class Auto Registration Code ##

Net::ACL::File->add_listtype('route-map',__PACKAGE__,'route-map');

## Public Object Methods ##

my $z = 0;
sub loadmatch
{
 my ($this,$block,$super) = @_;

 $block = $super unless $block =~ /route-map/;

 # Get name and action!
 croak "Configuration header line format error in line: '$block'"
	unless $block =~ /route-map ([^ ]+) (permit|deny) ?([\d]*)$/;
 $this->name($1);
 my %arg = ( Action => $2, Seq => $3 );

 my $ii = 0;
 foreach my $entry1 ($block->subs->get)
  {
   next if $entry1->text eq '';
   foreach my $entry ($entry1 =~ /\n./ ? $entry1->get : $entry1)
    {
     croak "Configuration content line format error in line: '$entry'"
	unless $entry =~ /^ (set|match) (.*)$/i;
     my ($what,$data) = ($1,$2);
     $arg{$what}->{$data} = 1;
    };
  };
 my $rule = new Net::ACL::File::RouteMapRule(%arg);
 $this->add_rule($rule);
}

## POD ##

=pod

=head1 NAME

Net::ACL::File::RouteMap - BGP Route-Maps loaded from configuration string.

=head1 DESCRIPTION

This module extends the Net::ACL::File::Standard class to handle
community-lists. See Net::ACL::File::Standard for details.

=head1 SEE ALSO

Net::ACL, Net::ACL::File, Net::ACL::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::RouteMap ##

1;
