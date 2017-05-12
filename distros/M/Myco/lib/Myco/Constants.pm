package Myco::Constants;

###############################################################################
# $Id: Constants.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Constants

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 SYNOPSIS

  use Myco::Constants;

  # Language data
  $arrayref = Myco::Constants->language_codes;
  $hashref = Myco::Constants->language_hash_by_code;

=head1 DESCRIPTION

A simple container for constant data.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;

##############################################################################
# Programatic Dependencies
use Locale::Country;
use Locale::Language;

##############################################################################
# Constants
##############################################################################
use constant PREF_LANG => 'en';
use constant PREF_CITI => 'us';


##############################################################################
# Methods
##############################################################################

=head1 CLASS METHODS

=head2 country_codes

List context:  returns array of ISO 3166-1 country codes, alpha sorted.
Scalar context:  returns reference to this array.

=cut

my $_country_hash;
for my $code ( @{ [all_country_codes()] } ) {
    $_country_hash->{$code} = code2country($code);
}

my @_country_codes =
  ( '__select__',
    '__blank__',
    PREF_CITI,
    '__blank__',
    '__other__',
    '__blank__',
    ( sort {$_country_hash->{$a} cmp $_country_hash->{$b}}
                                              keys %$_country_hash ),
    '__blank__',
    '__other__',
  );


sub country_codes {
    wantarray ? @_country_codes : \@_country_codes;
}

=head2 country_hash_by_code

List context:  returns hash of country code/name key/value pairs.
Scalar context:  returns reference to this array.

=cut

sub country_hash_by_code {
    wantarray ? %$_country_hash: $_country_hash;
}

=head2 language_codes

List context:  returns array of ISO 639 language codes, alpha sorted except
that the preferred language is listed first (hard-coded at present).
Scalar context:  returns reference to this array.

=cut

my $_lang_hash;
for my $code ( all_language_codes() ) {
    $_lang_hash->{$code} = code2language($code);
}

my @_language_codes =
  ( '__select__',
    '__blank__',
    PREF_LANG,
    '__blank__',
    sort { $_lang_hash->{$a} cmp $_lang_hash->{$b} }
    grep {$_ ne PREF_LANG} keys %$_lang_hash
  );

sub language_codes {
    wantarray ? @_language_codes : \@_language_codes;
}


=head2 language_hash_by_code

List context:  returns hash of language code/full_name key/value pairs.
Scalar context:  returns reference to this hash.

=cut

sub language_hash_by_code {
    wantarray ? %$_lang_hash : $_lang_hash;
}



1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Constants::Test|Myco::Constants::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
