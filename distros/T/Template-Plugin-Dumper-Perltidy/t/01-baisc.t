#!perl -T

use Test::More tests => 1;

use Template;
use Template::Plugin::Dumper::Perltidy;

my $tt = Template->new;
my $template = <<'TEMPLATE';
[% USE Dumper = Dumper::Perltidy %]
[% myvar = [{ title => 'This is a test header' },{ data_range =>
               [ 0, 0, 3, 9 ] },{ format     => 'bold' }] %]
[% Dumper.dump(myvar) %]
TEMPLATE
my $out;
$tt->process(\$template, {}, \$out)
        or die $tt->error;
my $val = <<'OUT';
$VAR1 = [
    { 'title'      => 'This is a test header' },
    { 'data_range' => [ 0, 0, 3, 9 ] },
    { 'format'     => 'bold' }
];
OUT

$out =~ s/(^\s+|\s+$)//g;
$val =~ s/(^\s+|\s+$)//g;

is $out, $val;

1;