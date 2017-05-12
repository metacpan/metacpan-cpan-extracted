package Object::eBay::Boolean;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use Carp;

    my %value_for :ATTR( :get<value> );

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;
        my $details = $args_ref->{object_details} || q{};
        croak "Invalid boolean value '$details'\n"
            unless $details eq 'true' || $details eq 'false';
        $value_for{$ident} = $details && $details eq 'true' ? 1 : 0;
    }

    sub as_string :STRINGIFY {
        my ($self) = @_;
        return $self->get_value() ? 'true' : 'false';
    }

    sub as_boolean :BOOLIFY {
        my ($self) = @_;
        return $self->get_value();
    }

    sub true  { shift->new({ object_details => 'true' })  }
    sub false { shift->new({ object_details => 'false' }) }
}

1;

__END__

=head1 NAME

Object::eBay::Boolean - Represents a boolean return value

=head1 SYNOPSIS

    # assuming that $item is an Object::eBay::Item object
    my $private = $item->seller->is_feedback_private();
    
    # In string context, yields 'true' or 'false'
    print "Is the feedback private? $private\n";
    
    # In boolean context, yields 1 or 0
    if ($private) {
        print "Feedback is private\n";
    }
    else {
        print "Feedback is public\n";
    }

=head1 DESCRIPTION

Many of eBay's API calls return boolean (true/false) values.  An
Object::eBay::Boolean object represents this boolean return value in a
context-aware way.  In boolean context, the value is simply a boolean value as
expected.  In string context, the value is eBay's literal 'true' or 'false'
value.

=head1 METHODS 

=head2 true

A class method that returns a new L<Object::eBay::Boolean> object representing
true.

=head2 false

A class method that returns a new L<Object::eBay::Boolean> object representing
false.

=head2 as_boolean

This method implements the boolean context.  Namely

    if ( $x->as_boolean() ) { ... }

is the same as

    if ($x) { ... }

=head2 as_string

This method implements the string context.  Namely

    print "Example: " . $x->as_string() . "\n";

is the same as

    print "Example: $x\n";

=head1 DIAGNOSTICS

=head2 Invalid boolean value '%s'

If an Object::eBay::Boolean object is constructed with a value other than
'true' or 'false', this exception is thrown.  Seeing this exception most
likely indicates an error (or change) in eBay's XML response.

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::Boolean requires no configuration files or environment variables.

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
 
