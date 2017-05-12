use strict;
use warnings;
package SeeAlso::Identifier::ISIL;
{
  $SeeAlso::Identifier::ISIL::VERSION = '0.71';
}
#ABSTRACT: International Standard Identifier for Libraries and Related Organisations

use utf8;


use Carp;

use base qw( SeeAlso::Identifier Exporter );
our @EXPORT_OK = qw( sigel2isil );


sub parse {
    my $value = shift;

    if (defined $value) {
        $value =~ s/^\s+|\s+$//g;
        $value =~ s/^ISIL |^info:isil\///i;

        # ISIL too long
        return '' unless length($value) <= 16;

        # Does not look like an ISIL
        return '' unless $value =~ /^([A-Z0-9]+)-(.+)$/;

        my ($prefix, $local) = ($1, $2);

        # Invalid prefix
        return '' unless ($prefix =~ /^[A-Z]{2}$/ or 
                          $prefix =~ /^[A-Z0-9]([A-Z0-9]{1-3})?$/);

        # Invalid characters in local library identifier
        return '' unless ($local =~ /^[a-zA-Z0-9:\/-]+$/);
    } else {
        $value = '';
    }

    return $value;
}




sub canonical {
    return ${$_[0]} eq '' ? '' : 'info:isil/' . uc(${$_[0]});
}


sub hash {
    return ${$_[0]} eq '' ? '' : uc(${$_[0]});
}


sub prefix {
    return ${$_[0]} =~ /^([A-Z0-9]+)-(.+)$/ ? $1 : '';
}


sub local {
    return ${$_[0]} =~ /^([A-Z0-9]+)-(.+)$/ ? $2 : '';
}


sub sigel2isil {
    my $sigel = shift;

    # Falls das Sigel mit einem Buchstaben beginnt, 
    # wird dieser in einen Großbuchstaben umgewandelt
    my $isil = ucfirst($sigel);

    # Bindestriche und Leerzeichen werden entfernt
    $isil =~ s/[- ]//g;

    # Slashes werden Bindestriche
    $isil =~ s/\//-/g;

    # Umlaute und Eszett (Ä,Ö,Ü,ä,ö,ü,ß) werden durch 
    # einfache Buchstaben ersetzen (AE,ÖE,UE,ae,oe,ue,ss).
    $isil =~ s/Ä/AE/g;
    $isil =~ s/Ö/OE/g;
    $isil =~ s/Ü/UE/g;
    $isil =~ s/ä/ae/g;
    $isil =~ s/ö/oe/g;
    $isil =~ s/ü/ue/g;
    $isil =~ s/ß/ss/g;

    return SeeAlso::Identifier::ISIL->new("DE-$isil");
}

1;




=pod

=head1 NAME

SeeAlso::Identifier::ISIL - International Standard Identifier for Libraries and Related Organisations

=head1 VERSION

version 0.71

=head1 DESCRIPTION

The purpose of ISIL is to define and promote the use of a set of 
standard identifiers for the unique identification of libraries 
and related organizations with a minimum impact on already existing 
systems. ISILs are mostly based on existing MARC Organisation Codes 
(also known as National Union Catalogue symbols (NUC)) or similar 
existing identifiers. ISIL is defined in ISO 15511:2003.

The ISIL is a variable length identifier. The ISIL consists of a maximum 
of 16 characters, using digits (arabic numerals 0 to 9), unmodified letters 
from the basic latin alphabet and the special marks solidus (/), 
hyphen-minus (-) and colon (:). An ISIL is made up by two components:
a prefix and a library identifier, in that order, separated by a hyphen-minus.

ISIL prefixes are managed by the ISIL Registration Authority 
at http://www.bs.dk/isil/ . An ISIL prefix can either be a 
country code or a non country-code.

A country code identifies the country in which the library or 
related organization is located at the time the ISIL is assigned. 
The country code shall consist of two uppercase letters in
accordance with the codes specified in ISO 3166-1.

A non-country code prefix is any combination of Latin alphabet 
characters (upper or lower case) or digits (but not special marks). 
The prefix may be one, three, or four characters in length. 
The prefix is registered at a global level with the ISIL 
Registration Authority.

=head1 METHODS

=head2 parse ( [ $value ] )

Get and/or set the value of the ISIL. The ISIL must consist of a
prefix and a local library identifier seperated by hypen-minus (-).
Additionally it can be preceeded by "ISIL ".

The method returns '' or the valid, normalized ISIL.

=head2 canonical ( )

Because of lower/uppercase differences, two ISIL variants
that only differ in case, may not be normalized to the same string.
The 'canonical' method returns an all-upercase representation of ISIL.

=head2 hash ( )

Returns a version of ISIL to be used for indexing. This is an
uppercase string because two ISIL must not differ only in case.

=head2 prefix

Returns the ISIL prefix.

=head2 local

Returns the local library identifier.

=head1 UTILITY FUNCTIONS

=head2 sigel2isil ( $sigel )

Creates an ISIL from an old German library identifier ("Sigel"). This
function is only a heuristic, not all cases can be mapped automatically!

=head1 NOTES

We could add validity check on prefixes with an additional prefix list.
Note the usage of ISO 3166-2:1998 codes is only a recommendation in
ISO 15511:2003. Moreover some country subdivision have changed since
1998 and National ISIL Agencies may have other reasons not to use the
same codes as provided by L<Locale::SubCountry>. You can find a list
of prefixes in the source code of this package.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

our %ISIL_prefixes = (
  'AU' => ['Australia', undef],
  'CA' => ['Canada', undef],
  'CY' => ['Cyprus', undef],
  'DE' => ['Germany', undef],
  'DK' => ['Denmark', undef],
  'EG' => ['Egypt', undef],
  'FI' => ['Finland', undef],
  'FR' => ['France', undef],
  'GB' => ['United Kingdom', undef],
  'IR' => ['Islamic Republic of Iran', undef],
  'KR' => ['Republic of Korea', undef],
  'NL' => ['The Netherlands', undef],
  'NZ' => ['New Zealand', undef],
  'NO' => ['Norway', undef],
  'CH' => ['Switzerland', undef],
  'US' => ['United States of America', undef],

  # in preperation (2006)
  'M' => ['Library of Congress - outside US', undef],
  'ZDB' => ['Staatsbibliothek zu Berlin - Zeitschriftendatenbank', undef],
  'OCLC' => ['OCLC WorldCat Registry', undef],
);
