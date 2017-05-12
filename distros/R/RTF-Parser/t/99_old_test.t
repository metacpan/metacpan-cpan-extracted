use strict;
use warnings;

use RTF::HTML::Converter;
my $result;
my $self = new RTF::HTML::Converter(Output => \$result);	

my @RTF_Documents = split (/\n/, <<'DATA');
{} # Ok!
{\par} # Ok!
{string\par} # Ok!
{\b bold \i Bold Italic \i0 Bold again} # Ok!
{\b bold {\i Bold Italic }Bold again} # Ok!
{\b bold \i Bold Italic \plain\b Bold again} # Ok!
DATA

my @HTML_Documents = (<<'D1;',<<'D2;',<<'D3;',<<'D4;',<<'D5;', <<'D6;');
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>
 </body>
</html>
D1;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>
 </body>
</html>
D2;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>

<p>string</p>
 </body>
</html>
D3;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>
<b>bold <i>Bold Italic </i>Bold again</b> </body>
</html>
D4;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>
<b>bold <i>Bold Italic </i>Bold again</b> </body>
</html>
D5;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>
<html>
<body>
<b>bold <i>Bold Italic </i>Bold again</b> </body>
</html>
D6;

print "1..", @RTF_Documents+0, "\n";
my $test = 0;
foreach (@RTF_Documents) {
  $test++;
  s/\#.*//;
  $result = '';
  $self->parse_string($_);
  if ($result eq $HTML_Documents[$test-1]) {
    print "ok $test\n";
  } else {
    print STDERR "$_\n";
    print STDERR $HTML_Documents[$test-1], "\n";
    print STDERR "$result\n";
  }
}

__DATA__



