#!/usr/bin/perl -I../lib

use warnings;
use strict;

#
# these are tests that confirm how perl works.
#

use Scalar::Util qw(refaddr reftype blessed weaken);
use Test::More tests => 129;
use B 'svref_2object';
use strict;
use warnings;

our $storeFunny;

#
# two references to the same thing are themselves the same
#

print "# block at ".__LINE__."\n";

{
	my $a = [ 'xyz' ];
	my $y = \$a->[0];
	my $z = \$a->[0];

	ok( $y eq $z );
	ok( refaddr($y) eq refaddr($z) );
}

#
# When an hash key is deleted
# the refaddr for a reference to the value
# changes.
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( x => 7 );
	my $a = refaddr(\$x{x});
	delete $x{x};
	$x{zyz} = 77;
	my $dummy = \$x{xyz};
	my $b = refaddr(\$x{x});
	$x{x} = 9;
	my $c = refaddr(\$x{x});

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $b eq $c )
}


print "# block at ".__LINE__."\n";

#
# Making an alias causes a hash key to exist.
#

{
	my (%x) = ( y => 7 );
	my $a = refaddr(\$x{x});

	ok ( exists $x{x});
}

#
# Deleting a hash key causes it's refaddr to
# change.
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( y => 7 );
	my $a = refaddr(\$x{x});
	$x{x} = 9;
	my $b = refaddr(\$x{x});
	delete $x{x};
	$x{zyz} = 77;
	my $dummy = \$x{xyz};
	my $c = refaddr(\$x{x});

	ok ( $a eq $b );
	ok ( $a ne $c );
	ok ( exists $x{x});
}

# 
# Orphaned references remain tied together.  
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( y => 7 );

	my $a = \$x{x};
	my $b = \$x{x};

	delete $x{x};

	$$a = 8;

	ok($$b == 8);
}

# ------------- now with Hash1 instead of untied -------------

#
# Make sure that Hash1 works as a hash table.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	$x{x} = 7;
	ok ($x{x} == 7);
	ok (! exists $x{y});
	delete $x{x};
	ok (! exists $x{x});
}

#
# References to hash values that don't exist don't create
# the hash key (unlike untied hashes).  However, the reference
# *is* tied to the hash and assigning to it will change the 
# underlying value.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	my $z = \$x{z};
	ok (! exists $x{z}); # bug
	ok (! defined($x{z}));
	$$z = 12;
	ok ($x{z} == 12);
}

#
# This behavior doesn't depend on how the tied hash is 
# implemented.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash2', \%y;

	my $z = \$x{z};
	$$z = 12;
	ok ($x{z} =~ /^12/);
}

#
# refaddrs to tied hashes are stable when the tied
# key exists.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	$x{x} = 7;
	my $b = refaddr(\$x{x});
	$x{x} = 9;
	my $c = refaddr(\$x{x});

	ok ( $b eq $c )
}

# 
# Orphaned references remain tied together.
# Deleting a hash key and then assinging to a 
# stale reference will re-create the key.
# This is different than untied behavior.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	$x{y} = 7;
	my $a = \$x{x};
	my $b = \$x{x};
	delete $x{x};
	$$a = 8;

	ok($$b == 8);
	ok($x{x} == 8);
}

# 
# ditto.
# True no matter how the hash is implemented.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash2', \%y;

	$x{y} = 7;
	my $a = \$x{x};
	my $b = \$x{x};
	delete $x{x};
	$$a = 8;

	ok($$b =~ /^8/);
	ok($x{x} =~ /^8/);
	ok($$a =~ /\(\d+\)/);
	ok($$a eq $$b);
	ok($$a eq $x{x});
}

#
# The refaddr for a tied hash value is different from
# the refaddr for the same hash value untied and different
# from a refaddr to an underlying hash. 
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;

	$x{y} = 99;
	my $c = \$x{y};
	my $r0 = refaddr($c);

	tie %x, 'Hash1', \%y;

	$x{y} = 7;
	my $a = \$x{y};
	my $b = \$y{y};

	my $r1 = refaddr($a);
	my $r2 = refaddr($b);

	ok($r0 ne $r1);
	ok($r0 ne $r2);
	ok($r1 ne $r2);
}

