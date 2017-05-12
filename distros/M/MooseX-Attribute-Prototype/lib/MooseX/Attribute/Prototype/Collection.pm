# Collection Class for prototypes;
#   Key is role/prototype
#       
package MooseX::Attribute::Prototype::Collection;

    use Moose;
    use MooseX::AttributeHelpers;

    our $VERSION = '0.10';
    our $AUTHORITY = 'cpan:CTBROWN';

    has 'prototypes' => (
        is            => 'rw' ,
        isa           => 'HashRef[MooseX::Attribute::Prototype::Object]' ,
        default       => sub { {} } ,
        documentation => 'Slot containing hash of attribute prototypes' ,
        metaclass     => 'Collection::Hash' ,
        provides      => {
            set     => 'set' ,
            get     => 'get' , 
            count   => 'count' ,    
            exists  => 'exists' ,
            keys    => 'keys' ,
        } ,
    );

         

  # This is a simplified interface for set where you pass a prototype instead
  # of a name => prototype.
    sub add_prototype {
        
        my ( $self, $prototype ) = @_;
        $self->set( $prototype->name, $prototype );

    } 


  # set the reference property of the attribute described by key
    sub set_referenced { 

        $_[0]->get( $_[1] )->referenced(1);

            
    }


    no Moose;

=pod

=head1 NAME

MooseX::Attribute::Prototype::Collection - Container class for MooseX::Attribute::Prototype::Object

=head1 VERSION 

0.10 - Released 2009-07-18

=head1 SYNOPSIS

    use MooseX::Attribute::Prototype::Collection
    $collection = MooseX::Attribute::Prototype::Collection->new();

  # Add a MooseX::Attribute::Prototype::Object
    $collection->add_prototype( $prototype );

  # Retrieve a prototype from the collections
    $collection->get( 'MyRole/attr' );
    
  # Check if a prototype exists
    $collection->exists( 'MyRole/attr' );


=head1 DESCRIPTION

This class is used internally by MooseX::Attribute::Prototype
it serves as a container for holding the prototype objects.  There is 
(as of yet) little reason to use this class directly.   

=head1 SEE ALSO

L<MooseX::Attribute::Prototype>, 

L<MooseX::Attribute::Prototype::Meta>, 

L<MooseX::Attribute::Prototype::Object>,

L<Moose>

L<MooseX::Role::Parameterized> 

L<MooseX::Types>


=head1 AUTHOR

Christopher Brown, C<< <ctbrown at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-attribute-prototype at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Attribute-Prototype>.  I will be notified, and then you'll
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

Copyright 2009 Christopher Brown and Open Data Group L<http://opendatagroup.com>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::Attribute::Prototype


