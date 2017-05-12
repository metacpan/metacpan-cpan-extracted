
use vars qw($eight $a $b $c $d $e $f $g %qq $i $template);
use String::RexxParse qw(parse);


$a = '  123 434 546.434 ([dsdsdsd])  2343 abcdefghijklmnop';

$b = "b";
$c = "c";
$d = "d";
$e = "EE";
$f = "f";
$qq{one} = 1;

$eight = 8;


print "1..16\n";

$i = 1;

for (0..1)
{
  parse $a, $template = q!$b . '.' $d '([' $e '])' $f -13 $g +($eight) $qq{one}!;
  if
  (
    $b eq '123' and $d eq '434 ' and $e eq 'dsdsdsd' and $f eq '])  2343 abcdefghijklmnop'
    and $g eq '434 ([ds' and $qq{one} eq 'dsdsd])  2343 abcdefghijklmnop'
  )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;
  
  parse $a, $template = q!$b . $d $e . $f $g $qq{one}!;
  if
  (
    $b eq '123' and $d eq '546.434' and $e eq '([dsdsdsd])' and $f eq 'abcdefghijklmnop'
    and $g eq '' and $qq{one} eq ''
  )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  parse $a, $template = q!$b 4 $d 8  $e -2 $f 9 $g -7 $qq{one}!;
  if
  (
    $b eq '  12' and $d eq '3 43' and $e eq '4 546.434 ([dsdsdsd])  2343 abcdefghijklmnop' 
    and $f eq '434' and $g eq ' 546.434 ([dsdsdsd])  2343 abcdefghijklmnop' 
    and $qq{one} eq '123 434 546.434 ([dsdsdsd])  2343 abcdefghijklmnop'
  )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  parse $a, $template = q!$b '.' $d '(['  $e '])' $f . $g $qq{one}!;
  if
  (
    $b eq '  123 434 546' and $d eq '434 ' and $e eq 'dsdsdsd' and $f eq '2343'
    and $g eq '' and $qq{one} eq ''
  )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  parse $a, $template = q!. $b $d $e . $f $g $qq{one}!;
  if
  (
    $b eq '434' and $d eq '546.434' and $e eq '([dsdsdsd])' and $f eq 'abcdefghijklmnop'
    and $g eq '' and $qq{one} eq ''
  )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  parse $a, $template = q! $b $d $e . $f $g $qq{one} .!;
  if
  (
    $b eq '123' and $d eq '434' and $e eq '546.434' and $f eq '2343'
    and $g eq 'abcdefghijklmnop' and $qq{one} eq ''
  ) 
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  @list = parse $a, $template = q! . ($b) . '([' . '])' . .!;
  if ( @list == 0 ) 
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

  parse $a, $template = q!$b!;
  if ( $b eq $a )
  { print "ok $i\n" } else { print "not ok $i\n" } $i++;

}
