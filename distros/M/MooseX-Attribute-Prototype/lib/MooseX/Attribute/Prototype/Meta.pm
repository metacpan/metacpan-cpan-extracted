package MooseX::Attribute::Prototype::Meta;

    use Moose::Role;
    use MooseX::Attribute::Prototype::Object;
    use MooseX::Attribute::Prototype::Collection;
    use MooseX::AttributeHelpers;
    
    use Data::Dumper;
    
    use MooseX::Attribute::Prototype::Meta::Attribute::Trait::Prototype;

    our $VERSION = '0.10';
    our $AUTHORITY = 'cpan:CTBROWN';

  # This keeps the queue of the roles to keep track which roles the prototype
  # attribtutes come from. 
    
    has 'prototype_queue' => (
        metaclass   => 'Collection::Array' ,
        is          => 'rw' ,
        isa         => 'ArrayRef[Str]' ,
        default     => sub { [] } ,
        required    => 1 ,
        provides    => {
            'unshift' => 'queue_role' ,
            'shift'   => 'dequeue_role' ,
            'get'     => 'get_role' ,
            'count'   => 'queue_size' ,
        } ,
    );

    
    has 'prototypes' => (
        is              => 'rw' ,
        isa             => 'MooseX::Attribute::Prototype::Collection' ,
        default         => sub { MooseX::Attribute::Prototype::Collection->new() } ,
        required        => 1 ,
        documentation   => 'Slot for holding the prototypes definitions' ,
        handles => [ 
            'add_prototype' , 
            'get_prototype' , 
            'count_prototypes' , 
            'get_prototype_keys' ,
        ] ,
    );



    around 'add_attribute' => sub {
        
        my ( $add_attribute, $self, $name, @options ) = @_;

        my %opts;
        if ( scalar @options % 2 == 0 ) {
            %opts = @options;
        } else { #if ( scalar @options == 1 ) {
            %opts = %{ $options[0] };
        }

      # CASE: prototype used in attribute specification.     
      #   If specified with 'prototype' we need to first load that roll 
      #   into the prototypes slot. Borrow those attributes and  
      #   
      # As of Moose ~0.85, an an option as part of an attribute will 
      #   cause a warning to be issued.  This is the case for 
      #   Here we dynamically add a meta-attribute trait.  
      #     
        if ( $opts{ prototype } ) {

          # Install the metaclass
          # Check to see if this is the abbreviated prototype specification
            if ( $opts{ prototype } !~ m/\// ) {
                
              # CTB: 2009-07-18
                
                # if ( $opts{ 'traits' } ) { 
                #  push @{ $opts{'traits'} }, 'Prototype';    
                # } else {
                #  $opts{ 'traits' } = 'Prototype';
                # }    
                # print Dumper \%opts;
                # print "\n";
                $opts{ prototype } = $opts{ prototype } . '/' . lc( $opts{ prototype } );

            }

            $opts{ 'traits' } = $opts{'traits'} ? [ 'Prototype', @{ $opts{'traits'} } ] : ['Prototype'] ;

            
            # $self->flag( $self->flag + 1 ); # Indicates that all attributes until 
            #                 # the flag are unset should be diverted into
            #                   # the prototype slot
            
            my $role_name = _parse_prototype_name( $opts{ prototype } )->{role};

            $self->queue_role( $role_name );  # Keeps track of the rolls


          # Dynamic loading of classes.
            Class::MOP::load_class( $role_name );           
            my $role = Moose::Meta::Role->initialize( $role_name );
            $role->apply( $self ); 

          # Now, let's construct the new opt string from the prototype.

            my $proto = $self->prototypes->get( $opts{ prototype } ) 
                || confess( $opts{ prototype } . " does not exist" );

          # Clobber the prototype options with those specified in the 
          # class       
            my %new_opts = ( %{ $proto->options }, %opts );
 
          # Now. let's install the attribute, finally!
          # Would it be possible to create this r
            $self->$add_attribute( $name, %new_opts );  

          # Mark the prototype as referenced
            $self->prototypes->set_referenced( $opts{ prototype } );


          # We are done borrowing
            $self->dequeue_role;  # We are done with the prototype roll now. 
            # $self->flag( $self->flag - 1 );     # Set the flag.


        } elsif ( $self->queue_size > 0 ) { 
        
          # We were not using a prototype, but the flag is set 
          # -  divert the install to the prototypes.
            
            $self->get_role(0); # role_name.  We do not remove this from the queue since
                                # each role can provide multiple attributes.

            $self->prototypes->add_prototype( 
                MooseX::Attribute::Prototype::Object->new( 
                    name => $self->get_role(0) . "/" . $name ,
                    options => \%opts 
                )
            );
 
        } else {

          # PLAIN OLD ATTRIBUTE
          $self->$add_attribute( $name, @options );

        } 

    }; 



# These should be exported from MooseX::Attribute::Prototype::Object
    sub _parse_prototype_name {

        my $name = shift || confess( "Must pass a prototype name to _parse_prototype_name" );
        my ( $role, $attribute );

        if ( $name =~ m/\// ) {
            $name =~ m/^(.*)\/(.*)$/;
            $role      = $1;
            $attribute = $2;
        } elsif ( $name =~ /::/ ) {
            $name  =~ m/^(.*)::(.*)$/;
            $role = $name;
            $attribute = lc $2;
        } else {
            $role = $name;
            $attribute = lc $name;
        }


        return { role => $role , attribute => $attribute } ;

    }
        

    no Moose::Role;



=pod

=head1 NAME 

MooseX::Attribute::Prototype::Meta - Metaclass Role for Attribute Prototypes

=head1 VERSION 

0.10 - Released 2009-07-18

=head1 SYNOPSIS

Please see L<MooseX::Attribute::Prototype>.

=head1 DESCRIPTION

This metaclass role, when injected into an objects metaclass provides
the ability to borrow and extend Moose attributes.

=head1 INTERNAL METHODS

=head2 _parse_prototype_name

Given the name of the prototype in either standard or abbreviated form, 
returns a hashref with C<role> and C<attribute> key-value pairs.

  # { role => 'M::X::Foo', attribute => 'bar' }
  _parse_prototype_name( 'M::X::Foo/bar' );  

  # { role => 'M::X::Foo', attribute => 'foo' }
  _parse_prototype_name( 'M::X::Foo' );  


=head1 SEE ALSO

L<MooseX::Attribute::Prototype>, 

L<MooseX::Attribute::Prototype::Object>,

L<MooseX::Attribute::Prototype::Collection>,

L<Moose>


=head1 AUTHOR

Christopher Brown, C<< <ctbrown at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-attribute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Attribute-Prototpye>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Attribute::Prototype

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Attribute-Prototype>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Attribute-Prototype>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Attribute-Prototype>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Attribute-Prototype>

=back


=head1 ACKNOWLEDGEMENTS

Though they would probably cringe to hear it, this effort would not have 
been possible without: 

Shawn Moore

David Rolsky

Thomas Doran

Stevan Little


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christopher Brown and Open Data Group L<http://opendatagroup.com>, 
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


1; # End of module MooseX::Attribute::Prototype::Meta
