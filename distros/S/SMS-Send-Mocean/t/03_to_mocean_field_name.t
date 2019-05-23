use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use SMS::Send::Mocean;

my $params = {
    _foo => 'mocean-foo',
    _foo_bar => 'mocean-foo-bar',
    _foo_bar_baz => 'mocean-foo-bar-baz',
};

while ((my $param, my $mocean_param) = each %{$params}) {
    is(SMS::Send::Mocean::_to_mocean_field_name($param), $mocean_param,
        'Expect parameter name converted correctly');
}

done_testing;
