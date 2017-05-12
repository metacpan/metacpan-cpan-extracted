package MooseX::MetaDescription::Meta::Class;
use Moose;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Class';
   with 'MooseX::MetaDescription::Meta::Trait';
   
has '+description' => (
   default => sub {
       my $self   = shift;
       my @supers = $self->linearized_isa;
       shift @supers;
       my %desc;
       foreach my $super (@supers) {
            if ($super->meta->isa('MooseX::MetaDescription::Meta::Class')) {
                %desc = (%{ $super->meta->description }, %desc)
            }
       }
       \%desc;
   },
);   

no Moose; 1;

__END__

=pod

=head1 NAME

MooseX::MetaDescription::Meta::Class - Custom class metaclass for meta-descriptions

=head1 SYNOPSIS

  package Foo;
  use metaclass 'MooseX::MetaDescription::Meta::Class' => (
      description => {
          'Hello' => 'World',
      }
  );
  use Moose;
  
  package Bar;
  use Moose;
  
  extends 'Foo';
  
  # always add it *after* the extends
  __PACKAGE__->meta->description->{'Hello'} = 'Earth';
  
  package Baz;
  use Moose;
  
  extends 'Bar';
  
  package Gorch;
  use metaclass 'MooseX::MetaDescription::Meta::Class' => (
      description => {
          'Hello' => 'World'
      }
  );    
  use Moose;

  extends 'Baz';  

  # ...
  
  Foo->meta->description # { 'Hello' => 'World', 'World' => 'Hello' }
  Bar->meta->description # { 'Hello' => 'Earth', 'World' => 'Hello' } # change one, inherit the other  
  Baz->meta->description # { 'Hello' => 'Earth', 'World' => 'Hello' } # inherit both 
  Gorch->meta->description # { 'Hello' => 'World' } # overrides all, no inheritance   

=head1 DESCRIPTION

This module provides the custom metaclass to add Meta Descriptions 
to your classes. It provides a limited degree of inheritance of 
meta-descriptions, the details of which are shown above in the 
SYNOPSIS section.

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
