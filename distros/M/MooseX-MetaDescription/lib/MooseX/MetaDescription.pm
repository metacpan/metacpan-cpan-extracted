package MooseX::MetaDescription;
use Moose;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use MooseX::MetaDescription::Meta::Class;
use MooseX::MetaDescription::Meta::Attribute;
use MooseX::MetaDescription::Description;

no Moose; 1;

__END__

=pod

=head1 NAME

MooseX::MetaDescription - A framework for adding additional metadata to Moose classes

=head1 SYNOPSIS

  package Foo;
  use metaclass 'MooseX::MetaDescription::Meta::Class' => (
      # add class-level metadata
      description => {
          'Hello' => 'World'
      }
  );
  use Moose;
  
  has 'bar' => (
      metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      is          => 'ro',
      isa         => 'Str',   
      default     => sub { Bar->new() },
      # add attribute level metadata
      description => {
          node_type   => 'element',
      }
  );
  
  my $foo = Foo->new;
  
  $foo->meta->description; # { 'Hello' => 'World' }
  
  my $bar = $foo->meta->get_attribute('bar');
  
  # access the desciption HASH directly
  $bar->description; # { node_type   => 'element' }    
  
  # or access the instance of MooseX::MetaDescription::Description
  $bar->metadescription;
  
  # access the original attribute metaobject from the metadesc too
  $bar->metadescription->descriptor == $bar;

=head1 DESCRIPTION

MooseX::MetaDescription allows you to add arbitrary out of band 
metadata to your Moose classes and attributes. This will allow 
you to track out of band data along with attributes, which is 
very useful for say serializing Moose classes in HTML or XML.

=head1 METHODS

=over 4

=item B<meta>

The Moose metaclass.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Code and Design originally by Jonathan Rockway in the Ernst module, 
extracted and refactored by:

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
