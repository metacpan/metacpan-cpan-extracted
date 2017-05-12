#!/usr/bin/perl

use warnings;
use strict;

#
# these are tests that confirm how perl works.
#

use Scalar::Util qw(refaddr reftype blessed);
use Test::More tests => 92;

#
# I can't find a case where a delete doesn't
# at least cause a change in the reference
# (if not the refaddr)
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( x => 7 );
	my $a = \$x{x};
	delete $x{x};
	my $b = \$x{x};
	$x{x} = 9;
	my $c = \$x{x};

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $b eq $c );
	ok ( refaddr($a) ne refaddr($b) );
}


#
# Nearly any other code sequnce cause the
# refaddr to change too
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( x => 7 );
	my $a = refaddr(\$x{x});
	my $ar = \$x{x};
	delete $x{x};
	my $b = refaddr(\$x{x});
	my $br = \$x{x};
	$x{x} = 9;
	my $c = refaddr(\$x{x});
	my $cr = \$x{x};

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $b eq $c );
	ok ( $ar ne $br );
	ok ( $br eq $cr );
	ok ( $$cr == 9 );
	ok ( $$ar == 7 );
}

#
# ditto.
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( x => 7 );
	my $ar = \$x{x};
	my $a = refaddr($ar);
	delete $x{x};
	my $br = \$x{x};
	my $b = refaddr($br);
	$x{x} = 9;
	my $cr = \$x{x};
	my $c = refaddr($cr);

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $b eq $c );
	ok ( $ar ne $br );
	ok ( $br eq $cr );
	ok ( $$cr == 9 );
	ok ( $$ar == 7 );
}


# 
# ditto.
#

print "# block at ".__LINE__."\n";

{
	my $x;
	my ($ar) = \$x;
	my ($br) = \$x;
	my ($cr) = \$x;
	my (%x) = ( x => 7 );
	my $a = refaddr(\$x{x});
	$ar = \$x{x};
	delete $x{x};
	my $b = refaddr(\$x{x});
	$br = \$x{x};
	$x{x} = 9;
	my $c = refaddr(\$x{x});
	$cr = \$x{x};

	ok ( $a ne $b );
	ok ( $b eq $c );
}

#
# repeat: refaddrs change when keys are deleted
# refaddr and references don't change when keys aren't deleted
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( y => 7 );
	my $a = \$x{x};
	my $a1 = $$a;
	$x{x} = 9;
	my $a2 = $$a;
	my $b = \$x{x};
	my $b1 = $$b;
	delete $x{x};
	my $c = \$x{x};

	ok (refaddr($a) eq refaddr($b));
	ok (refaddr($a) ne refaddr($c));
	ok ( !defined($a1));
	ok ($a2 == 9);
	ok ($b1 == 9);
}

#
# repeat: making a reference creates a hash key
# repeat: delting a reference orphans a key
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( y => 7 );

	ok (! exists($x{x}));

	my $a = \$x{x};

	ok (exists($x{x}));

	my $a1 = $$a;
	$x{x} = 9;
	my $a2 = $$a;
	my $b = \$x{x};
	my $b1 = $$b;

	delete $x{x};

	ok (! exists($x{x}));

	my $c = \$x{x};

	ok (exists($x{x}));
}

#
# EXCEPT!  When a hash key is deleted
# sometimes the refaddr doesn't change.
# This appears to be a rare case.
#
# I think this works this way because 
# the reference isn't kept and the new
# one just happens to get the same memory
# location.
#

print "# block at ".__LINE__."\n";

{
	my (%x) = ( x => 7 );
	my $a = refaddr(\$x{x});
	delete $x{x};
	my $b = refaddr(\$x{x});
	$x{x} = 9;
	my $c = refaddr(\$x{x});

	ok ( $a eq $b );
	ok ( $a eq $c );
	ok ( $b eq $c );
}

#
# EXCEPT!  When a hash key is deleted
# sometimes the refaddr doesn't change.
# This appears to be a rare case.
#
# I think this works this way because 
# the reference isn't kept and the new
# one just happens to get the same memory
# location.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{x} = 7;

	my $a = refaddr(\$x{x});
	delete $x{x};
	my $b = refaddr(\$x{x});
	$x{x} = 9;
	my $c = refaddr(\$x{x});

	ok ( $a eq $b );
	ok ( $a eq $c );
	ok ( $b eq $c );
}

#
# Tied references to hash values that don't exist
# don't refer to the future value (once it does exist)
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	$x{x} = 7;
	my $a = \$x{x};
	delete $x{x};
	my $b = \$x{x};
	$x{x} = 9;
	my $c = \$x{x};

	ok ( $a ne $b );
	ok ( $a ne $c );
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( $b eq $c );
	}
	ok ( refaddr($a) ne refaddr($b) );
}

#
# Nearly any other code sequnce cause the
# refaddr to change too
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{x} = 7;

	my $a = refaddr(\$x{x});
	my $ar = \$x{x};
	delete $x{x};
	my $b = refaddr(\$x{x});
	my $br = \$x{x};
	$x{x} = 9;
	my $c = refaddr(\$x{x});
	my $cr = \$x{x};

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $$cr == 9 );
	ok ( $$br == 9 );
	ok ( $ar ne $br );
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( $b eq $c );
		ok ( $br eq $cr );
		ok ( $$ar == 7 );
	}
}

