
BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(strtr);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

%hash = strtr(
    'しずけさや　いはにしみいる　せみのこえ',
    "あ-こや-ろ", "", "h");
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq 'い=>2:え=>1:け=>1:こ=>1:や=>1:る=>1'
    ? "ok" : "not ok", " 2\n";

$hash = strtr(
    'しずけさや　いはにしみいる　せみのこえ',
    "あ-こや-ろ", "", "h");
$join = join ':', map "$_=>$$hash{$_}", sort keys %$hash;

print $join eq 'い=>2:え=>1:け=>1:こ=>1:や=>1:る=>1'
    ? "ok" : "not ok", " 3\n";

%hash = strtr(
    "Caesar Aether Goethe Europaeae Oestrone Uenoeki",
    "aeoeueAeOeUe",
    "&auml;&ouml;&ouml;&Auml;&Ouml;&Uuml;",
    "h",
    "[aouAOU]e",
    "&[aouAOU]uml;");
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq "Ae=>1:Oe=>1:Ue=>1:ae=>3:oe=>2"
    ? "ok" : "not ok", " 4\n";

%hash = strtr('日本語のカタカナ', 'ぁ-んァ-ヶｦ-ﾟ', '', 'h');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq 'の=>1:カ=>2:タ=>1:ナ=>1'
    ? "ok" : "not ok", " 5\n";

$str = '日本語のカタカナ';
%hash = strtr(\$str, 'ぁ-んァ-ン', 'ァ-ンぁ-ん', 'h');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq 'の=>1:カ=>2:タ=>1:ナ=>1'
    ? "ok" : "not ok", " 6\n";
print $str eq '日本語ノかたかな'
    ? "ok" : "not ok", " 7\n";

$str = '日本語のカタカナの本';
%hash = strtr(\$str, 'ぁ-んァ-ン', '', 'cdh');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq '語=>1:日=>1:本=>2'
    ? "ok" : "not ok", " 8\n";
print $str eq 'のカタカナの'
    ? "ok" : "not ok", " 9\n";

$str = '日本語のカタカナの本';
%hash = strtr(\$str, 'ぁ-んァ-ン', '', 'dh');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq 'の=>2:カ=>2:タ=>1:ナ=>1'
    ? "ok" : "not ok", " 10\n";
print $str eq '日本語本'
    ? "ok" : "not ok", " 11\n";

$str = '日本語のカタカナの本';
%hash = strtr(\$str, 'ぁ-んァ-ン', '', 'ch');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq '語=>1:日=>1:本=>2'
    ? "ok" : "not ok", " 12\n";
print $str eq '日本語のカタカナの本'
    ? "ok" : "not ok", " 13\n";

$str = '本当の日本語のカタカナの本';
%hash = strtr(\$str, 'ぁ-んァ-ン', '!', 'ch');
$join = join ':', map "$_=>$hash{$_}", sort keys %hash;

print $join eq '語=>1:当=>1:日=>1:本=>3'
    ? "ok" : "not ok", " 14\n";
print $str eq '!!の!!!のカタカナの!'
    ? "ok" : "not ok", " 15\n";

1;
__END__
