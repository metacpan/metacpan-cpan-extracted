use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use strict;
use warnings;

# exercise output operations on filehandle proxies

my ($f1); # = Symbol::gensym();
my $z = open $f1, '>', 't/t-05a.out';
ok(-f 't/t-05a.out', 'test file created');

ok($z, 'remote filehandle opened successfully');
$z = open my $th, '<', 't/t-05a.out';
ok($z, 'test filehandle opened successfully');

my $f1_sel = select $f1;
$| = 1;
select $f1_sel;

ok($f1 && ref($f1) eq 'GLOB', 'created remote filehandle');
my $cfg = patronize($f1);
ok($cfg, 'got config for patronize glob');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($p1) = Patro->new($cfgstr)->getProxies;
ok($p1, 'client as boolean, loaded from config string');
is(CORE::ref($p1), 'Patro::N5', 'client ref');
is(Patro::ref($p1), 'GLOB', 'remote ref');
is(Patro::reftype($p1), 'GLOB', 'remote reftype');

my $c = Patro::client($p1);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';

$z = print $p1 "Hello world\n";
ok($z, 'print on proxy filehandle ok');
my $line = <$th>;
ok($line eq "Hello world\n", 'output received');

### 'print $p1' is ALWAYS treated as print($p1) NEVER as print {$p1} ();
### it cannot be used to print implicit $_ to filehandle $p1

#$_ = "Your lullaby would wake a drunken goblin.\n";
#$z = print $p1 $_;
#ok($z, 'print implicit $_ on remote filehandle');
#$line = <$th>;
#ok($line eq "Your lullaby would wake a drunken goblin.\n",
#   'output of implicit $_ received')
#    or diag $line;

$z = printf $p1 "Eye of %s\n", "Sauron";
ok($z, 'printf on proxy filehandle');
$line = <$th>;
ok($line eq "Eye of Sauron\n", 'received printf output');

ok(fileno($p1) == fileno($f1), 'fileno of proxy same as fileno of remote fh');
ok(tell($p1) > 0, 'tell of output proxy filehandle should be >0');


seek $th, tell($p1), 0;   # seek readhandle to writehandle

ok(binmode($p1), 'simple binmode ok');
print $p1 "q\n";
my $c0 = getc($th) . getc($th);
ok($c0 eq "q\cJ", 'simple binmode applied');

ok(binmode($p1,":crlf"), 'binmode with layer');
print $p1 "Z\n";
my $c1 = getc($th) . getc($th) . getc($th);
ok($c1 eq "Z\cM\cJ", 'binmode :crlf applied');

local $! = 0;
ok(!binmode($p1,":BogusLayer"), 'binmode with bogus layer failed');
ok($!, '$! set on bad binmode call');


done_testing;

END {
    unlink 't/t-05a.out' unless $ENV{KEEP};
}
