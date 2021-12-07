package SDL2::locale {
    use strict;
    use warnings;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    #
    package SDL2::Locale {
        use SDL2::Utils;
        our $TYPE = has
            _language => 'opaque',
            _country  => 'opaque';

        sub language {
            ffi->cast( 'opaque', 'string', $_[0]->_language );
        }

        sub country {
            ffi->cast( 'opaque', 'string', $_[0]->_country );
        }
        our $LIST = FFI::C::ArrayDef->new(
            ffi(),
            name    => 'LocaleList_t',
            class   => 'LocaleList',
            members => [$SDL2::Locale::TYPE]
        );
    };
    attach locale => { SDL_GetPreferredLocales => [ [], 'LocaleList_t' ] };

=encoding utf-8

=head1 NAME

SDL2::locale - SDL Locale Services

=head1 SYNOPSIS

    use SDL2 qw[:locale];
    my $locale = SDL_GetPreferredLocales( )->[0];

=head1 DESCRIPTION

SDL2::locale represents the user's preferred locale.

=head1 Functions

These may be imported by name or with the C<:locale> tag.

=head2 C<SDL_GetPreferredLocales( )>

Report the user's preferred locale.

	my $locale = SDL_GetPreferredLocales( )->[0];
	warn $locale->language;
	warn $locale->country;

This returns an array of L<SDL2::Locale> structs, the final item zeroed out.

Returned language strings are in the format xx, where 'xx' is an ISO-639
language specifier (such as "en" for English, "de" for German, etc). Country
strings are in the format YY, where "YY" is an ISO-3166 country code (such as
"US" for the United States, "CA" for Canada, etc). Country might be NULL if
there's no specific guidance on them (so you might get C<{ "en", "US" }> for
American English, but C<{ "en", undef }> means "English language,
generically"). Language strings are never C<undef>, except to terminate the
array.

Please note that not all of these strings are 2 characters; some are three or
more.

The returned list of locales are in the order of the user's preference. For
example, a German citizen that is fluent in US English and knows enough
Japanese to navigate around Tokyo might have a list like: C<[ "de", "en_US",
"jp", undef ]>. Someone from England might prefer British English (where
"color" is spelled "colour", etc), but will settle for anything like it: C<[
"en_GB", "en", undef ]>.

This function returns C<undef> on error, including when the platform does not
supply this information at all.

This might be a "slow" call that has to query the operating system. It's best
to ask for this once and save the results. However, this list can change,
usually because the user has changed a system preference outside of your
program; SDL will send an C<SDL_LOCALECHANGED> event in this case, if possible,
and you can call this function again to get an updated copy of preferred
locales.

Returns L<an array|FFI::C::Array> of locales, terminated with a locale with an
C<undef> language field. Will return C<undef> on error.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

structs xx

=end stopwords

=cut

};
1;
