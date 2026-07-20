##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/PP.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/17
## Modified 2026/07/19
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package PersonName::Format::PP;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'PersonName::Format' );
    use vars qw( $VERSION %SCRIPT_NAME_TO_CODE );
    use Unicode::UCD ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

# Populated on first use by _load_script_names().
our %SCRIPT_NAME_TO_CODE;

my $SCRIPT_NAMES_LOADED = 0;
my $SCRIPT_CACHE        = {};

sub _first_grapheme
{
    my $value = shift( @_ );
    if( !defined( $value ) || !length( $value ) )
    {
        return( '' );
    }

    # Extract the first grapheme cluster using \X.
    # On Perl < 5.28, \X does not fully implement UAX #29 rev 29+:
    #   - Regional Indicator pairs (U+1F1E6..U+1F1FF): not joined by \X on Perl < 5.18
    #   - ZWJ sequences (U+200D + emoji): not joined by \X on Perl < 5.28
    # We extend the result manually for those two cases.
    my( $grapheme ) = $value =~ /\A(\X)/s;
    return( '' ) unless( defined( $grapheme ) && length( $grapheme ) );

    # UAX #29 rule GB12/GB13: two adjacent Regional Indicators form one grapheme.
    # If \X returned a single RI codepoint, check whether the next character is also RI.
    if( length( $grapheme ) == 1 )
    {
        my $uv = ord( $grapheme );
        if( $uv >= 0x1F1E6 && $uv <= 0x1F1FF )
        {
            my $rest = substr( $value, 1 );
            if( length( $rest ) )
            {
                my $next_uv = ord( substr( $rest, 0, 1 ) );
                if( $next_uv >= 0x1F1E6 && $next_uv <= 0x1F1FF )
                {
                    $grapheme .= substr( $rest, 0, 1 );
                }
            }
            return( $grapheme );
        }
    }

    # UAX #29 rule GB11: ZWJ sequences.
    # \X handles ZWJ sequences inconsistently across Perl versions:
    #   Case B (most old Perls): \X consumes [base + ZWJ] but stops before the following emoji.
    #   Case C (very old Perls): \X consumes [base] and stops before ZWJ itself.
    # We detect both by checking whether $grapheme ends with ZWJ (case B) or
    # whether the next unconsumed character is ZWJ (case C), then continue consuming.
    my $pos = length( $grapheme );
    while(1)
    {
        my $zwj_at_end = ( $pos > 0 && ord( substr( $grapheme, -1, 1 ) ) == 0x200D );
        my $zwj_at_pos = ( $pos < length( $value ) && ord( substr( $value, $pos, 1 ) ) == 0x200D );

        if( $zwj_at_end )
        {
            # Case B: ZWJ is the last char of what \X consumed.
            # The character at $pos must exist and be non-ASCII for us to continue.
            last unless( $pos < length( $value ) );
            my $after = ord( substr( $value, $pos, 1 ) );
            last unless( $after > 0x7F );
            $grapheme .= substr( $value, $pos, 1 );
            $pos++;
        }
        elsif( $zwj_at_pos )
        {
            # Case C: ZWJ is the next unconsumed character.
            # The character after ZWJ must exist and be non-ASCII.
            last unless( $pos + 1 < length( $value ) );
            my $after_zwj = ord( substr( $value, $pos + 1, 1 ) );
            last unless( $after_zwj > 0x7F );
            $grapheme .= substr( $value, $pos, 2 );
            $pos += 2;
        }
        else
        {
            last;
        }

        # Consume any trailing Extend codepoints: emoji modifiers (U+1F3FB..U+1F3FF)
        # and variation selectors (U+FE00..U+FE0F) that may follow a ZWJ base.
        # Combining marks are already consumed by the preceding \X call.
        while( $pos < length( $value ) )
        {
            my $uv = ord( substr( $value, $pos, 1 ) );
            last unless(
                ( $uv >= 0xFE00 && $uv <= 0xFE0F ) ||
                ( $uv >= 0x1F3FB && $uv <= 0x1F3FF )
            );
            $grapheme .= substr( $value, $pos, 1 );
            $pos++;
        }
    }

    return( $grapheme );
}

