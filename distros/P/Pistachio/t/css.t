use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok('Pistachio::Css::Github');
    use_ok('Pistachio::Css::Github::Perl5', 'type_to_style');
}

my $css = Pistachio::Css::Github->new;
my $expect = "font-family:Consolas,'Liberation Mono',Courier,monospace;"
           . 'padding:0 8px 0 11px;white-space:pre;font-size:13px;'
           . 'line-height:18px;float:left';

ok($css->code_div eq $expect, 
   'Pistachio::Css::Style::Github::code_div() returns expected string');

my %expect = (
    'Symbol::Sub' => 'color:#333',
    'Operator::Dereference' => 'color:#333;font-weight:bold',
    'Dont::Have' => undef,
    );

while (my ($type, $style) = each (%expect)) {
    if (defined $style) {
        ok(type_to_style($type) eq $style, "Token style for `$type`");
    }
    else {
        ok(type_to_style($type) eq '', "Empty style for unknown type `$type`");
    }
}

done_testing;
