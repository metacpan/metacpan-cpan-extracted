use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;

use Number::Format::FixedLocale;
use utf8;

run();
done_testing;
exit;

sub run {

    ok my $f = Number::Format::FixedLocale->new();

    is $f->format_price( -45208.23 ), "-USD 45,208.23",
      "basic price is formatted according to Number::Format default locale";

    my %settings = (
        -mon_thousands_sep => '.',
        -mon_decimal_point => ',',
        -int_curr_symbol   => '€',
        -n_cs_precedes     => 0,
        -p_cs_precedes     => 0,
    );
    my $neg_loc_price = Number::Format::FixedLocale->new( %settings )->format_price( -45208.23 );
    my $pos_loc_price = Number::Format::FixedLocale->new( %settings )->format_price( 45208.23 );

    is $neg_loc_price, "-45.208,23 €", "customized price is formatted according to settings";
    is $pos_loc_price, "45.208,23 €",  "customized price is formatted according to settings";

    return;
}
