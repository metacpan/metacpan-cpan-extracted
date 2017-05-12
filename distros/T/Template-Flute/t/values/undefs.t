#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Template::Flute;
use Data::Dumper;

my $spec =<<'EOF';
<specification>
<value name="description" class="product-description" />
<form name="login" id="login">
<field name="email" id="email" />
<field name="password" id="password" />
</form>
</specification>
EOF

my $html =<<'EOF';
<html>
<body>
<h1>Title</h1>>
<div class="product-description">TEST</div>
<div class="login">
<form name="login" id="login">
<input type="email" id="email">
<input type="password" id="password">
</form>
</div>
</body>
</html>
EOF

my $flute = Template::Flute->new(
                                 template => $html,
                                 specification => $spec,
                                 values => {description => undef},
                                );
print Dumper($flute->{values});
my $out = $flute->process;

unlike $out, qr/TEST/, "product-description class was removed";
like $out, qr{<input id="email" type="email" />}, "input email is here";
like $out, qr{<input id="password" type="password" />}, "input password is here";

$flute = Template::Flute->new(
                                 template => $html,
                                 specification => $spec,
                                 values => {},
                                );

$out = $flute->process;

unlike $out, qr/TEST/, "product-description class was removed";
like $out, qr{<input id="email" type="email" />}, "input email is here";
like $out, qr{<input id="password" type="password" />}, "input password is here";

