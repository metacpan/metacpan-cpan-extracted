use warnings; use strict;
use Test::More tests => 56;

BEGIN { 
require_ok("IO::File");
use_ok("File::Temp", "tempfile"); 
require_ok("Object::Import");
}

my(my $TT, my $tn) = tempfile(UNLINK => 1);
ok($tn, "timefile name");
ok(binmode($TT));

SKIP: {
ok(open(TI, "+>", $tn), "open ti") or
	skip("could not open ti ($tn): $!", 25);
ok(binmode(TI), "binmode ti");
bless(*TI{IO}, IO::File::);

import Object::Import *TI, prefix => "ti";

ok(defined(&$_), "def\&$_") for qw"tiprint tiseek titell tigetline ticlose";
ok(tiprint("hello\nworld\n"), "&tiprint");
is(titell(), 12, "&titell");
ok(tiseek(0, 0), "&tiseek");
is(tigetline(), "hello\n", "&tigetline");

import Object::Import \*TI, prefix => "tj";

ok(defined(&$_), "def\&$_") for qw"tjprint tjseek tjtell tjgetline tjclose";
ok(tjseek(0, 0), "&tjseek");
is(tjgetline(), "hello\n", "&tjgetline");

import Object::Import *TI{IO}, prefix => "th";

ok(defined(&$_), "def\&$_") for qw"thprint thseek thtell thgetline thclose";
ok(thseek(0, 0), "&thseek");
is(thgetline(), "hello\n", "&thgetline");

ok(ticlose(), "&ticlose");
}

SKIP: {
ok(open(my $TL, "+>", $tn), "open tl") or
	skip("could not open tl ($tn): $!", 10);
ok(binmode($TL), "binmode tl");
bless(*$TL{IO}, IO::File::);

import Object::Import $TL, prefix => "tl";

ok(defined(&$_), "def\&$_") for qw"tlprint tlseek tltell tlgetline tlclose";
ok(tlprint("ahoi\nworld\n"), "&tlprint");
is(tltell(), 11, "&tltell");
ok(tlseek(0, 0), "&tlseek");
is(tlgetline(), "ahoi\n", "&tlgetline");

import Object::Import *$TL{IO}, prefix => "tv";

ok(defined(&$_), "def\&$_") for qw"tvprint tvseek tvtell tvgetline tvclose";
ok(tvseek(0, 0), "&tvseek");
is(tvgetline(), "ahoi\n", "&tvgetline");

ok(tlclose(), "&tlclose");
}

import Object::Import $TT, prefix => "tt";

ok(defined(&$_), "def\&$_") for qw"ttprint ttgetline ttclose";
ok(seek($TT, 0, 0), "seek");
is(ttgetline(), "ahoi\n", "&ttgetline");
ok(ttclose(), "&ttclose");

__END__
