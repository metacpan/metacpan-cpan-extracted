use Test::More;
use Carp 'verbose';
use Patro ':test', ':insecure';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use strict;
use warnings;

# exercise operations for proxies to dirhandles
#   -X, chdir, lstat, opendir/readdir/rewinddir/seekdir/telldir,closedir ,stat
#
#   opendir is an insecure operation
#   chdir is an insecurre operation

my $d9 = Symbol::gensym;
opendir $d9, 't';

my $p9 = getProxies( patronize($d9) );
ok($p9 && CORE::ref($p9) eq 'Patro::N5' && Patro::ref($p9) eq 'GLOB',
   'ref/reftype for proxy ok');

 SKIP: {
     if ($] < 5.012) {
	 skip("-X on proxy dirhandle requires Perl v5.12", 3);
     }
     if ($^O eq 'MSWin32') {
	 skip("The dirfd function is unimplemented", 3);
     }
     my $z = -r $p9;
     ok($z, '-r op on proxy dirhandle ok');
     my $s = -s $p9;
     ok($s || $s eq '0', '-s op on proxy dirhandle ok');
     my $M = -M $p9;
     ok($M ne '', "-M op on proxy dirhandle ok");
}

my $f = readdir $p9;
ok($f =~ /[.tm]$/,
   'read file name from proxy dirhandle');
my $t = telldir $p9;
 SKIP: {
     if ($^O eq 'freebsd') {
	 skip("on some OS don't expect telldir to return 0 after first read",1);
     }
     ok($t != 0, 'telldir from proxy dirhandle nonzero after 1 read');
}
my @f = readdir $p9;
ok(@f > 5, 'readdir from proxy dirhandle in list context');
my @c = grep { !/t$/ } $f, @f;
ok(@c == 3, '3 files found through proxy dirhandle that don\'t end in t')
    or diag "Found ",0+@c," extra files in t/: @c";
my $z = seekdir $p9, $t;
my $t2 = telldir $p9;
SKIP: {
    if ($^O eq 'freebsd') {
	skip("on some OS don't expect telldir to be consistent", 1);
    }
    ok($z && $t2 == $t, 'seekdir through proxy dirhandle');
}
$z = rewinddir $p9;
my $t3 = telldir($p9);
ok($z, 'rewinddir through proxy dirhandle');
 SKIP: {
     if ($^O eq 'freebsd') {
	 skip("on some OS don't expect telldir to return 0 after rewinddir",1);
     }
     # on freebsd, we do not expect telldir to return 0
     ok(0 == $t3, 'rewinddir makes telldir return 0') or diag($t3);
}
my $f2 = readdir $p9;
ok($f eq $f2, 'readdir after rewinddir returns same file as first read');

$z = closedir $p9;
 SKIP: {
     my $cc = Patro::client($p9);
     if ($cc->{config}{style} ne 'threaded') {
	 skip("closedir may not work on forked server?",2);
     }
     ok($z, 'closedir on proxy dirhandle');
     local $! = 0;
     $f2 = readdir $p9;
     ok(!defined($f2) && $!, 'readdir on closed proxy dirhandle fails');
}

$z = opendir $p9, 't';
ok($z, 'opendir on proxy filehandle');
 SKIP: {
     if ($^O eq 'MSWin32') {
	 skip("The fchdir function is unimplemented", 1);
     }
     $z = chdir $p9;
     ok($z, 'chdir on proxy dirhandle');
}

done_testing;
