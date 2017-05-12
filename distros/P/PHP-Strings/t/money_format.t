#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;
BEGIN { use_ok 'PHP::Strings', ':money_format' };
use POSIX qw( locale_h );

# Good inputs
{
    my $locale = setlocale( LC_MONETARY );
    my $amount = 1234.56;

    setlocale( LC_MONETARY, 'en_US' );
    is( money_format( '%i', $amount ) => "USD 1,234.56", "Basic" );

    setlocale(LC_MONETARY, 'it_IT');
    is( money_format('%.2n', $amount ) => "EUR 1.234,56",
        "Italian national format with 2 decimals" );

    $amount = -1234.5672;

    setlocale(LC_MONETARY, 'en_US');
    is( money_format('%(#10n', $amount) => '($        1,234.57)',
        "US national format, using () for negative numbers and 10 digits for left precision" );

    is( money_format('%=*(#10.2n', $amount ) => '($********1,234.57)',
        "As above, more precision, different fill" );

    setlocale(LC_MONETARY, 'de_DE');
    is( money_format('%=*^-14#8.2i', 1234.56) => ' 1234,56**** EUR',
        "German, width, left and right precision, no grouping" );

    # Let's add some blurb before and after the conversion specification
    setlocale(LC_MONETARY, 'en_GB');
    my $fmt = 'The final value is %i (after a 10%% discount)';
    is( money_format($fmt, 1234.56) =>
        'The final value is GBP 1,234.56 (after a 10% discount)',
        "Length formatting"
    );

    setlocale( LC_MONETARY, $locale );

}

# Extended beyond PHP's capabilities
TODO: {
    local $TODO = "I've not been bored enough, yet.";

    my $locale = setlocale( LC_MONETARY );
    setlocale( LC_MONETARY, 'en_AU' );

    eval {
        is( money_format( '%i foo %i', 12.45, 65.56 ) =>
            "AUD 12.45 foo AUD 65.56",
            "Look, two arguments"
        );
    };
    fail("Multi arg") if $@;

    setlocale( LC_MONETARY, $locale );
}

# Bad inputs
{
    eval { money_format( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { money_format( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { money_format( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for mode" );
    eval { money_format( "Foo", "Not a number" ) };
    like( $@, qr/^Parameter #2.*is a number.*callback/, "Mode not a number" );
}
