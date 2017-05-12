use Test;
BEGIN { plan tests => 2 }
use Piffle::Template;

print "# Loops: while and for\n";

#1
$tmpl = <<'__TMPL__';
for loops:
<?perl
  for (1 .. 5)
  {
?>
[iteration {$_}]<?perl
  }
?>
done
__TMPL__
$want = <<'__WANT__';
for loops:

[iteration 1]
[iteration 2]
[iteration 3]
[iteration 4]
[iteration 5]
done
__WANT__
$got = Piffle::Template->expand(source => $tmpl);
ok($got, $want);

#2
$tmpl = <<'__TMPL__';
nested loops --
<?perl
  for $x (qw{a b c})
  {
    for $y (0, 1, 2, 3, 4)
    {
      my $y = $y+1;
?> {$x}{$y}<?perl
    }
?>
<?perl
  }
?>end
__TMPL__
$want = <<'__WANT__';
nested loops --
 a1 a2 a3 a4 a5
 b1 b2 b3 b4 b5
 c1 c2 c3 c4 c5
end
__WANT__
$got = Piffle::Template->expand(source => $tmpl);
ok($got, $want);


