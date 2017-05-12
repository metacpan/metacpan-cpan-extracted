package Pod::Weaver::Section::ClassMopper;
use Moose;
use Moose::Util::TypeConstraints;
use Class::Load ':all';
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;
use List::Util qw(first);
use Try::Tiny;

our $VERSION = '0.06';

# ABSTRACT: Generate some stuff via introspection

with 'Pod::Weaver::Role::Section';

subtype 'Pod::Weaver::Section::ClassMopper::MethodListType'
   => as 'ArrayRef';

coerce 'Pod::Weaver::Section::ClassMopper::MethodListType'
   => from 'Str'
   => via { 
      [split(/\s+/, $_)]
   };

has '_attrs' => ( is => 'rw' );
has '_methods' => ( is => 'rw' );
has '_class' => ( is => 'rw' );

has 'skip_method_list' => ( 
   is => 'ro', 
   isa => 'Pod::Weaver::Section::ClassMopper::MethodListType',
   coerce => 1,
   default => sub { 
      my @list = Moose::Object->meta->get_all_method_names;
      push @list, 'can';
      return \@list;
   }
);



has [qw(no_tagline include_private skip_attributes skip_methods)] => ( 
   is => 'rw',
   isa => 'Bool',
   default => 0
);

sub weave_section { 
   my $self = shift;
   my( $document, $input ) = @_;

   return if (! defined $self->_get_classname( $input ));
   
   if( $input->{mopper}->{include_private} ) { 
      $self->include_private( 1 );
   }

   if( $input->{mopper}->{no_tagline} ) { 
      $self->no_tagline( 1 );
   }

   if( $input->{mopper}->{skip_method_list} ) { 
      $self->skip_method_list( $input->{mopper}->{skip_method_list} );
   }

   unless( $input->{mopper}->{skip_attributes} || $self->skip_attributes ) { 
      $self->_build_attributes( );
      if( $self->_attrs ) { 
         push @{$document->children},  Pod::Elemental::Element::Nested->new({
            command => 'head1',
            content => 'ATTRIBUTES',
            children => $self->_attrs } 
          );
       }
  }

   unless( $input->{mopper}->{skip_methods} || $self->skip_methods ) { 
      $self->_build_methods( );
      if( $self->_methods ) { 
         push @{$document->children}, Pod::Elemental::Element::Nested->new({ 
            command => 'head1',
            content => 'METHODS',
            children => $self->_methods }
          );
       }
   }
}

sub _build_attributes { 
   my $self = shift;
   my $meta = $self->_class;
   return unless ref $meta;
   return if $meta->isa('Moose::Meta::Role');
   my @attributes = $meta->get_all_attributes;
   if( @attributes ) { 
      my @chunks = map { $self->_build_attribute_paragraph( $_ ) } 
         sort { $a->{'name'} cmp $b->{'name'} } @attributes;
      $self->_attrs( \@chunks );
   }
}

sub _build_methods { 
   my $self = shift;
   my $meta = $self->_class;
   return unless ref $meta;
   return if $meta->isa('Moose::Meta::Role');
   my @methods = $meta->get_all_methods;

   if( @methods ) { 
      my @chunks = map { $self->_build_method_paragraph( $_ ) }
         sort { $a->{'name'} cmp $b->{'name'} } @methods;
      $self->_methods( \@chunks );
   }
}

sub _build_method_paragraph { 
   # Generate a pod section for a method.  
   my $self = shift;
   my $method = shift;   
   return unless ref $method;
   my $name = $method->name;

   if( first { $_ eq $name } @{$self->skip_method_list} ) {
      return;  # Skip over some of the more .. UNIVERSAL methods..
   }

   if( $method->original_package_name =~ /^Moose::Object/ ) { 
      return;  # No one wants to see that shit
   }

   if( $name =~ /^_/ ) { 
      return unless $self->include_private; # skip over privates, unless we don't.
   }

   my $bits = [];
   if( $self->_class ne $method->original_package_name ) {
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Method originates in ' . $method->original_package_name . '.'
      });
   }

   unless( $self->no_tagline ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'This documentation was automatically generated.'
      });
   }

   my $meth = Pod::Elemental::Element::Nested->new( { 
      command => 'head2',
      content => $method->name,
      children => $bits
   } );
   return $meth;

}

