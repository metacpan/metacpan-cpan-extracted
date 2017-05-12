# t/03_functions.t; test the basic functions

$|++; 
if(-e "/usr/sbin/makemap" && -f "/usr/sbin/makemap" && -x "/usr/sbin/makemap")
{
	print "1..7 
";
}
else	
{
	print "1..0 # SKIP /usr/sbin/makemap not found
";
	exit 0;
}

my($test) = 1;

# 1 load
use Sendmail::AccessDB;
my $foo;

$Sendmail::AccessDB::DB_FILE="./t/test.db";
system("touch ./t/test.db");
system("/usr/sbin/makemap hash ./t/test < ./t/test");


my $friend = Sendmail::AccessDB::spam_friend('foo@bar.com');
if ( (defined $friend) and ($friend eq 'FRIEND')) 
  { print "ok $test\n";}else{ print "not ok $test\n"; }
$test++;

$friend = Sendmail::AccessDB::spam_friend('foo@bar.de');
if ( (defined $friend) and ($friend eq 'FOE'))
  { print "ok $test\n";}else{ print "not ok $test\n"; }
$test++;


my $whitelisted = Sendmail::AccessDB::whitelisted('foo.test.example.com','type'=>'hostname');
if ( (defined $whitelisted) and ($whitelisted))
  { print "ok $test\n" }else{ print "not ok $test\n"; }
$test++;

my $should_fail = Sendmail::AccessDB::whitelisted('bar.example.com');
if ($should_fail) { print "not ok $test\n";} else { print "ok $test\n"; }
$test++;

my $lookup = Sendmail::AccessDB::lookup('foo.bar.tld','qualifier'=>'Qual');
if ( (defined $lookup) and ($lookup eq 'OK'))
   { print "ok $test\n" } else { print "not ok $test\n"; };
$test++;

my $wltwo = Sendmail::AccessDB::whitelisted('user@foo.bar.tld','qualifier'=>'Qual','type'=>'mail');
if ($wltwo) { print "ok $test\n" } else { print "not ok $test\n"; };
$test++;

my $should_be_skip = Sendmail::AccessDB::lookup('user@foo.bar.tld2','qualifier'=>'Qual','type'=>'mail');
if ($should_be_skip eq "SKIP") { print "ok $test\n" } else { print "not ok $test\n"; };
$test++;



# end of t/03_functions.t