#
# References to tied hash values are all unique.  They each have
# their own address.  References remain even when the hash key
# is deleted.
#
# Sometimes the references can become disconnected from the underlying
# hash.  They'll reconnect on assignement.
#
# When a reference reconnects after assignement, any other references
# disconnect.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	tie %x, 'Hash1', {};

	$x{y} = 7;
	my $a = \$x{y};
	delete $x{y};
	$x{y} = 9;
	my $b = \$x{y};
	my $c = \$x{y};

	ok($$a == 9); # bug
	ok(refaddr($a) ne refaddr($b));
	ok(refaddr($a) ne refaddr($c));
	ok(refaddr($b) ne refaddr($c)); # bug

	delete $x{y};
	$$c = 17;
	ok($$b == 17);
	ok($x{y} == 17);
	ok($$c == 17);   # why?

	ok($$a == 9); # bad
	$$a = 12;
	ok($x{y} == 12);
	ok($$c == 17);	# bug
	ok($$b == 17);  # bug

	$x{y} = 11;
	ok($$a == 11);
	ok($$b == 17);	# bug
	ok($$c == 17);	# bug

	$$b = 12;
	ok($x{y} == 12);
	ok($$c == 17);  # bug
	ok($$a == 11);  # bug
}

#
# Assignment though one referenc to a tied hash
# can disconnect other references to the tied hash
#

print "# block at ".__LINE__."\n";
{
	my %x;
	tie %x, 'Hash1', {};

	$x{y} = 9;

	$x{a} = \$x{y};
	$x{b} = \$x{y};

	$x{y} = 10;

	ok(${$x{a}} == 10);
	ok(${$x{b}} == 10);

	${$x{a}} = 11;

	ok(${$x{b}} == 10); # bug
}
print "# block at ".__LINE__."\n";
{
	my %x;
	tie %x, 'Hash1', {};

	$x{y} = 7;
	my $a = \$x{y};
	my $b = \$x{y};
	$x{y} = 9;

	ok($$a == 9);
	ok($$b == 9);

	$$a = 10;

	ok($$b == 9); # bug
}


# ------------- now let's look at references to references 

#
# References to the same thing are identical but they are
# not the same object.  This means that references to references
# of the same thing are different.
#

print "# block at ".__LINE__."\n";

{
	my $x = 'foobar';
	my $a = \$x;
	my $b = \$a;
	my $aa = \$x;
	my $bb = \$aa;
	my $c = \$a;
	my $cc = \$aa;

	ok($a eq $aa);
	ok($b eq $c);
	ok($bb eq $cc);
	ok($aa ne $bb);
}

#
# ditto, but for references to hash values.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	$x{x} = 7;
	my $a = \$x{x};
	my $b = \$a;
	my $aa = \$x{x};
	my $bb = \$aa;
	my $c = \$a;
	my $cc = \$aa;

	ok($a eq $aa);
	ok($b eq $c);
	ok($bb eq $cc);
	ok($aa ne $bb);
}

#
# Ditto for a tied hash.
#

print "# block at ".__LINE__."\n";

{
	my $x;
	tie $x, 'Ref1';
	$x = 'Foobar';

	my $a = \$x;
	my $b = \$a;
	my $aa = \$x;
	my $bb = \$aa;
	my $c = \$a;
	my $cc = \$aa;

	ok($a eq $aa);
	ok($b eq $c);
	ok($bb eq $cc);
	ok($aa ne $bb);
}

#
# It doesn't seem to matter if the 
# scalar is tied -- the reference remains
# the same tied or not and still works
# when tied and untied.
#

print "# block at ".__LINE__."\n";

{
	my $x;
	my $a = \$x;
	my $aa = refaddr($a);

	tie $x, 'Ref1';
	$x = 'Foobar';

	my $b = \$x;
	my $ba = refaddr($b);

	ok($a eq $b);
	ok($aa eq $ba);

	$$a = 22;
	ok($$b == 22);

	untie $x;
	$$b = 99;
	ok($$a == 99);
}

#
# ditto for sclar tie of an array element
#

print "# block at ".__LINE__."\n";

{
	my (@x) = (1, 2, 3);
	my $a = \$x[1];
	my $aa = refaddr($a);

	tie $x[1], 'Ref1';
	$x[1] = 'Foobar';

	my $b = \$x[1];
	my $ba = refaddr($b);

	ok($a eq $b);
	ok($aa eq $ba);

	$$a = 22;
	ok($$b == 22);

	untie $x[1];
	$$b = 99;
	ok($$a == 99);
}

#
# Using an array element that doesn't exist will
# create it.
#
print "# block at ".__LINE__."\n";
{
	my @a;
	$#a = 8;
	goody($a[4]);
	ok(exists $a[4]);
}
sub goody
{
	my $x = shift;
	$x = '' unless defined $x;
	return "foo$x";
}

#
# Arrays really do track exists or not exists info
#
print "# block at ".__LINE__."\n";
{
	my @a;
	$#a = 8;
	$a[5] = 'five';
	ok(! exists $a[4]);
	delete $a[5];
	ok(! exists $a[5]);
	$a[3] = undef;
	ok(exists $a[3]);
}

#
# Elements beyond the end don't exist
#
print "# block at ".__LINE__."\n";
{
	my (@a) = qw(a b c d e);
	$#a = 2;
	ok(exists $a[0]);
	ok(exists $a[1]);
	ok(exists $a[2]);
	ok(! exists $a[3]);
	ok(! exists $a[4]);
	ok(! exists $a[5]);
}

#
# seems like a bug. 
#
print "# block at ".__LINE__."\n";
{
	my @a;
	$a[0] = 'zero';
	$a[1] = 'one';
	$#a = 3;
	shift(@a);
	shift(@a);
	delete $a[1];
	ok($#a == -1); # bug

	my @b;
	$#b = 1;
	delete $b[1];
	ok($#b == -1); # bug

	my @c;
	$#c = 2;
	delete $c[2];
	ok($#c == -1); # bug

	my @d;
	$d[0] = 'zero';
	$#d = 3;
	delete $d[3];
	ok($#d == 0);  # bug
}

#
# extending an array doesn't cause elements to exist
#
print "# block at ".__LINE__."\n";
{
	my (@a) = qw(a b c);
	$#a = 5;
	ok(exists $a[0]);
	ok(exists $a[1]);
	ok(exists $a[2]);
	ok(! exists $a[3]);
	ok(! exists $a[4]);
	ok(! exists $a[5]);
	ok(! exists $a[5]);
	ok(! exists $a[6]);
}

# ------------- now let's play with B

#
# Method for finding what hash & key a reference to 
# a tied hash value points to.
#

print "# block at ".__LINE__."\n";

{
	tie my %x, 'Hash1', {};

	$x{y} = 7;
	my $a = \$x{A_KEY_WAS_FOUND};

	my $sv = svref_2object($a);
	my $svx = $sv->MAGIC;
	while (lc($svx->TYPE) ne 'p') {
		$svx = $svx->MOREMAGIC;
	}
	ok(${$svx->OBJ->RV} eq refaddr(tied %x));
	ok($svx->PTR->as_string eq 'A_KEY_WAS_FOUND');
}

# 
# for references to tied hash keys, this will return
# the refaddr of the tie object and the hash key
#
sub tied_hash_reference
{
	my $ref = shift;
	return eval {
		my $magic = svref_2object($ref)->MAGIC;
		$magic = $magic->MOREMAGIC
			while lc($magic->TYPE) ne 'p';
		return (${$magic->OBJ->RV}, $magic->PTR->as_string);
	};
}

print "# block at ".__LINE__."\n";

{
	my $t = tie my %x, 'Hash1', {};
	$x{KEY_ONE} = 7;
	my $a = \$x{KEY_ONE};
	my ($h, $k) = tied_hash_reference($a);
	ok($k eq 'KEY_ONE');
	ok((tied_hash_reference($a))[1] eq 'KEY_ONE');
}

#
# Even when dis-associated, tied_hash_reference() still works.
#

print "# block at ".__LINE__."\n";
{
	my %x;
	my $t = tie %x, 'Hash1', {};
	my $ta = refaddr($t);

	$x{y} = 7;
	my $a = \$x{y};
	my $b = \$x{y};
	$x{y} = 9;

	ok($$a == 9);
	ok($$b == 9);

	ok((tied_hash_reference($a))[1] eq 'y');
	ok((tied_hash_reference($a))[0] eq $ta);
	ok((tied_hash_reference($b))[1] eq 'y');
	ok((tied_hash_reference($b))[0] eq $ta);

	$$a = 10;

	ok($$b == 9); # bug
	ok((tied_hash_reference($a))[1] eq 'y');
	ok((tied_hash_reference($a))[0] eq $ta);
	ok((tied_hash_reference($b))[1] eq 'y');
	ok((tied_hash_reference($b))[0] eq $ta);
}


#
# Parameter aliasing can be used to make references
#

print "# block at ".__LINE__."\n";
{
	sub makeref 
	{
		return \$_[0];
	}
	my %x;
	my $t = tie %x, 'Hash1', {};
	my $ta = refaddr($t);

	$x{y} = 7;
	my $a = makeref($x{y});
	my $b = makeref($x{y});
	$x{y} = 9;

	ok($$a == 9);
	ok($$b == 9);
}
{
	sub makeref2
	{
		return \$_[0];
	}
	sub makeref3
	{
		makeref2($_[0]);
	}
	my %x;
	my $t = tie %x, 'Hash1', {};
	my $ta = refaddr($t);

	$x{y} = 7;
	my $a = makeref3($x{y});
	my $b = makeref3($x{y});
	$x{y} = 9;

	ok($$a == 9);
	ok($$b == 9);
}

#
# Something very much like this causes a segv.  Why doens't this?
#

print "# block at ".__LINE__."\n";
{

	tie my %root, 'Hash1', {};
	my $root = \%root;
	$root->{skey} = 'sval';

	$root->{X9} = [ \$root->{skey} ];
	$root->{Y9} = [ \$root->{skey} ];
	my $x = \$root->{Y9}[0];
	weaken($x);
	local($storeFunny) = sub { $$x = \$root->{skey} };
	${$root->{X9}[0]} = 'FOO9';

	ok(${$root->{Y9}[0]} eq 'FOO9');
}


#
# Why does eval catch exceptions sometimes and not catch them
# other times?
#
print "# block at ".__LINE__."\n";
{
	sub foo 
	{
		return eval {
			die "foobar\n";
		}
	}

	&foo;
	ok($@, "foobar\n");
}

#
# Blessing stays with the scalar (and I assume, hash)
# even when there is no reference to the scalar.
#
print "# block at ".__LINE__."\n";
{
	my $x = 'foobar';
	{
		my $y = \$x;
		bless $y, 'baz';
		undef $y;
	}
	my $a = \$x;
	my $b = ref($a);
	ok($b eq 'baz'); 
}

#
# What is actually passed to HASH->STORE?  Answer: the
# actual hash key.  However, there is a very strange 
# bug here.
#
print "# block at ".__LINE__."\n";
{
	my $z = '77';
	my $y = \$z;
	my $a = '78';
	my $b = \$a;
	tie my %x, 'Hash3', {};
	$x{$y} = 22;
	$x{$b} = 23;
	ok(ref($x{$y}));
	ok(ref($x{$b}));
	{
		local $TODO = 'Do these still fail?  Multiple versions of Util::Scalar?';
		ok(refaddr($x{$y})); # bug
		ok(refaddr($x{$b})); # bug
	}
	my $xy = $x{$y}; 
	my $xb = $x{$b}; 
	ok(refaddr($xy) == refaddr($y));
	ok(refaddr($xb) == refaddr($b));
	#print "x{y}=$x{$y} y=$y\n";
	#print "x{b}=$x{$b} b=$b\n";
	#printf "ra(x{y})=%d, ra(y)=%d\n", refaddr($x{$y}), refaddr($y);
	#printf "ra(x{b})=%d, ra(b)=%d\n", refaddr($x{$b}), refaddr($b);
	#printf "x{y} ref()=%s reftype=%s refaddr=%d %s\n", ref($x{$y}), reftype($x{$y}), refaddr($x{$y}), $x{$y};
	#printf "x{b} ref()=%s reftype=%s refaddr=%d %s\n", ref($x{$b}), reftype($x{$b}), refaddr($x{$b}), $x{$b};
	#printf "x{y} ref()=%s reftype=%s refaddr=%d %s\n", ref($xy), reftype($xy), refaddr($xy), $xy;
	#printf "x{b} ref()=%s reftype=%s refaddr=%d %s\n", ref($xb), reftype($xb), refaddr($xb), $xb;
	#ok(refaddr($x{$y}) == refaddr($y));
}
	
#
# Turns out that caller returns the name of the subroutine
# called rather than the name of the calling subroutine.
# Weird.
# 
print "# block at ".__LINE__."\n";
{

	tie my %tiecaller, 'MT', sub { my $lvls = $_[0]+2; return [ caller($lvls) ] };
	sub subcaller { my $lvls = $_[0]+1; return [ caller($lvls) ] };

	sub MT::TIEHASH { my $p = shift; return bless shift, $p } 
	sub MT::FETCH { my $f = shift; return &$f(shift) } 

	my $cl;

	&A();

	sub A
	{
		$cl = __LINE__; &B();
	}

	sub B
	{
		my ($package, $filename, $line, $subroutine);

		my $l = 0;
		($package, $filename, $line, $subroutine) = @{&subcaller($l)};
		ok($line == $cl);
		ok($subroutine eq 'main::B');  # bug
		print "# p:$package, f:$filename, l:$line, s:$subroutine\n";
		($package, $filename, $line, $subroutine) = @{$tiecaller{$l}};
		ok($line == $cl);
		ok($subroutine eq 'main::B');  # bug
		print "# p:$package, f:$filename, l:$line, s:$subroutine\n";
		($package, $filename, $line, $subroutine) = caller($l);
		print "# p:$package, f:$filename, l:$line, s:$subroutine\n";
		ok($line == $cl);
		ok($subroutine eq 'main::B');  # bug
	}
}

#
# What happens when there is a die inside a die?
#
print "# block at ".__LINE__."\n";
{
	sub DIEDIE::DESTROY {
		die "DIEDIE\n";
	}
	sub FO23 {
		my $x = bless {}, 'DIEDIE';
		die "XXX\n";
	}
	sub FO22 {
		eval {
			FO23();
		};
		my $e = $@;
		return $e;
	}
	my $x = eval {
		FO22();
	};
	ok($x =~ /^XXX/);
}

#
# Does eval { return } return from the outer sub?
#
print "# block at ".__LINE__."\n";
{
	sub xy7 {
		eval { return 3 };
		return 4;
	}
	my $x = xy7();
	ok($x == 4);
}

package Hash1;

sub TIEHASH
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;
}

sub FETCH
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return $underlying->{$key};
}

sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my ($underlying) = @$self;
	&$main::storeFunny($self, $key, $value) if defined $main::storeFunny;
	return ($underlying->{$key} = $value);
}

sub DELETE
{
	my ($self, $key) = @_;
	my ($underlying) = @$self;
	return delete($underlying->{$key});
}

sub CLEAR
{
	my $self = shift;
	my ($underlying) = @$self;
	%$underlying = ();
}

sub EXISTS
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return exists $underlying->{$key};
}

