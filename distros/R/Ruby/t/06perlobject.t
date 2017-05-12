#!perl

use warnings;
use strict;

package T;

use Test::More tests => 157;

BEGIN{ use_ok('Ruby', ':DEFAULT', 'rb_const', -class => 'GC') }

is rb_const(Perl::VERSION), sprintf("%vd", $^V), "Perl::VERSION";

sub add{
	$_[0] + $_[1];
}
sub method{
	$_[1] + 41;
}
sub list{
	(1, 2, 3)
}

sub m{
	my($block) = @_;;
	$block->(42);
}

sub how_many_want{
	wantarray;
}

sub block{
	is $_[0], "as block", "code as block";
}

our $scalar = 'T::scalar';
our @ary   = ('foo', 'bar', 'baz');
our %hash  = (key => 'T::hash');

our $G = 'S';
our %G = qw(H H);
our @G = ('A');
open G, '<', __FILE__;
sub G(){}


{
	package U;

	use Test::More;
	our $s1 = 'U::scalar1';
	our $s2 = 'U::scalar2';
}


rb_eval <<'EOS', __PACKAGE__, __FILE__, __LINE__;

is(__PACKAGE__, 'T', "__PACKAGE__");

is(add(1, 2), 3, "call perl function");

is(add("foo", "bar"), "foobar", "redo");
m{ |v|
	is v, 42, "call perl function with block";
}

GC.start;

is(add(3.14, 0.0015), "3.1415", "redo after GC.start");

sv = Perl.String("foo");

is(sv, "foo", "Perl.String");
ok(sv  == "foo");
ok(sv.defined?, "sv.defined?");
ok(!sv.undef?, "sv.undef?");
ok(sv.true?, "sv.true?");
ok(!sv.false?, "sv.false?");

sv.concat("bar");
is(sv, "foobar", "Perl::Scalar concat");
sv.concat("!");
is(sv, "foobar!", "Perl::Scalar concat");

hash = Hash.new;

hash[sv] = sv;

is(hash[sv], sv, "hash() & eql?()");
isnt(hash["foobar!"], sv);
is(hash[Perl.String("foobar!")], sv);

sv.set("hoge".to_perl);
is(sv, "hoge", "Perl::Scalar set");

hash = Perl::Hash.new;

ok(hash.kind_of?(Perl::Hash), "Perl::Hash");

hash[Perl.String("100")] = "OK";

is(hash[Perl.String("100")], "OK", "Perl::Hash aset/aref");
is(hash["100"],              "OK");

ok(hash.exists("100"), "exist");
ok(!hash.exists("foo"), "not exist");
ok(!hash.has_key?("foo"), "not has_key?");

hash.each_key{ |k|
	is k, "100", "Perl::Hash each_key";
}
hash.each_value{ |v|
	is v, "OK", "Perl::Hash each_value";
}

count = 1;
hash.each_pair{ |k,v|
	is count, 1, "Perl::Hash each_pair"; # only 1

	is k, "100";
	is v, "OK";

	count += 1;
};

hash.delete("100");
ok !hash.exists("100"), "Perl::Hash delete";

# perl == perl

ok(Perl.String("foo")  == Perl.String("foo"), "perlstr == perlstr");
ok(Perl.String("foo")  != Perl.String("bar"), "perlstr != perlstr");

ok(Perl.String("10")   == Perl.Integer(10),  "perlstr == perlint");
ok(Perl.String("10")   != Perl.Integer(11),  "perlstr != perlint");

ok(Perl.String("10")   == Perl.Float(10),    "perlstr == perlfloat");
ok(Perl.String("10")   != Perl.Float(11),    "perlstr != perlfloat");

# perl == ruby

ok(Perl.String("foo")  == String("foo"),    "perlstr == rubystr");
ok(Perl.String("foo")  != String("FOO"),    "perlstr != rubystr");

ok(Perl.String("10")   == Integer(10),     "perlstr == rubyint");
ok(Perl.String("10")   != Integer(11),     "perlstr != rubyint");

ok(Perl.String("0.1")  == Float(0.1),      "perlstr == rubyfloat");
ok(Perl.String("0.1") !=  Float(1.0),      "perlstr != rubyfloat");

ok(Perl.Integer(10)   == String("10"),    "perlint == rubystr");
ok(Perl.Integer(10)   != String("11"),    "perlint != rubystr");

ok(Perl.Integer(10)   == Integer(10),     "perlint == rubyint");
ok(Perl.Integer(10)   != Integer(11),     "perlint != rubyint");

