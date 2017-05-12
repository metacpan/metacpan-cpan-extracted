package MooseX::Meta::Attribute::Index;

    our $VERSION = 0.04;
    our $AUTHORITY = 'cpan:CTBROWN';

    use Moose::Role;
    use Carp;


  # Given the name of the attribute return the attributes index
    sub get_attribute_index { 

        my $self = shift;
        my $name = shift;

        $self->meta->get_attribute( $name )->index 

    }



  # Given the index of the attribute return the attributes value
    sub get_attribute_by_index {

        my ($self, $index) = @_;
        confess( "You cannot retrieve non integer valued indexes. ($index)" ) 
            if ( $index =~ /\D/ ); 

        my $attr = $self->get_attribute_name_by_index( $index );
        
        if ( $attr ) {
            return $self->meta->get_attribute( $attr );
        } else {
            carp( "There is no attribute with index, $index" );
            return undef;
        }

    }



  # Given the index, return attribute name
    sub get_attribute_name_by_index {

        my ($self, $index) = @_;  
        # print "===>$index\t";
        confess( "You cannot retrieve non integer valued indexes. ($index)" ) 
            if ( $index =~ /\D/ ); 

        foreach my $name ( keys %{ $self->meta->get_attribute_map } ) {
            my $attribute = $self->meta->get_attribute( $name );
            return ( $name ) 
                if ( $attribute->can('index') and $attribute->index == $index );
        }

        carp( "There is no attribute with index, $index" );
        return undef;

    }



package MooseX::Meta::Attribute::Trait::Index;

    use Moose::Role;

    has index => ( 
        is      => 'rw' ,
        isa     => 'Int' ,
        predicate   => 'has_index' ,
        trigger     => sub { 
                my ( $self, $value, $meta ) = @_ ;
                if ( $value < 0 ) {
                    confess( "A negative value cannot be used as an " .
                             "index for an attribute.\n" );
                }
            } , 
    );


package Moose::Meta::Attribute::Custom::Trait::Index;
    sub register_implementation { 
        'MooseX::Meta::Attribute::Trait::Index' 
    };




1;


__END__

=pod 

=head1 NAME

MooseX::Meta::Attribute::Index - Provides index meta attribute trait


=head1 SYNOPSIS

    package App;
        use Moose;
            with 'MooseX::Meta::Attribute::Index';

        has attr_1 => ( 
            traits  => [ qw/Index/ ] ,
            is      => 'rw'     , 
            isa     => 'Str'    ,
            index   => 0
        );

        has attr_2 => (
            traits  => [ qw/Index/ ] ,
            is      => 'rw'     ,
            isa     => 'Int'    ,
            index   => 1
        ) ;


    package main;
        my $app = App->new( attr_1 => 'foo', attr_2 => 42 );
        
        $app->get_attribute_index( "attr_1" );  # 0
        $app->get_attribute_index( "attr_2" );  # 1

        $app->get_attribute_by_index(0); # returns attr_1 object
        $app->get_attribute_by_index(1); # returns attr_2 object

        $app->get_attribute_name_by_index(0); # returns attr_1 object
        $app->get_attribute_name_by_index(1); # returns attr_2 object


=head1 DESCRIPTION

This module is a Moose role which implements a meta-attribute, B<index>
, using traits. The index meta attribute is useful for ordered of 
attributes.  In standard Moose, attributes are implemented via hash
references and order is not preserved.  This module implements a 
meta-attribute that can be used to track the order of attributes where 
the order of attributes matters. For example, see L<ODG::Record> where 
maintaining of the order of attributes allows for a Moose class to use 
an array ref for storage rather than a hash ref.  

The indexes must be defined and provided manually.  The indexs are 
checked to ensure that negative indices are not used.

In addition to the meta-attribute, several methods are introduced to
work with the indexed attributes.  See L<#methods> below.  If you just 
want the meta attribute without the added methods, have your class use
the role 'MooseX::Meta::Attribute::Trait::Index'.


=head1 METHODS

The following methods are loaded into your class when this role is used.

=over

=item get_attribute_index( $attr_name )

Returns the index for the attribute c<$attr_name>

=item get_attribute_by_index( $index )

Returns the attribute associated with the index

=item get_attribute_name_by_index( $index )

Returns the attribute name associated with $index 

=back

=head1 SEE ALSO

L<ODG::Record>, L<Moose>

=head1 AUTHOR

Christopher Brown, L<cbrown -at- opendatagroup.com>

L<http://www.opendatagroup,com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Open Data

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut



