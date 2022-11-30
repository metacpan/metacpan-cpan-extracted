use FindBin; use lib "${FindBin::RealBin}/..";
use t::lib::Test;

my $parsed = parse_tracestate('');
eq_or_diff($parsed->{list_members}, []);

update_tracestate($parsed, 'a', 'b');
eq_or_diff($parsed->{list_members}, [
    { key => 'a', value => 'b' },
]);

update_tracestate($parsed, 'b', 'c');
eq_or_diff($parsed->{list_members}, [
    { key => 'b', value => 'c' },
    { key => 'a', value => 'b' },
]);

update_tracestate($parsed, 'a', 'd');
eq_or_diff($parsed->{list_members}, [
    { key => 'a', value => 'd' },
    { key => 'b', value => 'c' },
]);

done_testing();