ok(Perl.Integer(10)   == Float(10.0),     "perlint != rubyfloat");
ok(Perl.Integer(10)   != Float(11.0),     "perlint != rubyfloat");

ok(Perl.Float(1.1)   == String("1.1"),    "perlfloat == rubystr");
ok(Perl.Float(1.1)   != String("0.0"),    "perlfloat != rubystr");

ok(Perl.Float(1.0)   == Integer(1.0),     "perlfloat == rubyint");
ok(Perl.Float(1.1)   != Integer(1.1),     "perlfloat != rubyint");

ok(Perl.Float(1.1)   == Float(1.1),       "perlfloat == rubyfloat");
ok(Perl.Float(1.1)   != Float(1.0),       "perlfloat != rubyfloat");

# ruby == perl

ok(String("foo")  == Perl.String("foo"),    "rubystr == perlstr");
ok(String("foo")  != Perl.String("FOO"),    "rubystr != perlstr");

ok(String("10")   == Perl.Integer(10),     "rubystr == perlint");
ok(String("10")   != Perl.Integer(11),     "rubystr != perlint");

ok(String("0.1") == Perl.Float(0.1),      "rubystr == perlfloat");
ok(String("0.1") != Perl.Float(1.0),      "rubystr != perlfloat");

ok(Integer(10)   == Perl.String("10"),    "rubyint == perlstr");
ok(Integer(10)   != Perl.String("11"),    "rubyint != perlstr");

ok(Integer(10)   == Perl.Integer(10),     "rubyint == perlint");
ok(Integer(10)   != Perl.Integer(11),     "rubyint != perlint");

ok(Integer(10)   == Perl.Float(10.0),     "rubyint != perlfloat");
ok(Integer(10)   != Perl.Float(11.0),     "rubyint != perlfloat");

ok(Float(1.1)   == Perl.String("1.1"),    "rubyfloat == perlstr");
ok(Float(1.1)   != Perl.String("0.0"),    "rubyfloat != perlstr");

ok(Float(1.0)   == Perl.Integer(1.0),     "rubyfloat == perlint");
ok(Float(1.1)   != Perl.Integer(0.1),     "rubyfloat != perlint");

ok(Float(1.1)   == Perl.Float(1.1),       "rubyfloat == perlfloat");
ok(Float(1.1)   != Perl.Float(1.0),       "rubyfloat != perlfloat");

GC.start

sv = Perl.undef;

ok(sv.kind_of?(Perl::Any));
ok(sv.undef?, "undef.undef?");
ok(!sv.true?, "undef.true?");

ok Perl.eval("require IO::Handle"), "Perl.require"; # load OO module
ok Perl.eval("require IO::File"),   "redo Perl.require";

IO_File = Perl.Class("IO::File");

fh = IO_File.new(__FILE__);

ok(fh.kind_of?(Perl::Any));
ok(fh.isa("IO::Handle").true?, "obj->isa()");
ok(!fh.isa("Ruby").true?);

is fh.getline, "#!perl\n";

fh.close;

Perl.eval("use Symbol qw(qualify); pass 'Perl.eval'");
Perl.eval("pass 'redo Perl.eval'");

is(qualify(Perl.String('Foo'), 'Test'), "Test::Foo");


is(Perl.Package("Symbol").qualify(Perl.String("Bar"), "main"), "main::Bar", "call Perl function in a package");

is(Perl.Package("T").send(:add, 2, 3), 5, "call Perl function via Perl::Package#send()");
is(Perl.String("T").send(:method, 1),  42, "call Perl function via Perl::String#send()");

# fetching variable

is(self["$scalar"], 'T::scalar', 'fetch scalar');

ary = Perl::Array.new;
ok(ary.empty?, "Perl::Array empty?");
ary.push(Perl.String("bar"));
ary.unshift(Perl.String("foo"));
ary.push(Perl.String("baz"));

ok(!ary.empty?, "Perl::Array empty?");

is_deeply(self["@ary"], ary, 'fetch array');
is(ary.join("|"), "foo|bar|baz", ":Array join");

is(ary.pop, "baz");
is(ary.shift, "foo");
is(ary[0], "bar", 'Array aref');
ary[0] = "hoge";
is(ary[0], "hoge", 'Array aset');
is(ary.size, 1, "Array size");
ary.clear;
is(ary.size, 0, "Array clear");

ok( ary.to_ary.kind_of?(Array), "Perl::Array to_ary");

hash = Perl::Hash.new;
hash["key"] = Perl.String("T::hash");

is_deeply(self["%hash"], hash, 'fetch hash');

ok( hash.to_hash.kind_of?(Hash), "Perl::Hash to_hash" );

g = self["*G"];

ok g.kind_of?(Perl::Glob);

is_deeply g[:SCALAR], Perl.String("S").to_ref, "G[:SCALAR]";
is_deeply g[:ARRAY],  Perl::Array.new.push('A'), "G[:ARRAY]";

h = Perl::Hash.new;
h['H'] = 'H';
is_deeply g[:HASH],  h, "G[:HASH]";

ok g[:IO].kind_of?(Perl::IO), "G[:IO]";
ok g[:CODE].kind_of?(Perl::Code), "G[:CODE]";

ok g["SCALAR"].kind_of?(Perl::Scalar);
ok g["ARRAY"].kind_of?(Perl::Array);
ok g["HASH"].kind_of?(Perl::Hash);
ok g["IO"].kind_of?(Perl::IO);
ok g["CODE"].kind_of?(Perl::Code);
is g["PACKAGE"], "T";
is g["CLASS"],   "T";
is g["NAME"],    "G";

ok g[:foo].nil?,  "G[:invalid_elem]";
ok g["foo"].nil?, "G['invalid_elem']";

g = Perl['*NewGlob'];

ok g[:NAME], "NewGlob";

how_many_want = Perl['&how_many_want'];

ctx = how_many_want.call();
ok ctx.defined? && ctx.false?, "default context: scalar(defined but false)";

ctx = how_many_want.want(:void).call();
ok ctx.nil?, "void context: return nil";

ctx = how_many_want.want(:scalar).call();
ok ctx.defined?, "scalar context: defined"
ok !ctx.true?,   "  and no value"

ctx = how_many_want.want(:array).call();
ok ctx.defined?, "array context: defined"
ok ctx.true?,    "  and true value"

ctx = how_many_want.call();
ok ctx.defined? && ctx.false?, "context reseted: scalar(defined but false)";

ctx = Perl["T"].want(:void).how_many_want();
ok ctx.nil?, "called as method: void context";
ctx = Perl["T"].how_many_want();
ok ctx.defined? && ctx.false?, "context reseted";

ary = Perl["T"].want(:array).list();
is_deeply ary.to_perl, [1, 2, 3].to_perl, "return list";

lambda(&Perl['&block']).call('as block');

Perl.Package("U"){
	is(__PACKAGE__, "U", 'Package');
	is(self.inspect, "Perl::Package(U)", "Package inspect");
	is(self["$s1"], "U::scalar1", 'fetch sclalar in Package(...){ ... }');
	is(self["$s2"], "U::scalar2", 'fetch sclalar in Package(...){ ... }');
}


EOS

GC->start;

# more string check



rb_eval <<'EOS', __PACKAGE__, __FILE__, __LINE__;

str = Perl.String("foo\nbar\nbaz\0xxx");

ok Perl.String("").empty?,   '"".empty? -> true';
ok Perl.undef.empty?,        'undef.empty? -> true';
ok !Perl.String("0").empty?, '"0".empty? -> false';
ok !str.empty?,              '"...".empty? -> false';

is Perl::undef.to_s, "undef", "undef.to_s";

is Perl.String("").size, 0, 'S.size';
is Perl.String("foo").size, 3, 'S.size';
is Perl.Integer(12).size, 2, 'I.size';
is Perl.Float(3.14).size, 4, 'F.size';

ok Perl.undef.size.nil?, 'undef.size is nil';

ary = ["foo\n", "bar\n", "baz\0xxx"];

str.each do |s|
	is s, ary.shift, "Perl::Scalar#each";
end

is str, "foo\nbar\nbaz\0xxx";

range = Perl.String('a') .. Perl.String('z');

is_deeply range.to_a.to_perl, ('a' .. 'z').to_a.to_perl, "Range by succ";


ok range == ('a' .. 'z'), "== (a Range of Ruby String)";

EOS

rb_eval <<'EOS', __PACKAGE__, __FILE__, __LINE__;

is_deeply(nil.to_perl,  Perl::undef, "nil.to_perl");
is_deeply(true.to_perl, Perl::String("1"), "true.to_perl");
is_deeply(false.to_perl,Perl::String(""),  "false.to_perl");
is_deeply(2.to_perl,    Perl::Integer(2), "2.to_perl");
is_deeply(2.3.to_perl,  Perl::Float(2.3), "2.3.to_perl");
is_deeply(:sym.to_perl, Perl::String("sym"), ":sym.to_perl");
EOS

GC->start;

END{
	pass "test end";
}