use Test;
BEGIN { plan tests => 6 }
use Piffle::Template;


print "# Scalar interpolation\n";

#1
$t = '<?perl $var = "Hello World" ?>*{$var}*';
$w = '*Hello World*';
$g = Piffle::Template->expand(source => $t);
ok($g, $w);

#2
$t = '<?perl $var = "&" ?>{$var}{$var,xml}{$var,uri}{$var,raw}';
$w = '&#38;&#38;%26&';
$g = Piffle::Template->expand(source => $t);
ok($g, $w);

#3
$t = '<?perl $var = "&" ?>{$var}{$var,xml}{$var,something_random}';
$w = '&#38;&#38;&#38;';
$g = Piffle::Template->expand(source => $t);
ok($g, $w);



print "# Array and hash interpolation\n";

#4
$t = '<?perl @ary = qw{1 2 foo bar} ?>Ary: {@ary}';
$w = 'Ary: 12foobar';
$g = Piffle::Template->expand(source => $t);
ok($g, $w);

#5,6
$t = '<?perl %hash = (foo => "bar", answer => 42) ?>Hash: {%hash}';
$g = Piffle::Template->expand(source => $t);
ok($g =~ /^Hash:.*foobar/);
ok($g =~ /^Hash:.*answer42/);

