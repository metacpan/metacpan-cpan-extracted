use strict;
use warnings;
package SeeAlso::Identifier::ISBN;
{
  $SeeAlso::Identifier::ISBN::VERSION = '0.71';
}
#ABSTRACT: International Standard Book Number as Identifier

use Business::ISBN;
use Carp;

use base qw( SeeAlso::Identifier );


sub parse {
    my $value = shift;
    $value = shift if ref($value) and scalar @_;

    if (defined $value and not UNIVERSAL::isa( $value, 'Business::ISBN' ) ) {
        $value =~ s/^urn:isbn://i;
        $value = Business::ISBN->new( $value );
    }

    return '' unless defined $value;

    my $status = $value->error;
    if ( $status != Business::ISBN::GOOD_ISBN && 
         $status != Business::ISBN::INVALID_GROUP_CODE &&
         $status != Business::ISBN::INVALID_PUBLISHER_CODE ) {
         return '';
    }

    $value = $value->as_isbn13 unless ref($value) eq 'Business::ISBN13';

    return $value->as_string([]);
}


sub canonical {
    return ${$_[0]} eq '' ? '' : 'urn:isbn:' . ${$_[0]};
}


sub hash {
    my $self = shift;

    # TODO: support use as constructor and as function

    if ( scalar @_ ) {
        my $value = shift;
        $value = defined $value ? "$value" : "";
        $value = '' if not $value =~ /^[0-9]+$/ or $value >= 2000000000;
        if ( $value eq "" ) {
            $$self = '';
            return '';
        }
        my $isbn = Business::ISBN13->new( ($value+978000000000) . "X" );
        $isbn->fix_checksum;
        $self->value( $isbn );
        return $value;
    } else {
        return $$self eq '' ? '' : substr($$self, 2, 10 ) - 8000000000;
    }
}


sub isbn13 {
    my $self = shift;
    return $$self;
}


sub isbn10 {
    my $self = shift;
    return '' if $$self eq '' or not $$self =~ /^978/;
    my $value = Business::ISBN->new( substr($$self,3) );
    $value->fix_checksum;
    return $value->as_string([]);
}

1;


__END__
=pod

=head1 NAME

SeeAlso::Identifier::ISBN - International Standard Book Number as Identifier

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  my $isbn = new SeeAlso::Identifier::ISBN "";

  print "invalid" unless $isbn; # $isbn is defined but false !

  $isbn->value( '0-8044-2957-x' );
  $isbn->value; # '' or ISBN-13 without hyphens (9780804429573)
  $isbn; # ISBN-13 as URI (urn:isbn:9780804429573)

  $isbn->hash; # long int between 0 and 1999999999 (or '')
  $isbn->hash( 59652724 ); # set by hash

  $isbn->canonical; # urn:isbn:9780596527242

=head1 DESCRIPTION

This module handles International Standard Book Numbers as identifiers.
Unlike L<Business::ISBN> the constructor of SeeAlso::Identifier::ISBN 
always returns an defined identifier with all methods provided by
L<SeeAlso::Identifier>. As canonical form the URN representation of 
ISBN-13 without hyphens is used - that means all ISBN-10 are converted
to ISBN-13. As hashed form of an ISBN, a 32 Bit integer can be calculated.

=head1 METHODS

=head2 parse ( $value )

Get and/or set the value of the ISBN. Returns an empty string or the valid
ISBN-13 without hyphens as determinded by L<Business::ISBN>. You can also 
use this method as function.

=head2 canonical

Returns a Uniform Resource Identifier (URI) for this ISBN (or an empty string).

This is an URI according to RFC 3187 ("urn:isbn:..."). Unfortunately RFC 3187
is broken, because it does not oblige normalization - this method does: first 
only valid ISBN (with valid checkdigit) are allowed, second all ISBN are 
converted to ISBN-13 notation without hyphens (URIs without defined 
normalization and valitidy check are pointless).

=head2 hash ( [ $value ] )

Returns or sets a space-efficient representation of the ISBN as long integer.
An ISBN-13 always starts with '978' or '979' and ends with a check digit.
This makes 2,000,000,000 possible ISBN which fits in a 32 bit (signed or 
unsigned) integer value. The integer value is calculated from the ISBN-13 by
removing the check digit and subtracting 978,000,000,000.

=head2 isbn13

Return the ISBN in ISBN 13 form (or an empty string)

=head2 isbn10

Return the ISBN in ISBN 10 form if possible (or an empty string)

=head1 NOTES

In theory zero ('0') is a valid ISBN value representing ISBN-10 0-00-000000-0
= ISBN-13 978-0-00-000000-2. In practise this value is mostly used errorously.

For canonical form instead of RFC 3187 you could also use "http://purl.org/isbn/".

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

