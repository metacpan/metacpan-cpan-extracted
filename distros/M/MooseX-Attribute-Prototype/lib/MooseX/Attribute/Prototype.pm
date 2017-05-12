package MooseX::Attribute::Prototype;

    use 5.008;  
    use Moose;
    use Moose::Exporter;
    use MooseX::Attribute::Prototype::Meta;
    use Moose::Util::MetaRole;
    use MooseX::Attribute::Prototype::Meta::Attribute::Trait::Prototype;    

    our $VERSION = '0.10';
    our $AUTHORITY = 'cpan:CTBROWN';

    Moose::Exporter->setup_import_methods();    
        
    sub init_meta {
        
        my ( $caller, %options ) = @_;

        Moose::Util::MetaRole::apply_metaclass_roles(
            for_class       => $options{for_class} ,
            metaclass_roles => [ 'MooseX::Attribute::Prototype::Meta' ] ,
        );   

    }

    no Moose;


=pod 

=head1 NAME

MooseX::Attribute::Prototype - Borrow and Extend Moose Attrtibutes

=head1 VERSION

0.10 - Released 2009-07-18

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Attribute::Prototype;
    
    has 'my_attr' => (
        is        => 'rw' ,
        isa       => 'Str' ,
        prototype => 'MyRole/my_attr' , 
    );
    
    
    has 'my_attr_2' => prototype => 'MyRole2/my_attr_2'; 
    
    has 'my_attr_3' => prototype => 'MyRole3'; # Same as 'MyRole3/myrole3'


=head1 DESCRIPTION

This module implements attribute prototyping -- the practice of borrowing 
an attribute from a role and optionally overriding/extending the attribute 
definition. This is This works very similar to Moose's native attribute 
cloning, but allows for additional benefits such as changing the name of 
the attribute and the abstracting of attributes into roles.

Attributes are very often designed as objects that have their own types and 
methods associated with them. MooseX::Attribute::Prototype takes a very
pragmatic view of attributes. They are the fundamental building 
blocks of a class. This module promotes a more natural reuse of attributes.  

When your attribute includes a C<prototype> specification, the 
attribute is copied from the role and attribute.  In many situations,
all you will want is declare a C<prototype>.  
All current specifications override those provided by prototype.


=head1 How to use Attribute Prototypes

All variants of usage are in the SYNOPSIS above.  This is a more 
thorough explanation.  

Prototypes are just any good ole Moose attributes in good ole 
L<Moose::Role>. To use them simply declare a C<prototype> in your 
attribute definition:

    prototype => 'MyRole/attribute' 

where C<MyRole> is the name of the role and C<attribute> is the name of 
the attribute.  As of version 0.05, you may use the abbreviated 
specification and omit the name of the C<attribute>.  The attribute 
used as the prototype has the the same name as the role, except it 
has all lower-case letters.  

    prototype => 'MyRole' 

In this example, the prototype is C<MyRole/myrole> serves as the 
prototype.  This is just a shortcut to cover the very common occurrence where 
the attribute shares the name of the role.  


=head1 WHY?

L<MooseX::Role::Parameterized> and L<MooseX::Types> abstract
the roles and types, respectively. But surprisinly, there is no similar 
functionality for attributes. Moose leans towards viewing attributes
as containers for data.  However, attributes can store full-fledged 
objects. And these objects often have specialized types and subtypes, 
methods, and behaviors (such as getting their values using 
L<MooseX::Getopt>). In fact, attribute specifications, can often become
the majority of code for a given application. Why not seperate these 
chunks into horizontally-reusable roles?  

L<MooseX::Attribute::Prototype> takes a functional view of attributes -- 
slots that can contain anything -- and provides an easy interface for 
making these slots reusable.

=head2 Why Not Moose's Attribute Clone Mechanism?

Moose's attribute cloning does not allow you to change the name 
of the derived attribute. You can take the defaults of an attribute from 
a role and change its default, but good luck in changing the name of the
attribute.   

=head2 Subclassing Benefit

L<Moose> makes subclassing easy through the c<extends> sugar. More 
often than not, however, Moose applications are an amalgam of 
objects including other Moose classes and other CPAN modules. In these 
cases, one often places the objects in the the attributes. 
L<MooseX::Attributes::Prototypes> allows for the Moosifying of these CPAN
classes in a reusable way.  


=head1 SEE ALSO

L<MooseX::Attribute::Prototype::Meta>, 

L<MooseX::Attribute::Prototype::Object>,

L<MooseX::Attribute::Prototype::Collection>,

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
