package Pcore::Lib::IDN;

use Pcore -const, -export;

# https://libidn.gitlab.io/libidn2/manual/libidn2.html

our $EXPORT = {
    ALL   => [qw[domain_to_ascii domain_to_utf8 ]],
    CONST => [qw[$IDN2_NFC_INPUT $IDN2_ALABEL_ROUNDTRIP $IDN2_TRANSITIONAL $IDN2_NONTRANSITIONAL $IDN2_ALLOW_UNASSIGNED $IDN2_USE_STD3_ASCII_RULES]],
};

const our $IDN2_NFC_INPUT            => 1;    # apply NFC normalization on input
const our $IDN2_ALABEL_ROUNDTRIP     => 2;    # apply additional round-trip conversion of A-label inputs
const our $IDN2_TRANSITIONAL         => 4;    # perform Unicode TR46 transitional processing
const our $IDN2_NONTRANSITIONAL      => 8;    # perform Unicode TR46 non-transitional processing
const our $IDN2_ALLOW_UNASSIGNED     => 16;
const our $IDN2_USE_STD3_ASCII_RULES => 32;

use Inline(
    C => <<'C',
# include "idn2.h"

SV* domain_to_utf8 ( char* domain, ... ) {
    char *output;

    Inline_Stack_Vars;

    // Function: int idn2_to_unicode_8z8z (const char *input, char **output, int flags)
    //    input: Input zero-terminated UTF-8 string.
    //    output: Newly allocated UTF-8 output string.
    //    flags: optional idn2_flags to modify behaviour.

    int rc = idn2_to_unicode_8z8z( domain, &output, Inline_Stack_Items == 2 ? SvIV(Inline_Stack_Item(1)) : 0 );

    if ( rc == IDNA_SUCCESS ) {
        SV *res = newSVpvn_flags( output, strlen(output), SVf_UTF8 );

        idn2_free(output);

        return res;
    }
    else {
        croak( "IDN2: %s", idn2_strerror(rc) );
    }
}

SV* domain_to_ascii ( char* domain, ... ) {
    char *output;

    Inline_Stack_Vars;

    // Function: int idn2_to_ascii_8z (const char *input, char **output, int flags)
    //    input: zero terminated input UTF-8 string.
    //    output: pointer to newly allocated output string.
    //    flags: optional idn2_flags to modify behaviour.

    int rc = idn2_to_ascii_8z( domain, &output, Inline_Stack_Items == 2 ? SvIV(Inline_Stack_Item(1)) : IDN2_NONTRANSITIONAL );

    if ( rc == IDNA_SUCCESS ) {
        SV *res = newSVpvn( output, strlen(output) );

        idn2_free(output);

        return res;
    }
    else {
        croak( "IDN2: %s", idn2_strerror(rc) );
    }
}
C
    libs      => $MSWIN ? '-lidn2' : '-l:libidn2.a',
    ccflagsex => '-Wall -Wextra -Ofast -std=c11',

    # build_noisy => 1,
    # force_build => 1,
);

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::IDN - libidn2 bindings

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
