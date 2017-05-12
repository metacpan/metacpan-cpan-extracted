package Object::eBay::Condition;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use Carp;

    my %display_name_for :ATTR( :get<display_name> );
    my %condition_id_for :ATTR( :get<condition_id> );

    sub BUILD {
        my ( $self, $ident, $args_ref ) = @_;

        my $condition_id = $args_ref->{id};
        croak "Missing ConditionID\n" if not $condition_id;
        my $display_name = $args_ref->{name};
        croak "Missing ConditionDisplayName\n" if not $display_name;

        $display_name_for{$ident} = $display_name;
        $condition_id_for{$ident} = $condition_id;
    }

    sub as_string :STRINGIFY { shift->get_display_name }

    # aliases providing naming similar to other Object::eBay classes
    sub display_name           { $_[0]->get_display_name }
    sub condition_id :NUMERIFY { $_[0]->get_condition_id }
}

1;

__END__

=head1 NAME

Object::eBay::Condition - Represents a condition used by eBay

=head1 SYNOPSIS

    # assuming that $item is an Object::eBay::Item object
    my $condition = $item->condition;
    
    # supports string and numeric context
    print "Condition: $condition\n";    # "Condition: Brand New"
    print "Shiny!\n" if $condition == 1000;    # numeric context
    
    # accessor methods are also available
    my $condition_id = $condition->condition_id;    # just the condition ID
    my $name         = $condition->display_name;    # same as numeric context
    my $string       = $condition->as_string;       # same as string context

=head1 DESCRIPTION

eBay allows sellers to describe the condition of their item using several
pre-determined descriptions.  These descriptions depend on the listing
category but often include values like "Brand New" or "Acceptable".  Each
textual value is associated with a numeric code which uniquely identifies the
value for the particular category.  Presumably the codes are identical across
sites regardless of the site's language.

An Object::eBay::Condition object represents a particular condition.  Methods
on Object::eBay::Item return Condition objects where appropriate.

As mentioned in the L</SYNOPSIS>, string and numeric context are supported.
In numeric context, the object evaluates to eBay's numeric condition
identifier.  In string context, the object evaluates to a string which
describes the condition (see L</as_string> for details).

=head1 METHODS

=head2 as_string

Returns a string with a natural language description of the condition.  For
example "Brand New" or "Acceptable" or "Very Good", etc.

This method provides the value for string context.

=head2 condition_id

Returns a number identifying the condition.  The possible values are
determined by eBay and vary from category to category.

=head2 display_name

Identical to L</as_string>

=head1 DIAGNOSTICS

=head2 Missing ConditionID

=head2 Missing ConditionDisplayName

These exceptions are thrown when constructing a Condition object from an
invalid hashref.  This indicates a problem (or change) with eBay's XML
response.

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::Condition requires no configuration files or environment variables.

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

Copyright (c) 2010 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

