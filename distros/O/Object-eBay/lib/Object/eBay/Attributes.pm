package Object::eBay::Attributes;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use base qw( Object::eBay );
    use Carp;
    use Object::eBay::Attribute;

    my %value_for :ATTR( :get<value> );

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;
        $value_for{$ident} = $args_ref->{object_details} || {};
    }

    sub _maybe_array { ref($_[0]) eq 'ARRAY' ? @{$_[0]} : $_[0] }
    sub find {
        my ($self, $pattern) = @_;
        my $array = $self->get_details;
        return if not ref $array;
        my @sets          = map { $_->{AttributeSet} } _maybe_array($array);
        my @attributes    = map { _maybe_array( $_->{Attribute} ) }
                            map { _maybe_array($_) }
                            @sets;
        my @needles = ref($pattern) eq 'Regexp'
                    ? grep { $_->{Value}{ValueLiteral} =~ $pattern } @attributes
                    : grep { $_->{attributeID} == $pattern } @attributes
                    ;
        return if not @needles;
        return map {
            Object::eBay::Attribute->new({ attribute => $_ });
        } @needles;
    }

}

1;

__END__

=head1 NAME

Object::eBay::Attributes - Represents item attributes

=head1 SYNOPSIS

    # assuming that $item is an Object::eBay::Item object
    my $attribute = $item->attributes->find(10244);
    print "The condition is $attribute\n";

=head1 DESCRIPTION

eBay associates key-value pairs (attributes) with certain auctions.  An
L<Object::eBay::Attributes> object represents the collection of all attributes
for a specific auction.

=head1 METHODS 

=head2 find

Given either an "attributeID" or a regular expression, searches for attributes
and returns a list of L<Object::eBay::Attribute> objects representing them.
If the argument is a number, it's intrepreted as an "attributeID" (the numeric
code that eBay assigns to a particular attribute).  If the argument is a
regular expression, that pattern is compared against the string values
("ValueLiteral") for each attributes and those matching are returned.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2008 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
