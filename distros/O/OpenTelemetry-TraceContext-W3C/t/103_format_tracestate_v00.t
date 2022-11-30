use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

eq_or_diff(format_tracestate_v00({ list_members => [
    {
        key     => 'rojo',
        value   => '00f067aa0ba902b7',
    },
    {
        key     => 'bread',
        value   => 'crumb',
    },
]}), 'rojo=00f067aa0ba902b7,bread=crumb', 'multiple entries');

eq_or_diff(format_tracestate_v00({ list_members => [
    {
        key     => 'rojo',
        value   => '00f067aa0ba902b7',
    },
]}), 'rojo=00f067aa0ba902b7', 'single entry');

eq_or_diff(format_tracestate_v00({ list_members => []}), '', 'no entries');

# max length exceeded

eq_or_diff(format_tracestate_v00({ list_members => [
    {
        key     => 'a',
        value   => 'x' x 128,
    },
    {
        key     => 'b',
        value   => 'cde',
    },
]}, { max_length => 20 }), 'b=cde', 'truncate entries > 128 first');

eq_or_diff(format_tracestate_v00({ list_members => [
    {
        key     => 'a',
        value   => 'x' x 10,
    },
    {
        key     => 'b',
        value   => 'c' x 10,
    },
]}, { max_length => 20 }), 'a=xxxxxxxxxx', 'truncate entries from the right');

eq_or_diff(format_tracestate_v00({ list_members => [
    {
        key     => 'a',
        value   => 'x' x 20,
    },
    {
        key     => 'b',
        value   => 'c' x 20,
    },
]}, { max_length => 20 }), '', 'discard all the entries');

done_testing();
