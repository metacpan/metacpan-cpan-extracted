#!/usr/bin/perl -w

use lib 't';
use Test::More tests => 26;

BEGIN { use_ok 'Sub::Delete' };


# Tests subs:

sub thing {}
++$thing[0];
sub foo {}
()=\&bar;
use constant baz => 'dotodttoto';

{package Phoo;
	sub thing {}
	++$thing[0];
	sub foo {}
	()=\&bar;
	use constant baz => 'dotodttoto';
 }

is +()=delete_sub('thing'), 0, 'no retval';
ok !exists &{'thing'}, 'glob / sub that shares its symbol table entry';
is ${'thing'}[0], 1, 'the array in the same glob was left alone';
delete_sub 'foo';
ok !exists &{'foo'}, 'sub that has its own symbol table entry';
delete_sub 'bar';
ok !exists &{'bar'}, 'stub';
delete_sub 'baz';
ok !exists &{'baz'}, 'constant';

delete_sub 'Phoo::thing';
ok !exists &{'Phoo::thing'},
	'sub in another package that shares its symbol table entry';
is ${'Phoo::thing'}[0], 1,
	'the array in the same glob (in the other package) was left alone';
delete_sub 'Phoo::foo';
ok !exists &{'Phoo::foo'},
	'sub in another package w/its own symbol table entry';
delete_sub 'Phoo::bar';
ok !exists &{'Phoo::bar'}, 'stub in another package';
delete_sub 'Phoo::baz';
ok !exists &{'Phoo::baz'}, 'constant in another package';


@ISA = 'Foo';
{no warnings qw 'once';
*Foo::thing = *Foo::foo = *Foo::bar = *Foo::baz = sub {1};}

# Make sure there really are no stubs left that would affect methods:
ok +main->$_, 'it really *has* been deleted'
	for qw w thing foo bar baz w;

# Make sure that globs get erased if they exist solely for the sake of
# subroutines.
sub clext;
delete_sub 'clext';
ok !exists $::{clext},
  'delete_subs deletes globs that exists solely for subroutines’ sake';

sub blile;
$blor = \$blile;
delete_sub 'blile';
cmp_ok $blor, '==', \${'blile'},
 'delete_sub leaves globs whose scalar entry is referenced elsewhere';

SKIP:{
 skip 'unimplemented', 2;

 # We can’t make these two work, because it would require preserving the
 # glob, which stops constant::lexical from working (because compiled code
 # references not the subroutine, but the glob containing it).

 # This case seems  impossible.  A glob is a scalar  that  has  magic
 # that references the actual glob  (GP).  Calling undef  *brox  (which
 # delete_sub does) actually swaps out the GP, replacing it with another
 # $blun = *bri  syntax  creates  a  new  scalar  referencing  the  same
 # GP.  There seems to be no way to make this work  (from Perl  at least;
 # maybe we could do this with XS).
 sub cho;
 $belp = *cho;
 delete_sub 'cho';
 # $belp is now a different scalar from *cho, though it (ideally) shares
 # the same magic object. So we have to test the equality by modifying it.
 () = @$belp; # auto-vivify
 cmp_ok \@$belp, '==', \@{'cho'},
  'and globs that are themselves referenced elsewhere (via *bue syntax)';

 sub ched;
 $blode = \*ched;
 delete_sub 'ched';
 cmp_ok $blode, '==', \*{'ched'},
  'and globs that are themselves referenced elsewhere (via \*bue syntax)';
}

# Make sure ‘use vars’ info is preserved.
{ package gred; *'chit = \$'chit } # use vars
sub chit;
delete_sub 'chit';
{
 use strict 'vars';
 ok eval q/()=$chit; 1/, '‘use vars’ flags are not erased';
}

# Make sure ‘use vars’ is not inadvertently turned on.
() = @glob; # auto-viv
sub glob; # We are calling this ‘glob’ as there is a lexical var in
delete_sub 'glob';  # delete_sub and we are making sure it doesn’t
{                            # interfere.
 use strict 'vars';
 local $SIG{__WARN__} = sub {};
 ok !eval q/()=$glob; 1/,
  '‘use vars’ flags are not inadvertently turned on';
}

# Make sure we can run deleted subroutines
sub bange { 3 }
is eval { bange }, 3, 'deleted subroutines can be called';
BEGIN { delete_sub 'bange' }

# %^H leakage in perl 5.10.0
{
 package ScopeHook;
 DESTROY { ++$exited }
}
sub spow;
{
 BEGIN {
  $^H |= 0x20000;
  $^H{'Sub::Delete_test'} = bless [], ScopeHook;
  delete_sub "spow";
 }
}
BEGIN { is $ScopeHook::exited, 1, "delete_sub does not cause %^H to leak" }

# $@ leakage
sub jare;
$@ = 'fring';
delete_sub 'jare';
is $@, 'fring', '$@ does not leak';
sub TIESCALAR{bless[]}
tie $@, "";
sub feck;
ok eval{delete_sub 'feck';1}, '$@ is quite literally untouched';