sub _get_name_script
{
    my $surname = shift( @_ );
    my $given   = shift( @_ );

    foreach my $value ( $surname, $given )
    {
        if( !defined( $value ) ||
            !length( $value ) )
        {
            next;
        }

        # Do not use split(//u, ...) here: the /u modifier on split was only
        # introduced in Perl 5.14 and produces warnings on earlier versions.
        # The string is already a decoded Unicode character sequence, so
        # split(//, ...) correctly splits on codepoint boundaries.
        foreach my $char ( split( //, $value ) )
        {
            my $script = _script_code_for_uv( ord( $char ) );
            if( $script eq 'Zyyy' ||
                $script eq 'Zinh' ||
                $script eq 'Zzzz' )
            {
                next;
            }
            return( $script );
        }
    }

    return( 'Zzzz' );
}

sub _load_script_names
{
    return if $SCRIPT_NAMES_LOADED;
    require 'PersonName/Format/ScriptNames.pl';
    $SCRIPT_NAMES_LOADED = 1;
}

sub _script_code_for_uv
{
    my $uv = shift( @_ );
    if( exists( $SCRIPT_CACHE->{ $uv } ) )
    {
        return( $SCRIPT_CACHE->{ $uv } );
    }

    my $script_name = Unicode::UCD::charscript( $uv );
    my $script      = 'Zzzz';

    if( defined( $script_name ) )
    {
        # Unicode::UCD::prop_value_aliases() was introduced in Perl 5.16.
        # On earlier versions we fall back to our bundled ScriptNames.pl.
        if( $] >= 5.016 )
        {
            my @aliases = Unicode::UCD::prop_value_aliases( 'sc', $script_name );
            $script = $aliases[0] || 'Zzzz';
        }
        else
        {
            _load_script_names();
            $script = $SCRIPT_NAME_TO_CODE{ $script_name } || 'Zzzz';
        }
    }

    $SCRIPT_CACHE->{ $uv } = $script;
    return( $script );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::PP - Pure-Perl backend for PersonName::Format

=head1 DESCRIPTION

This module provides the pure-Perl implementations of internal Unicode primitives used by L<PersonName::Format>. It is not part of the public API.

The XS backend must return exactly the same values as these functions.

=head1 FUNCTIONS

=head2 _first_grapheme

    my $grapheme = PersonName::Format::PP::_first_grapheme( $value );

Returns the first Unicode extended grapheme cluster from C<$value>. Returns an empty string for an undefined or empty value.

The implementation uses C<\X> as its primary mechanism, but extends the result manually to cover two cases that C<\X> does not handle correctly on older Perl versions:

=over 4

=item Regional Indicator pairs (UAX #29 rule GB12/GB13)

Two adjacent Regional Indicator codepoints (U+1F1E6..U+1F1FF) must form a single flag grapheme such as C<\x{1F1EF}\x{1F1F5}> (🇯🇵). C<\X> handles this correctly from Perl 5.18 onward; on Perl 5.16 only the first codepoint is returned.

=item ZWJ emoji sequences (UAX #29 rule GB11)

A sequence of the form C<base + ZWJ (U+200D) + emoji> must form a single grapheme such as C<\x{1F469}\x{200D}\x{1F4BB}> (👩‍💻). C<\X> handles this correctly from Perl 5.28 onward. On intermediate versions, C<\X> consumes C<base + ZWJ> but stops before the following emoji (case B). On very old versions, C<\X> stops before the ZWJ itself (case C). Both are corrected by post-processing.

=back

Both cases are corrected by post-processing the C<\X> result at the codepoint level. The XS backend must return exactly the same values as this function.

=head2 _get_name_script

    my $script = PersonName::Format::PP::_get_name_script(
        $surname,
        $given,
    );

Returns the first significant Unicode Script code found in the surname and then the given name. C<Common>, C<Inherited>, and C<Unknown> are ignored.
Returns C<Zzzz> when no significant script is found.

=head2 _script_code_for_uv

    my $code = PersonName::Format::PP::_script_code_for_uv( $codepoint );

Returns the ISO 15924 four-letter script code for a Unicode codepoint.

On Perl 5.16 and later, C<Unicode::UCD::prop_value_aliases()> is used directly to resolve the script name returned by C<Unicode::UCD::charscript()>. On earlier versions, the mapping is loaded on first use from C<PersonName/Format/ScriptNames.pl> via C<require>. In both cases, processes that never call C<_get_name_script> pay no memory cost for the table.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
