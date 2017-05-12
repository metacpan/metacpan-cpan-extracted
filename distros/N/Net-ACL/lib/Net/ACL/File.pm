#!/usr/bin/perl

# $Id: File.pm,v 1.13 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL;
use Net::ACL::Rule qw( :rc :action );
use Carp;
use Cisco::Reconfig;

## Private Global Class Variables ##

my %listtypes;

## Public Class Methods ##

sub add_listtype
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 my ($type,$aclclass,$match,$use) = @_;
 $use ||= $aclclass;
 $match ||= $type;
 unless ($aclclass->isa('Net::ACL::File::Standard'))
  {
   eval "use $use;";
   croak "Error adding $match ($type) - Can't locate $use module." if ($@ =~ /Can't locate/); 
   croak $@ if ($@);
   croak "$aclclass is not a Net::ACL::File::Standard class"
	unless ($aclclass->isa('Net::ACL::File::Standard'))
  };
 $listtypes{$match}->{_class} = $aclclass;
 $listtypes{$match}->{_type} = $type;
}

sub load
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 my $obj = shift;
 unless ((ref $obj) && $obj->isa('Cisco::Reconfig'))
  {
   $obj = Cisco::Reconfig::stringconfig($obj);
   croak "Unable to load configuration data" unless $obj;
  };

 my $res;

 foreach my $match (sort keys %listtypes)
  {
   my $aclclass = $listtypes{$match}->{_class};
   my $lists = $obj->get($match);
   foreach my $list ($lists->single ? $lists : $lists->all) # Was get not all
    {
     next if $list->text eq '';
     my $acl = $aclclass->load($list);
     next unless defined $acl->name; # No list name - no list at all!
     $acl->type($listtypes{$match}->{_type});
     $res->{$acl->type}->{$acl->name} = $acl;
    }
  };

 return $res;
}

## Public Object Methods ##

sub asconfig
{
 my $this = shift;
 my $class = ref $this || $this;
 $this = shift if $this eq $class;

 my $conf = '';
 croak 'ACL need name for configuration to be generated' unless defined $this->name;
 croak 'ACL need type for configuration to be generated' unless defined $this->type;
 foreach my $rule (@{$this->{_rules}})
  {
   croak "ACL rule of class " . (ref $rule) . " has no asconfig method!" unless $rule->can('asconfig');
   $conf .= $rule->asconfig($this->name,$this->type);
  };
 return $conf;
}

## POD ##

=pod

=head1 NAME

Net::ACL::File - Access-lists constructed from configuration file like syntax.

=head1 SYNOPSIS

    use Net::ACL::File;

    Net::ACL::File->add_listtype('community-list', __PACKAGE__,'ip community-list');

    # Construction
    $config = "ip community-list 4 permit 65001:1\n";
    $list_hr = load Net::ACL::File($config);

    $list = renew Net::ACL(Type => 'community-list', Name => 4);
    $config = $list->asconfig;

=head1 DESCRIPTION

This module extends the Net::ACL class with a load constructor that loads one
or more objects from a Cisco-like configuration file using Cisco::Reconfig.

=head1 CONSTRUCTOR

=over 4

=item load() - Load one or more Net::ACL objects from a configuration string.

    $list_hr = load Net::ACL::File($config);

This special constructor parses a Cisco-like router configuration.

The constructor takes one argument which should either be a string or a
Cisco::Reconfig object.

It returns a hash reference. The hash is indexed on
list-types. Currently supporting the following:

=over 4

=item C<community-list>

=item C<as-path-list>

=item C<prefix-list>

=item C<access-list>

=item C<route-map>

=back

Each list-type hash value contains a new hash reference indexed on list names
or numbers.

=back

=head1 CLASS METHODS

=over 4

=item add_listtype()

The add_listtype() class method registers a new class of access-lists.

The first argument is the type-string of the new class.
The second argument is the class to be registered. The class should be a
sub-class of Net::BGP::File::Standard. Normally this should be C<__PACKAGE__>.

The third argument is used to match the lines in the configuration file using
Cisco::Reconfig's get() method. If match argument is not defined,
the type string will be used.

The forth argument is used to load the class with a "use" statement. This
should only be needed if the class is located in a different package.
Default is the class name from the second argument.

=back

=head1 ACCESSOR METHODS

=over 4

=item asconfig()

This function tries to generate a configuration matching the one the load
constructer got. It can read from any access-list. The resulting configuration
is returned as a string.

All ACL's which rules support the I<asconfig> method may be used. To do so,
use:

	$conf = Net::ACL::File->asconfig($acl);

=back

=head1 SEE ALSO

Net::ACL, Cisco::Reconfig, Net::ACL::File::Standard

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::File ##

1;
