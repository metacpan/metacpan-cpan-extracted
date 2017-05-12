#!/usr/bin/perl

# $Id: IPAccessExtRule.pm,v 1.10 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::IPAccessExtRule;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @ACL_EIA_INDEX );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Rule );
$VERSION = '0.07';

## Constants For Argument numbering ##

sub ACL_EIA_PROTO { 0; };
sub ACL_EIA_FROM  { 1; };
sub ACL_EIA_TO    { 2; };

## Export Tag Definitions ##

@ACL_EIA_INDEX = qw ( ACL_EIA_PROTO ACL_EIA_FROM ACL_EIA_TO );

@EXPORT      = ();
@EXPORT_OK   = ( @ACL_EIA_INDEX );
%EXPORT_TAGS = (
    index	=> [ @ACL_EIA_INDEX ],
    ALL		=> [ @EXPORT, @EXPORT_OK ]
);

## POD ##

=pod

=head1 NAME

Net::ACL::IPAccessExtRule - Class representing an Extended IP Access-list rule

=head1 DESCRIPTION

This module represents a single extended IP access-list. It implements nothing.
It defines the order of the arguments to the query function by defining
constants.

=head1 EXPORTS

The module exports the following symbols according to the rules and
conventions of the Exporter module.

=over 4

=item :index

	ACL_EIA_PROTO ACL_EIA_FROM ACL_EIA_TO

=back

=head1 SEE ALSO

Net::ACL, Net::ACL::Rule

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::IPAccessExtRule ##
 
1;