#
# ditto.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{x} = 7;

	my $ar = \$x{x};
	my $a = refaddr($ar);
	delete $x{x};
	my $br = \$x{x};
	my $b = refaddr($br);
	$x{x} = 9;
	my $cr = \$x{x};
	my $c = refaddr($cr);

	ok ( $a ne $b );
	ok ( $a ne $c );
	ok ( $ar ne $br );
	ok ( $$cr == 9 );
	ok ( $$br == 9 );
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( $$ar == 7 );
		ok ( $br eq $cr );
		ok ( $b eq $c );
	}
}


# 
# ditto.
#

print "# block at ".__LINE__."\n";

{
	my $x;
	my ($ar) = \$x;
	my ($br) = \$x;
	my ($cr) = \$x;

	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{x} = 7;

	my $a = refaddr(\$x{x});
	$ar = \$x{x};
	delete $x{x};
	my $b = refaddr(\$x{x});
	$br = \$x{x};
	$x{x} = 9;
	my $c = refaddr(\$x{x});
	$cr = \$x{x};

	ok ( $a ne $b );
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( $b eq $c );
	}
}

print "# block at ".__LINE__."\n";

#
# Making an alias causes an hash key to exist.
#

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{y} = 7;

	my $a = refaddr(\$x{x});

	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( exists $x{x});
	}
}

#
# Deleting a hash key causes it's refaddr to
# changed.
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;

	$x{y} = 7;
	my $a = refaddr(\$x{x});
	$x{x} = 9;
	my $b = refaddr(\$x{x});
	delete $x{x};
	$x{zyz} = 77;
	my $dummy = \$x{xyz};
	my $c = refaddr(\$x{x});

	ok ( $a eq $b );
	ok ( $a ne $c );
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok ( exists $x{x});
	}
}

#
# repeat: refaddrs change when keys are deleted
# refaddr and references don't change when keys aren't deleted
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{y} = 7;

	my $a = \$x{x};
	my $a1 = $$a;
	$x{x} = 9;
	my $a2 = $$a;
	my $b = \$x{x};
	my $b1 = $$b;
	delete $x{x};
	my $c = \$x{x};

	ok (refaddr($a) ne refaddr($c));
	ok ( !defined($a1));
	ok ($b1 == 9);
	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok (refaddr($a) eq refaddr($b));
		ok (defined($a2) && $a2 == 9);
	}
}

#
# repeat: making a reference creates a hash key
# repeat: delting a reference orphans a key
#

print "# block at ".__LINE__."\n";

{
	my %x;
	my %y;
	tie %x, 'Hash1', \%y;
	$x{y} = 7;

	ok (! exists($x{x}));

	my $a = \$x{x};

	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok (exists($x{x}));
	}

	my $a1 = $$a;
	$x{x} = 9;
	my $a2 = $$a;
	my $b = \$x{x};
	my $b1 = $$b;

	delete $x{x};

	ok (! exists($x{x}));

	my $c = \$x{x};

	TODO: {
		local $TODO = "TIE doesn't support lvalue return";
		ok (exists($x{x}));
	}
}

print "# block at ".__LINE__."\n";

{
	my %x;
	$x{x} = 7;
	$x{y} = 8;
	my $a = \$x{x};
	my $b = \$a;
	$a = \$x{y};

	ok(${${$b}} == 8);
}

if (0) {
	tie my %x, 'Hash1', {};

	$x{y} = 7;
	my $a = \$x{A_KEY_WAS_FOUND};

	my $sv = svref_2object($a);
	print "ref(sv)         : ".ref($sv)."\n";
	print "MAGICAL(sv)     : ".$sv->MAGICAL."\n";
	print "FLAGS(sv)       : ".$sv->FLAGS."\n";
	print "TARG(sv)        : ".$sv->TARG."\n";
	print "STASH(sv)       : ".$sv->SvSTASH."\n";
	print "ref(MAGICAL(sv)): ".ref($sv->MAGICAL)."\n";
	print "ref(FLAGS(sv))  : ".ref($sv->FLAGS)."\n";
	print "ref(STASH(sv))  : ".ref($sv->SvSTASH)."\n";
	print "ref(TARG(sv))   : ".ref($sv->TARG)."\n";
	print "sv->TARG->      : ".${$sv->TARG}."\n";
	print "sv->STASH->     : ".${$sv->SvSTASH}."\n";
	print "sv              : $$sv\n";
	my $svx = $sv->MAGIC;
	print "ref(svx)        : ".ref($svx)."\n";
	#print "MAGICAL(svx)    : ".$svx->MAGICAL."\n";
	print "svx             : $$svx\n";
	while (lc($svx->TYPE) ne 'p') {
		print "type: ".$svx->TYPE."\n";
		$svx = $svx->MOREMAGIC;
	}
	print "svx->TYPE       : ".$svx->TYPE."\n";
	print "svx->OBJ        : ".$svx->OBJ."\n";
	print "svx->PTR        : ".$svx->PTR."\n";
	print "svx->PTR->str   : ".$svx->PTR->as_string."\n";
	print "svx->OBJ->RV    : ".${$svx->OBJ->RV}."\n";
	print "ref(svx->PTR)   : ".ref($svx->PTR)."\n";
	my $ob = $svx->OBJ;
	print "ref(ob)         : ".ref($ob)."\n";
	print "ref(ob)->       : ".$$ob."\n";
	print "refaddr tied %x : ". refaddr(tied %x)."\n";
	print "refaddr      \\%x: ". refaddr(\%x)."\n";
}

