package Object::eBay::Attribute;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use overload
        q{""}    => 'get_value_literal',
        q{0+}    => 'get_value_id',
        fallback => 1
    ;
    use Carp;

    my %attribute_id_for  :ATTR( :get<attribute_id>  );
    my %value_id_for      :ATTR( :get<value_id>      );
    my %value_literal_for :ATTR( :get<value_literal> );

    sub BUILD {
        my ( $self, $ident, $args_ref ) = @_;
        my $hash = $args_ref->{attribute} || {};
        $attribute_id_for{$ident}  = $hash->{attributeID};
        $value_id_for{$ident}      = $hash->{Value}{ValueID};
        $value_literal_for{$ident} = $hash->{Value}{ValueLiteral};
    }
}

1;

__END__

=head1 NAME

Object::eBay::Attribute - Represents an item attribute

=head1 SYNOPSIS

    # assuming that $item is an Object::eBay::Item object
    my $attribute = $item->attributes->find(10244);
    print "The condition is $attribute\n";  # "The condition is New"
    if ( $attribute == 24227 ) {
        print "This is a Sega Genesis game\n";
    }

=head1 DESCRIPTION

eBay associates key-value pairs (attributes) with certain auctions.  An
L<Object::eBay::Attribute> object represents a specific attribute of an
auction.

=head1 METHODS 

=head2 get_attribute_id

Returns an ID number for the type of this attribute.

=head2 get_value_id

Returns an ID number for the value of this attribute.  This method is called
when the attribute object is used in numeric context.

=head2 get_value_literal

Returns a string for the value of this attribute.  This method is called when
the attribute object is used in string context.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
