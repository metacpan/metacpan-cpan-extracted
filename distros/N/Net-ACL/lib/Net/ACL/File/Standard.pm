#!/usr/bin/perl

# $Id: Standard.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::File::Standard;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::File );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::File;
use Carp;

## Public Class Methods ##

sub load
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 my $config = shift;

 my $obj = $class->new;

 foreach my $rule ($config->get)
  {
   $obj->loadmatch($rule,$config);
  };

 return $obj;
}

## Public Object Methods ##

sub loadmatch
{
 my $this = shift;
 my $class = ref $this || $this;
 croak __PACKAGE__ . ' objects cannot do loadmatch!'
        if $class eq __PACKAGE__;

 croak "$class should reimplement the match method inhireted from __PACKAGE__";
};

## POD ##

=pod

=head1 NAME

Net::ACL::File::Standard - Standard access-lists loaded from configuration string.

=head1 SYNOPSIS

    use Net::ACL::File;
    use Net::ACL::File::Community;
    use Net::ACL::File::ASPath;
    use Net::ACL::File::Prefix;
    use Net::ACL::File::Access;

    # Construction
    my $list_hr = load Net::ACL::File(<<CONF);
    ! Community-lists
    ip community-list 1 permit 65001:1
    ip community-list 42 deny 65001:1
    ip community-list 42 permit
    ! AS Path-lists
    ip as-path access-list 1 permit .*
    ip as-path access-list 2 permit ^$
    ip as-path access-list 55 permit ^65001_65002
    ! Prefix-lists
    ip prefix-list ournet seq 10 permit 10.0.0.0/8
    ip prefix-list ournet seq 20 permit 192.168.0.0/16
    ! Access-lists
    access-list 10 permit 10.20.30.0 0.0.0.255
    access-list 10 permit 10.30.00.0 0.0.255.255
    access-list 12 deny   10.0.0.0 0.255.255.255
    access-list 12 permit any
    CONF

    # Abstract method
    $list->loadmatch($line);

=head1 DESCRIPTION

This is an abstract class that extends the Net::ACL::File class. It has the
common features of loading a standard access-list in Cisco-notation.
It replaces the load constructor and adds a loadmatch() method that should be
replaced in any sub-class.

Any sub-classes should register them self with the Net::ACL::File class using
the add_listtype() class method. After this, classes are constructed by the
Net::ACL::File new() constructor.

=head1 CONSTRUCTOR

There should be no reason to use nor change the constructor of this class.
However - It gets a Cisco::Reconfig object as argument. It returns a reference
to the object created from the data in the Cisco::Reconfig object.

=head1 ACCESSOR METHODS

=over 4

=item loadmatch()

The loadmatch() method is called with an access-list clause - normally a single
line. It should construct a Net::ACL::Rule object and add it using the
add_rule() inherited method.

=back

=head1 SEE ALSO

Cisco::Reconfig, Net::ACL::File, Net::ACL,
Net::ACL::File::Community, Net::ACL::File::ASPath,
Net::ACL::File::Prefix, Net::ACL::File::Access,
Net::ACL::File::IPAccess, Net::ACL::File::IPAccessExt,
Net::ACL::File::RouteMap


=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::ACL::File::Standard ##

1;