sub FIRSTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	keys %$underlying;
	return each %$underlying;
}

sub NEXTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	return each %$underlying;
}

package Hash2;

use Scalar::Util qw(refaddr reftype blessed);

sub TIEHASH
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;
}

sub FETCH
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	my $x = refaddr(\$underlying->{$key});
	return "$underlying->{$key}($x)";
}

sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my ($underlying) = @$self;
	return ($underlying->{$key} = $value);
}

sub DELETE
{
	my ($self, $key) = @_;
	my ($underlying) = @$self;
	return delete($underlying->{$key});
}

sub CLEAR
{
	my $self = shift;
	my ($underlying) = @$self;
	%$underlying = ();
}

sub EXISTS
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return exists $underlying->{$key};
}

sub FIRSTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	keys %$underlying;
	return each %$underlying;
}

sub NEXTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	return each %$underlying;
}

package Ref1;

sub TIESCALAR
{
	my $pkg = shift;
	return bless { val => undef };
}

sub FETCH
{
	my $self = shift;
	#print "FETCH $self->{val}\n";
	return $self->{val};
}

sub STORE
{
	my $self = shift;
	my $new = shift;
	#print "STORE $new\n";
	$self->{val} = $new;
}

package Hash3;

use Scalar::Util qw(refaddr reftype blessed);

sub TIEHASH
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;
}

sub FETCH
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return $underlying->{refaddr($key)};
}

sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my ($underlying) = @$self;
	return ($underlying->{refaddr($key)} = $key);
}

sub DELETE
{
	my ($self, $key) = @_;
	my ($underlying) = @$self;
	return delete($underlying->{refaddr($key)});
}

sub CLEAR
{
	my $self = shift;
	my ($underlying) = @$self;
	%$underlying = ();
}

sub EXISTS
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return exists $underlying->{$key};
}

sub FIRSTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	keys %$underlying;
	return each %$underlying;
}

sub NEXTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	return each %$underlying;
}


1;
