#!/usr/bin/perl

package MooseX::Role::JSONObject::Meta::Trait;

use v5.012;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.0");

use Moose::Role;

Moose::Util::meta_attribute_alias('JSONAttribute');

has json_attr => (
	is => 'rw',
	isa => 'Str',
	predicate => 'has_json_attr',
);

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Role::JSONObject::Meta::Trait - rename a JSONObject attribute

=head1 SYNOPSIS

    package foo;
    
    use Moose;
    use MooseX::Role::JSONObject::Meta::Trait;

    with 'MooseX::Role::JSONObject';
    
    has ipv4_address => (
      is => 'rw',
      isa => 'Str',
      traits => ['JSONAttribute'],
      json_attr => 'IPv4 Address',
    );

    ...
    
    my %data = ('IPv4 Address' => '127.0.0.1');
    my $o = foo->from_json(\%data);
    say $o->ipv4_address;

=head1 DESCRIPTION

The C<MooseX::Role::JSONObject::Meta::Trait> trait enhances
the L<MooseX::Role::JSONObject> role by allowing an attribute to be stored or
retrieved from a hash element with a different name.  This may be useful when
parsing or outputting data with key names containing whitespace or
other characters not well suited for use in a Moose attribute name.

The trait may also be accessed by its C<JSONAttribute> alias.

=head1 PROPERTIES

The C<MooseX::Role::JSONObject::Meta::Trait> trait provides a single
property:

=over 4

=item * C<json_attr>

Specify the name of the hash key that this attribute should be stored to
or retrieved from.

=back

=head1 SEE ALSO

L<MooseX::Role::JSONObject>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

