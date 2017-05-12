package MooseX::MetaDescription::Meta::Attribute;
use Moose;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
   with 'MooseX::MetaDescription::Meta::Trait';

no Moose; 1;

__END__

=pod

=head1 NAME

MooseX::MetaDescription::Meta::Attribute - Custom attribute metaclass for meta-descriptions

=head1 SYNOPSIS

  package Foo;
  use Moose;
  
  has 'bar' => (
      # use the meta description attribute metaclass for this attr
      metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      is          => 'ro',
      isa         => 'Str',   
      default     => sub { 'Foo::bar' },
      description => {
          baz   => 'Foo::bar::baz',
          gorch => 'Foo::bar::gorch',
      }
  );

=head1 DESCRIPTION

This module provides a custom attribute metaclass to add meta 
description capabilities to your class attributes.

=head1 METHODS 

NOTE: these are methods composed into this class from 
L<MooseX::MetaDescription::Meta::Trait> refer to that 
module for the complete description.

=over 4

=item B<description>

=item B<metadescription_classname>

=item B<metadescription>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
