# $Id: test.pl,v 1.3 2003/09/03 15:11:21 cvspub Exp $
use Test;
BEGIN { plan tests => 1 };
ok(1);

use IO::String;
$/ = "\n";

print "<";
use PerlIO::via::Babelfish  source => 'English',  target => 'Spanish';
binmode(STDOUT, ":via(Babelfish)") or die $!;
print "i love you you you you";

binmode(STDOUT);
print ">";
print "\nIf you see 'te amo usted usted usted', then the module seems ok.\n"
