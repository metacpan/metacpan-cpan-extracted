
BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(strtr);
$loaded = 1;
print "ok 1\n";

#####

print "ok 2\n";

# modified from a part of Perl 5.6.0 <t/op/subst.t>
{
  $_ = "aaaaa";
  print strtr(\$_, 'a', 'b') == 5
    ? "ok" : "not ok", " 3\n";
  print strtr(\$_, 'a', 'b') == 0
    ? "ok" : "not ok", " 4\n";
  print strtr(\$_, 'b', '' ) == 5
    ? "ok" : "not ok", " 5\n";
  print strtr(\$_, 'b', 'c', 's') == 5
    ? "ok" : "not ok", " 6\n";
  print strtr(\$_, 'c', '' ) == 1
    ? "ok" : "not ok", " 7\n";
  print strtr(\$_, 'c', '', 'd') == 1
    ? "ok" : "not ok", " 8\n";
  print $_ eq "" ? "ok" : "not ok", " 9\n";

  my($x);
  $_ = "Now is the %#*! time for all good men...";
  print 7 == ($x = strtr \$_, 'a-zA-Z ', '', 'cd')
    ? "ok" : "not ok", " 10\n";
  print 8 == strtr(\$_, ' ', ' ', 's')
    ? "ok" : "not ok", " 11\n";

  $_ = 'abcdefghijklmnopqrstuvwxyz0123456789';
  strtr(\$_, 'a-z', 'A-Z');
  print $_ eq 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' ?
	"ok" : "not ok", " 12\n";

  # same as tr/A-Z/a-z/;
  strtr(\$_, "\101-\132", "\141-\172");

  print $_ eq 'abcdefghijklmnopqrstuvwxyz0123456789' ?
	"ok" : "not ok", " 13\n";

  if (ord("+") == ord(",") - 1 && ord(",") == ord("-") - 1 &&
    ord("a") == ord("b") - 1 && ord("b") == ord("c") - 1) {
    $_ = '+,-';
    strtr(\$_, '+--', 'a-c');
    print "not " unless  $_ eq 'abc';
  }
    print "ok 14\n";

  $_ = '+,-';
  strtr(\$_, '+\--', 'a/c');
  print $_ eq 'a,/' ? "ok" : "not ok", " 15\n";

  $_ = '+,-';
  strtr(\$_, '-+,', 'ab\-');
  print $_ eq 'b-a' ? "ok" : "not ok", " 16\n";
}

1;
__END__
