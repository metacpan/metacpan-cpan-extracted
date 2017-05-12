package Object::eBay::Currency;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use Carp;

    my %value_for       :ATTR( :get<value>       );
    my %currency_id_for :ATTR( :get<currency_id> );

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;
        my $details = $args_ref->{object_details};

        my $msg = "Missing 'content' and/or 'currencyID'\n";
        my $content = $details->{content};
        my $id = $details->{currencyID};
        croak $msg if !defined($content) || !defined($id);

        $value_for{$ident}       = $details->{content};
        $currency_id_for{$ident} = $details->{currencyID};
    }

    sub as_string :STRINGIFY {
        my ($self) = @_;
        return $self->get_currency_id() . sprintf('%.2f', $self->get_value());
    }

    # aliases providing naming similar to other Object::eBay classes
    sub value       :NUMERIFY { $_[0]->get_value()       }
    sub as_bool     :BOOLIFY  { $_[0]->get_value() != 0  }
    sub currency_id           { $_[0]->get_currency_id() }
}

1;

__END__

=head1 NAME

Object::eBay::Currency - Represents a currency used by eBay

=head1 SYNOPSIS

    # assuming that $item is an Object::eBay::Item object
    my $price = $item->selling_status->current_price;
    
    # supports string, numeric and boolean context
    print "Going for $price\n";          # "Going for USD12.99"
    print "Bargain!\n" if $price < 20;   # numeric context
    print "Has price\n" if $price;       # boolean context
    
    # accessor methods are also available
    my $currency_id = $price->currency_id; # just the currency ID
    my $value       = $price->value;       # same as numeric context
    my $string      = $price->as_string;   # same as string context

=head1 DESCRIPTION

Many of eBay's API calls return values which represent an amount of a
particular currency.  Item prices are a good example.  An
Object::eBay::Currency object represents a particular quantity of a particular
currency.  Methods throughout Object::eBay return Currency objects where
appropriate.

As mentioned in the L</SYNOPSIS> string, numeric and boolean context are
supported.  In numeric context, the object evaluates to the amount of currency
represented.  In string context, the object evaluates to a string which
represents the currency and the quantity both (see L</as_string> for details).
Boolean context returns the same value as numeric context.  This overloading
of boolean context makes Object::eBay::Currency objects behave as expected in
boolean context instead of returning true all the time.

=head1 METHODS 

=head2 as_bool

Returns a boolean representation of the currency amount.  Namely, if the
currency amount is 0, false is returned.  Otherwise, true is returned.  This
method provides the implementation for boolean context.

=head2 as_string

Returns a string representation of the currency amount.  The string is
produced by concatenating the currency ID with the quantity.  For example 10
U.S. Dollars is represented as 'USD10.00'  The value will always be rounded to
two numbers after the decimal.  The rounding algorithm is that used by
C<sprintf('%.2f')>.

This method provides the value for string context.

=head2 currency_id

Returns a string identifying the type of currency this object represents.  The
possible values are determined by eBay.

=head2 value

Returns the quantity of currency represented by this object.  It's generally a
bad idea to use this method unless you already know the type of currency.  For
example, if the return value is '10', that could mean 10 U.S. Dollars or 10
Euros.

This method provides the value for numeric context.

=head1 DIAGNOSTICS

=head2 Missing 'content' and/or 'currencyID'

This exception is thrown when trying to construct a Currency object from an
invalid hashref.  This indicates a problem (or change) with eBay's XML
response.

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::Currency requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 4

=item * Class::Std

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-eBay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::eBay;

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-eBay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-eBay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-eBay>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-eBay>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
