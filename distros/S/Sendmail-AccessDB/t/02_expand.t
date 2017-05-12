# t/02_expand.t - test the private functions

$|++; 
print "1..3
";
my($test) = 1;

# 1 load
use Sendmail::AccessDB;
my $foo;

$foo = join '/',  Sendmail::AccessDB::_expand_ip('192.168.1.0');
$foo eq '192.168.1.0/192.168.1/192.168/192' ? print "ok $test
" : print "not ok $test
";
$test++;

$foo = join '/',  Sendmail::AccessDB::_expand_hostname('foo.bar.example.com');
$foo eq 'foo.bar.example.com/bar.example.com/example.com/com' ? print "ok $test
" : print "not ok $test
";
$test++;

$foo = join '/',  Sendmail::AccessDB::_expand_email('joebob@foo.bar.example.com');
$foo eq 'joebob@foo.bar.example.com/joebob@/foo.bar.example.com/bar.example.com/example.com/com' ? print "ok $test
" : print "not ok $test
";
$test++;


# end of t/02_expand.t

