#! perl
#
# Test for lowerdash filter

use strict;
use warnings;
use Test::More tests => 3;

use Template::Flute;

# lowerdash filter
my $xml = <<EOF;
<specification name="filters">
    <value name="text" filter="lower_dash" />
</specification>
EOF

my $html = <<EOF;
    <div class="text">foo</div>
EOF

my $tests = {
    'Red Wine'                     => 'red-wine',
    'Red Wine is Delicious'        => 'red-wine-is-delicious',
    'Red Wine    is     Delicious' => 'red-wine-is-delicious',
};
for my $key ( keys %$tests ) {
    my $flute = Template::Flute->new(
        specification => $xml,
        template      => $html,
        values        => { text => $key }
    );
    my $ret = $flute->process();
    ok( $ret =~ m{<div class="text">$tests->{$key}</div>},
        qq{lower_dash filter: $ret} );
}