if (0) {
	print "methods(B::PVLV) =\n\t".join("\n\t",methods('B::PVLV'))."\n";
	print "methods(B::RV) =\n\t".join("\n\t",methods('B::RV'))."\n";
	print "methods(B::PV) =\n\t".join("\n\t",methods('B::PV'))."\n";
	print "methods(B::MAGIC) =\n\t".join("\n\t",methods('B::MAGIC'))."\n";
	print "methods(B::SPECIAL) =\n\t".join("\n\t",methods('B::SPECIAL'))."\n";
}

sub methods
{
	my ($class) = @_;
	my %done;
	no strict qw(refs);
	my (@isa) = $class;
	my (@methods);
	while (@isa) {
		my $r = shift(@isa);
		next if $done{$r}++;
		my $s = \%{"${r}::"};
		for my $symname (keys %$s) {
			local *sym = *{$s->{$symname}};
			next unless defined &sym;
			next if $done{$symname}++;
			push(@methods, $symname);
		}
		push(@isa, @{"${r}::ISA"});
	}
	return (@methods);
}

print "# block at ".__LINE__."\n";

{
	tie my $x, 'ScalarInc';
	$x = 7;
	ok($x == 8);

	my %y;
	tie $y{z}, 'ScalarInc';
	$y{z} = 9;
	# print "y{z} = $y{z}\n";
	ok($y{z} == 10);

	my %a;
	my $b = \%a;
	tie $b->{z}, 'ScalarInc';
	$b->{z} = 11;
	ok($b->{z} == 12);
}


#
# Why does local($@) hide the active return?
# bug #29696
#

print "# block at ".__LINE__."\n";
{
	sub x9 {
		local($@);
		eval { &y9(); };
		TODO: {
			local $TODO = 'local($@) is hiding the exception return';
			ok($@ eq 'foo4:foo2');
		}
	}
	sub y9 {
		&z9();
	}
	sub z9 {
		local($@);
		my $x;
		eval { $x = 7 };
		eval { $x = 'foo2'; die "foo3\n" } || die "foo4:$x\n";
		die $@ if $@;
	}
	&x9();
}

print "# block at ".__LINE__."\n";
{
	sub a10 {
		local($@);
		die "foobar\n";
	}
	eval { &a10(); };
	TODO: {
		local $TODO = 'local($@) is hiding the exception return';
		ok($@ eq "foobar\n");
	}
}

print "# block at ".__LINE__."\n";
{
	sub a11 {
		local($@);
		eval { my $x };
		die "foobar2\n";
	}
	eval { &a11(); };
	TODO: {
		local $TODO = 'local($@) is hiding the exception return';
		ok($@ eq "foobar2\n");
	}
}

{
package ScalarInc;

sub TIESCALAR { my $pkg = shift; my $x; return bless \$x, $pkg };
sub FETCH { my $self = shift; return ++$$self; }
sub STORE { my $self = shift; my $o = $$self; $$self = shift; return $o; }
}



#
# Slice notation works for deleting hash elements
#

print "# block at ".__LINE__."\n";
{
	my %x = (
		a => 1,
		b => 2,
		c => 3,
		d => 4
	);
	delete @x{'a', 'd'};
	ok(! exists($x{a}));
	ok(exists($x{b}));
	ok(exists($x{c}));
	ok(! exists($x{d}));
}
print "# block at ".__LINE__."\n";
{
	my %x;
	tie %x, 'Hash1', {};
	%x = (
		a => 1,
		b => 2,
		c => 3,
		d => 4
	);
	delete @x{'a', 'd'};
	ok(! exists($x{a}));
	ok(exists($x{b}));
	ok(exists($x{c}));
	ok(! exists($x{d}));
}

#
# Local work on lexical keys?
#
{
	print "# block at ".__LINE__."\n";
	my $foo = {
		a	=> 1,
		b	=> 2,
		c	=> 3,
	};

	sub x11 
	{
		my ($f) = @_;
		local($f->{a}) = 6;
		ok($f->{a} == 6);
		ok($f->{a} == $foo->{a});
		x12($f);
	}

	sub x12
	{
		my ($f) = @_;
		local($f->{b}) = 7;
		ok($f->{a} == 6);
		ok($f->{b} == 7);
		ok($f->{a} == $foo->{a});
	}

	x11($foo);
	ok($foo->{a} == 1);
	ok($foo->{b} == 2);
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

1;