sub _build_attribute_paragraph { 
   my $self = shift;
   my $attribute = shift;
   return unless ref $attribute;
   
   if( $attribute->name =~ /^_/ ) { 
      # Skip the _methods unless we shouldn't.
      return unless $self->include_private;
   }

   my $bits = [];
   
   if( $attribute->has_read_method ) { 
      # is => 'r..'
      my $reader = $attribute->get_read_method;
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Reader: ' . $reader
      });
   }

   if( $attribute->has_write_method ) { 
      # is => '..w'
      my $writer = $attribute->get_write_method;
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Writer: ' . $writer
      });
   }
   
   # Moose has typecontraints, not Class::MOP.  
   if( $attribute->has_type_constraint ) { 
      # has an 'isa => ...'
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({
         content => 'Type: ' . $attribute->type_constraint->name
      });
   }

   # Moose only, again.
   if( $attribute->is_required ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'This attribute is required.'
      });
   }

   if( $attribute->has_documentation ) { 
      # Moose's 'docmentation' option.
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Additional documentation: ' . $attribute->documentation
      });
   }

   unless( $self->no_tagline ) { 
      # Adds the 'auto generated' tagline, unless not.
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'This documentation was automatically generated.'
      });
   }
   
   # build up our element, send it on its way.
   my $a = Pod::Elemental::Element::Nested->new({ 
      command => 'head2',
      content => $attribute->name,
      children => $bits
   });
   return $a;

}

sub _get_classname { 
   my( $self, $input ) = @_;
   
   # Do some fiddling here, see what sort of crap we have, and 
   # try to return a package name.  
   my $classname;

   my $ppi = $input->{ppi_document};
   unless( ref $ppi eq 'PPI::Document'  ) { 
      return;
   }
   my $node = $ppi->find_first('PPI::Statement::Package');
   if( $node ) { 
      $classname = $node->namespace;
   } else { 
      # parsing comments.  WHAT COULD GO WRONG.  
      # Shamelessly stolen from Pod::Weaver::Section::Name.  Thanks rjbs!
      ($classname) = $ppi->serialize =~ /^\s*#+\s*PODNAME:\s*(.+)$/m;
   }

   try {
       local @INC=('blib',@INC);
       load_class( $classname );
       my $meta = Class::MOP::Class->initialize( $classname );
       $self->_class( $meta );
   }
   catch {
       $classname=undef;
   };
   return $classname;
}



__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME 

Pod::Weaver::Section::ClassMopper - Use Class::MOP introspection to make a couple sections.

=head1 OVERVIEW

This section plugin is able to generate two sections for you, B<ATTRIBUTES> and B<METHODS>.  By
default, both sections are generated.

Your results will look something like:

 =head1 ATTRIBUTES

 =head2 someattribute

 Reader: someattribute

 Type: Str

 This attribute is required.

It should be noted that should an attribute make use of the Moose 'documentation' 
option, its value will be included here as well.

 =head1 METHODS

 =head2 somemethod
  
 Method originates in Some::Parent::Class

 This documentation was automatically generated.

 =head2 another_method 
 


=head1 OPTIONS

All options are checked under the C<mopper> part of the input..

 $weaver->weave_document({ 
   ...
   mopper => { 
      include_private => 0,
      skip_attributes => 0,
      skip_methods => 0,
      no_tagline => 0,
      skip_method_list => { 
         [qw(DOES AUTOLOAD can)] # .. see below
      }
   },
   ...
 });

Additionally, options passed via C<weaver.ini>, by the same name, should also
be accepted. 

 [ClassMopper]
 no_tagline = 1
 skip_method_list = DOES AUTOLOAD can  
etc.

=head2 C<include_private>

   By default, all methods and attributes matching C</^_/> are excluded.  Toggle this
bit on if you want to see the gory details.

=head2 C<skip_attributes> and C<skip_methods>

Set these to something Perl thinks is true and it'll skip over the appropriate 
section.  

=head2 C<no_tagline>

Turn the "This documentation was automatically generated" bit off.  It's on 
by default.

=head2 C<skip_method_list>

By default, there are several methods (see below) that will be skipped when 
generating your list.  Most of them are from UNIVERSAL or L<Moose::Object>.  
If you'd like to adjust this list, provide the B<complete> list (that is, 
include the things below, and then some) here, as an arrayref.

The default list of methods skipped is derived from L<Moose::Object>'s list
of methods.  At the time of writing, that list is:

=over 4

=item dump

=item DEMOLISHALL

=item meta

=item does

=item new

=item DESTROY

=item BUILDALL

=item can

=item BUILDARGS

=item isa

=item VERSION

=item DOES

=back

=head1 AUTHOR

Dave Houston, C<dhouston@cpan.org>, 2010.

=head1 CONTRIBUTORS

=over 3

=item Alexei Znamensky <russoz@cpan.org>

=item Caleb Cushing <xenoterracide@gmail.com>

=item Edward Ash <eash@nvidia.com>

=back

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=cut
