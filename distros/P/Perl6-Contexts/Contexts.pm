#!/usr/bin/perl

# Here, localtime() should return a stringified date or an object
# use Perl6::Contexts;
# my @stuff = (1, 2, 3, localtime);
# print "@stuff\n";
# 1 2 3 27 12 10 8 8 104 3 251 0

# TODO - make this work:
# use Perl6::Contexts;
# my %hash = { foo => 10, bar => 20 };
# foreach my $key (keys %hash) {
#   print $key, "\n";
# }
# HASH(0x813808c)

# TODO - make this work:
# perl -MO=Concise -e 'my @foo; my $bar = [ 1 .. 20 ]; @foo = $bar;'
# c     <;> nextstate(main 3 -e:1) v ->d
# h     <2> aassign[t5] vKS ->i
# -        <1> ex-list lK ->f
# d           <0> pushmark s ->e
# e           <0> padsv[$bar:2,3] l ->f
# -        <1> ex-list lK ->h
# f           <0> pushmark s ->g
# g           <0> padav[@foo:1,3] lRM* ->h

# Reference found where even-sized list expected = my %foo = {  }

# TODO - make this work:
# perl -MO=Concise -e 'localtime->date();'
# 7  <@> leave[1 ref] vKP/REFC ->(end)
# 1     <0> enter ->2
# 2     <;> nextstate(main 1 -e:1) v ->3
# 6     <1> entersub[t2] vKS/TARG ->7
# 3        <0> pushmark s ->4
# 4        <0> localtime[t1] sM ->5
# 5        <$> method_named(PVIV "date") ->6
# this will require numerous helper classes, one for stat buffers, time,
# and any other built-in that returns a list in list context. perhaps can
# reuse existing classes like Date::Manip.


package Perl6::Contexts;

# use Data::Dumper 'Dumper'; # debug

use 5.008;
our $VERSION = '0.4';

#
# some preliminary goop is gotten out of the way first, and then we get into the meat which
# starts with the CHECK() routine. that calls one_cv_at_a_time() for each code value, 
# which calls walkoptree_slow() after some prep work, which calls look_for_things_to_diddle()
# for each actual bytecode instruction.
#

use B 'OPf_KIDS', 'OPf_WANT_SCALAR', 'OPf_WANT_LIST', 'OPf_WANT', 'OPf_REF', 'OPf_MOD', 'OPf_SPECIAL';
use B::Generate;
use B::Concise 'concise_cv'; # 'walk_topdown'
# use B::Utils;

use strict;
use warnings;

sub OPfDEREF    () { 32|64 } # #define OPpDEREF                (32|64) /* autovivify: Want ref to something: */
sub OPfDEREF_AV () { 32 }    # #define OPpDEREF_AV             32      /*   Want ref to AV. */
sub OPfDEREF_HV () { 64 }    # #define OPpDEREF_HV             64      /*   Want ref to HV. */
sub OPfDEREF_SV () { 32|64 } # #define OPpDEREF_SV             (32|64) /*   Want ref to SV. */

my $redo_reverse_indices; # recompute $previous for the current CV
my $previous = {};  # opposite of next, inferred from next
my %knownuniverse;  # modules using us
my %knowncvs;       # code values we've found (subroutines and anonymous subs)
my @padtmps;        # pad entry offsets available for our consumption
my $lastpadtmp;     # last one used - go round robin
my %did_already;    # arrays were getting ref'd twice because parent info was stale and two rules matched

my $lastpack; my $lastline; my $lastfile;

# numericish opcodes, taken from perldoc Opcodes
# stringwise: slt sgt sle sge seq sne scmp

my $mathops = { map { ($_ => 1) } qw{
                preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec
                int hex oct abs pow multiply i_multiply divide i_divide
                modulo i_modulo add i_add subtract i_subtract

                left_shift right_shift bit_and bit_xor bit_or negate i_negate
                not complement

                lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp

                atan2 sin cos exp log sqrt
                rand srand

                scalar
}};

my $boolops = { map { ($_ => 1) } qw{
                cond_expr flip flop andassign orassign dorassign and or dor xor
}};

my $stringops = { map { ($_ => 1) } qw{
                slt sgt sle sge seq sne scmp

                substr vec stringify study pos length index rindex ord chr

                ucfirst lcfirst uc lc quotemeta trans chop schop chomp schomp

                match split qr
                concat
}};

my $arrayops = { map { ($_ => 1) } qw{
                splice push pop shift unshift reverse
}};

my $hashops = { map { ($_ => 1) } qw{
                each values keys exists delete
}};

sub import {
     my $caller = caller;
     $knownuniverse{$caller} = 1;
}

CHECK {

    # make a hash of code values we've found - memory address of the opcode is mapped to the
    # B object encapsulating it. then go through them all, marking them done as we do them.
    # this is tricky since more may appear as we go along. for each code value we find, call
    # one_cv_at_a_time() on it.

    # build initial list of code values from methods/functions in the subs and the main root

    %knowncvs = do { my $x = B::main_cv(); ( $$x => $x ) };

    foreach my $package (keys %knownuniverse) {
        no strict 'refs';
        foreach my $method (grep { defined &{$package.'::'.$_} } keys %{$package.'::'}) {
            my $cv = B::svref_2object(*{$package.'::'.$method}{CODE});
            $knowncvs{$$cv} = $cv; 
        }
    }

    foreach my $cv ((B::main_cv->PADLIST->ARRAY)[1]->ARRAY) {
        # print "debug: main pad list: ", ref $cv, "\n";
        next unless ref $cv eq 'B::CV';
        # print "debug: found a cv!\n";
        $knowncvs{$$cv} = $cv;
    }


    my %donecvs; 
    my $curcv;

    goto first_cv;

    next_cv:

    one_cv_at_a_time($curcv);
    $donecvs{$curcv} = 1;

    first_cv:

    foreach (keys %knowncvs) {
        # we look through the list of code values each time just in case something got added
        # this happens when we encounter anoncode operations
        $curcv = $knowncvs{$_}; goto next_cv if ! $donecvs{$curcv};
    }

}

sub one_cv_at_a_time {

    # get ready to recurse through the bytecode tree - build a reverse index, previous, from the next
    # links and do any debugging output after we traverse the tree

    my $curcv = shift;
    my $leave = $curcv->ROOT;

    return if $curcv->PADLIST->isa('B::SPECIAL');
    my @nonrootpad = ($curcv->PADLIST->ARRAY)[0]->ARRAY;

    # XXX - locate some temporaries we can use. 
    # this routine *should* build a list of all temporaries for the CV and then remove the list of
    # temporaries already used in the current statement but for now we're just going to use some
    # ringers. ringers also deal with the problem of modifiying the most complex statement
    # in a CV where all temps are in use a d we can't make more!

    for(my $padindex = 0; $padindex < @nonrootpad; $padindex++) {
        my $name = $nonrootpad[$padindex];
        # that's the inidivual entries of the names array - see the comments in pad.c in the perl source
        next if ref $name eq 'B::SPECIAL'; # B::SPECIALs are PADTMPs which are exactly what we *should* be using
        # print 'PVX: ', $name->PVX, ' NV: ', $name->NV,  ' IV: ', $name->IV, "\n";
        next unless $name->PVX =~ m/^\$t[0-9]$/; # XXX might have to fix up flags a bit here
        # my $sv = (($curcv->PADLIST->ARRAY)[1]->ARRAY)[0]; bless $sv, 'B::PV'; $sv->PV('');
        push @padtmps, $padindex;
        # print "debug: $padindex is a temp for us - ", $name->PVX, "\n";
    }

    $redo_reverse_indices = sub {
        walkoptree_slow($leave, sub { 
            my $self = shift;       return unless $self and $$self;
            my $next = $self->next; return unless $next and $$next;
            $previous->{$$next} = $self; 
        });
    };

    $redo_reverse_indices->();

    walkoptree_slow($leave, \&look_for_things_to_diddle);

    # B::main_root()->linklist();

    # print $$leave, " basic:\n"; B::Concise::concise_cv_obj('basic', $curcv); # debug
    # print $$leave, " exec:\n";  B::Concise::concise_cv_obj('exec', $curcv); # debug

    return 1;
}

my @parents = ();

sub walkoptree_slow {
    # actually recurse the bytecode tree
    # stolen from B.pm, modified
    my $op = shift;
    my $sub = shift;
    my $level = shift;
    $level ||= 0;
    # warn(sprintf("walkoptree: %d. %s\n", $level, peekop($op))) if $debug;
    $sub->($op, $level, \@parents);
    if ($op->can('flags') and $op->flags() & OPf_KIDS) {
        # print "debug: go: ", '  ' x $level, $op->name(), "\n"; # debug
        push @parents, $op;
        my $kid = $op->first();
        my $next;
        next_kid:
          # was being changed right out from under us, so pre-compute
          $next = 0; $next = $kid->sibling() if $$kid;
          walkoptree_slow($kid, $sub, $level + 1);
          $kid = $next;
          goto next_kid if $kid;
        pop @parents;
    }
    if (B::class($op) eq 'PMOP' && $op->pmreplroot() && ${$op->pmreplroot()}) {
        # pattern-match operators
        push @parents, $op;
        walkoptree_slow($op->pmreplroot(), $sub, $level + 1);
        pop @parents;
    }
};

sub look_for_things_to_diddle {
 
    # $sub->($op, $prev, $parfirst, $parlast, $level);

    my $self = shift;       # op object
    my $level = shift;
    my $parents = shift;

    return unless $self and $$self;

    return unless exists $parents->[0]; # root op isn't that interesting and we need a parent
    my $parent = $parents->[-1];
    my $non_null_parent = do { my $i = -1; $i-- until $parents->[$i]->name() ne 'null'; $parents->[$i]; };

    if($self->name() eq 'nextstate') {

        # record where we are in the program for any diagnstics
        
        # $lastpack = $self->stash()->PV(); # NAME();
        $lastpack = '';
        $lastfile = $self->file();
        $lastline = $self->line();

    }

    # return unless $self->name() eq 'padav' or $self->name() eq 'padhv';

    # print "debug: go: ", $self->name(), "\n";

    # create some reusable logic to do the actual bytecode splicing

    my $padav_to_ref = sub {

        # the bytecode tree is both a tree (built with ->sibling and ->first) and a thread
        # (threaded with ->next, as well as some special ones for loops and conditionals).
        # this logic modifies both at the same time so that other B::Generate hacks have a
        # valid tree to work on and so that the bytecode actually executes.
        # see http://perldesignpatterns.com/?PerlAssembly

        # print "debug: doing padav_to_ref $lastpack $lastfile $lastline\n";
        # print "modifying ", $self->name, " at addresss ", $$self, "\n";

        my $padav = $self;
        my $nextstate = $previous->{$$padav} or die "no previous"; # may not actually be a nextstate but that's okey
        my $padav_next = $padav->next;
        my $padav_sibling = $padav->sibling; # may be 0

        my $list = B::LISTOP->new('list', OPf_WANT_LIST | OPf_KIDS | OPf_REF | OPf_MOD, 0, 0);
        my $pushmark = B::OP->new('pushmark', OPf_WANT_SCALAR | OPf_REF | OPf_MOD);
        my $refgen = B::UNOP->new('refgen', OPf_WANT_SCALAR | OPf_KIDS | OPf_MOD, 0);

        $nextstate->next($pushmark);
        $nextstate->sibling($refgen) if $nextstate->can('sibling') and ${$nextstate->sibling} == $$padav;

        $parent->first($refgen) if $parent->can('first') and ${$parent->first} == $$padav;
        $parent->last($refgen) if $parent->can('last') and ${$parent->last} == $$padav;

        $list->first($pushmark);
        $list->last($padav);
        $list->next($pushmark); # $list isn't ever called and in non-fudged bytecode it is optimized away

        $pushmark->next($padav);
        $pushmark->sibling($padav);

        $padav->next($refgen);
        $padav->flags(OPf_WANT_LIST | OPf_REF | OPf_MOD);
        $padav->sibling(0);

        $refgen->first($list);
        $refgen->next($padav_next);
        $refgen->sibling($padav_sibling);

        $did_already{$$self}++;
        $redo_reverse_indices->();

    };

    my $insert_rv2av = sub {

        # disused because of problems with perl not liking push $foo, $bar in the least ;)

        # print "debug: doing insert_rv2av $lastpack $lastfile $lastline\n";

        my $padsv = $self;
        my $padsv_next = $padsv->next;
        my $padsv_sibling = $padsv->sibling; # may be 0
        my $rv2av = B::UNOP->new('rv2av', OPf_WANT_LIST | OPf_KIDS | OPf_REF | OPf_MOD, 0);

        $parent->first($rv2av) if $parent->can('first') and ${$parent->first} == $$padsv;
        $parent->last($rv2av)  if $parent->can('last') and ${$parent->last} == $$padsv;

        $padsv->flags(OPf_WANT_SCALAR | OPf_MOD);
        $padsv->private($padsv->private & OPfDEREF_AV); # tells it to autovivify a reference if needed
        $padsv->next($rv2av); 
        $padsv->sibling(0);

        $rv2av->first($padsv);
        $rv2av->next($padsv_next);
        $rv2av->sibling($padsv_sibling);

        $did_already{$$self}++;
        $redo_reverse_indices->();

    };

    my $insert_join = sub {

        # no warnings 'syntax';  # magic

        # print "debug: doing insert_join $lastpack $lastfile $lastline\n";

        # perl -MO=Concise -e 'my @foo = (1..20); my $foo = "bar" . @foo . "baz";'

        # 9     <;> nextstate(main 2 -e:1) v ->a
        # g     <2> sassign vKS/2 ->h
        # e        <2> concat[t7] sKS/2 ->f
        # c           <2> concat[t6] sK/2 ->d
        # a              <$> const(PV "bar") s ->b
        # b              <0> padav[@foo:1,3] s ->c    <-- splice stuff in here
        # d           <$> const(PV "baz") s ->e
        # f        <0> padsv[$foo:2,3] sRM*/LVINTRO ->g

        # perl -MO=Concise 
        # my @foo = (1..20); print "bar" . join(${'$"'}, @foo), "baz";

        # 9     <;> nextstate(main 3 -:1) v ->a 
        # j     <@> print vK ->k
        # a        <0> pushmark s ->b
        # h        <2> concat[t6] sK/2 ->i
        # b           <$> const(PV "bar") s ->c             <-- * start
        # g           <@> join[t5] sK/2 ->h                 <-- replaces padav in tree
        # c              <0> pushmark s ->d                 <-- insert before padav in execution
        # e              <1> rv2sv sK/1 ->f                 
        # d                    <$> const(PV "$\"") s ->e 
        # f              <0> padav[@foo:1,3] l ->g
        # i        <$> const(PV "baz") s ->j

        my $padav = $self;
        my $nextstate = $previous->{$$padav} or die "no previous"; # actually const 'bar' in the example
        my $padav_next = $padav->next;
        my $padav_sibling = $padav->sibling; # may be 0

        my $pushmark  = B::OP->new('pushmark', OPf_WANT_SCALAR);
        my $const     = B::SVOP->new('const', OPf_WANT_SCALAR, '"');
        my $rv2sv     = B::UNOP->new('rv2sv', OPf_WANT_SCALAR | OPf_KIDS, 0); 

        # have to build structure to avoid coredumps from ck_ routines! suck! redundant stuff
        $pushmark->sibling($const); $const->sibling(0); # chain of siblings under $join
        my $join      = B::LISTOP->new('join', OPf_WANT_SCALAR | OPf_KIDS, $pushmark, $padav);

        $parent->first($join) if $parent->can('first') and ${$parent->first} == $$padav;
        $parent->last($join) if $parent->can('last') and ${$parent->last} == $$padav;

        $nextstate->next($pushmark); # splice in
        $nextstate->sibling($join) if $nextstate->can('sibling') and ${$nextstate->sibling} == $$padav;

        $pushmark->sibling($rv2sv);
        $pushmark->next($const);

        $const->next($rv2sv);

        $rv2sv->sibling($padav);
        $rv2sv->next($padav);
        $rv2sv->first($const);

        $padav->sibling(0);
        $padav->flags(OPf_WANT_LIST);
        $padav->next($join);

        $join->private(2); # XXX - voodoo - to match code generated by perl - does this mean we join two things?
        $lastpadtmp++; $lastpadtmp %= scalar @padtmps;
        # XXX should alternate between two temps, or through the whole queue - 
        # not sure - all must be able to live on the stack at the same time though
        $join->targ($padtmps[$lastpadtmp]); 
        $join->first($pushmark);
        $join->last($padav);
        $join->sibling($padav_sibling);
        $join->next($padav_next); # splice out

        $did_already{$$self}++;
        $redo_reverse_indices->();

    };

    # hash or array variable used in scalar context other than as boolean or number:

    goto not_padav unless $self->name() eq 'padav' or $self->name() eq 'padhv';
    goto not_padav unless OPf_WANT_SCALAR == ($self->flags() & OPf_WANT);
    goto not_padav if $self->flags & OPf_REF; # things like 'exists' want a ref
    goto not_padav if exists $mathops->{$non_null_parent->name()};
    goto not_padav if exists $boolops->{$non_null_parent->name()};
    goto not_padav if exists $stringops->{$non_null_parent->name()};
    goto not_padav if $did_already{$$self};

    $padav_to_ref->();

    not_padav:

    # both subroutine and method calls:

    goto not_entersub unless $self->name() eq 'padav' or $self->name() eq 'padhv';
    goto not_entersub unless $non_null_parent->name() eq 'entersub';
    goto not_entersub unless OPf_WANT_LIST == ($self->flags() & OPf_WANT);
    goto not_entersub if $did_already{$$self};
    $padav_to_ref->();
        
    not_entersub:

    # arrays should stringify when used in scalar context with a string op:

    goto not_string unless $self->name eq 'padav';
    goto not_string unless exists $stringops->{$non_null_parent->name()};
    goto not_string unless OPf_WANT_SCALAR == ($self->flags() & OPf_WANT);
    goto not_string if $did_already{$$self};

    die 'Due to a limitation of B::Generate and this module you must declare several lexical variables: my($t1, $t2, $t3). ' .
        'This is sadly required to use arrays in string context with Perl6::Contexts. ' unless @padtmps;

    $insert_join->();

    not_string:

    return 0;

}

1;

=pod

=head1 NAME

L<Perl6::Contexts> - array and hash variables turn into references to themselves when
used in non-numeric scalar context or as function arguments

=head1 SYNOPSIS

  my @foo = ( 1 .. 20 ); 
  my $foo = @foo;                  # same as: my $foo = \@foo;
  my $foo = 0 + @foo;              # unchanged - length of @foo
  $obj->some_method(10, 20, @foo); # same as: $obj->some_method(10, 20, \@foo);
  some_function(10, 20, @foo);     # same as: some_function(10, 20, \@foo);

=head1 DESCRIPTION

L<Perl6::Contexts> makes Perl 5 behave more like Perl 6 with regard to the 
array and hash variables as used as arguments to operators, method calls, and functions.

This module doesn't add new syntax -- it merely changes the meaning of existing
syntax.
Using this module to make Perl 5 more like Perl 6 won't go very far towards
writing Perl 5 that will run under Perl 6 but it I<will> help you get used to
some of the changes.

To run legacy Perl 5 along side Perl 6, check out L<PONIE> or L<Inline::Pugs>.

=head2 Context

Perl 6 divides scalar context into boolean, numeric, string, and object context, among others. 

=head3 Reference Context

Arrays and hashes used in reference context turn into a reference to themselves.
We assume reference context unless we know better. This vaguely approximates
Perl 6's behavior. For example, given a completely spurrious C<< my $foo = @bar >>,
we assume that C<$foo> should be a reference to C<@bar>.

=head3 Numeric Context

Arrays used in numeric context return their size, as in Perl 5. 
Perl 6 uses the C<+> prefix or C<num>, C<int>, or C<float> keywords to force numeric context.
We don't have those keywords (yet), but C<+> and C<scalar> do the trick for now.
Numeric context is also supplied by math related operators such as C<->, C<*>, C<sin>,
and so on.

Force numeric context to get the old Perl 5 behavior of counting the elements in an array or hash:

  scalar @arr;
  0 + @arr;

In Perl 6, the C<0> is redundant and undesireably ugly but it is required for our purposes so
I suggest using C<scalar> instead.

Note that hashes return internal memory allocation information when used in scalar context -
use C<scalar keys %hash> to count the number of items it contains.

=head3 Boolean Context

Boolean context formalizes the murky semantics of "zero but true" for Perl 6
but our implementation doesn't do anything to help with that.
Our boolean context is currently identical to Perl 5's scalar context
which is identical to numeric context and is provided by
C<and>, C<or>, C<&&>, C<||>, and other conditionls.

=head3 String Context

Perl 6 gives arrays, hashes, and objects, among other things, control over how they present themselves
when used as a string. 
Perl 6 adds interpolation of hashes in quoted text, along with the arrays and scalars that 
already interpolate in Perl 5.
Each variable can be extended with a trait to control the exact details of its presentation.
Perl 5 allows a minimal amount of presentation control with the global C<< $" >> variable.
See F<perldoc perlvar>'s entry on C<< $" >> for details.
We don't try to interpolate hashes in strings but we do C<join> on C<< $" >> to stringify
arrays when used as a string. The C<.> operator, for example, forces string context.

  use Perl6::Contexts;
  my $t1; my $t2; my $t3;
  my @arr = ( 1 .. 20 );
  print '@arr: ' . @arr . "\n";  # note that . is used instead of comma

C<.> forces string context on C<@arr> in this example.

Or:

  use Perl6::Contexts;
  my $t1; my $t2; my $t3;
  my @arr = ( 1 .. 20 );
  $" = '-';
  @arr =~ m/15-16/ or die;

C<=~> forces string context on C<@arr> in this example. That's a lot more useful
than matching on a string representing of the number of things in C<@arr>.

Yes, the C<my $t1> things are needed to use arrays in string context. It's a long story.
See the B<BUGS> section for details if you're curious but it's a limitation I hope
to overcome soon. There must be one such variable allocated for each string context
use of an array in the single most complex expression in the module (and thus
is the sacrifice that must be paid homage to satisify the demons that make this module work).

=head3 Context Summary

This module cheats a bit in guessing context. Contexts do not propogate (yet) as
they do in Perl. Operators such as C<< || >> do not yet apply the context to their operands
that they themselves got from somewhere. The point of some contexts, such as boolean,
is entirely missed. In general, the Perl 6 rules and this module come closer to
the ideal of "do what I mean".

=head2 Function Calls

Hashes and arrays as function and method call arguments don't flatten by
default. Perl 6 uses the splat operator, C<*>, to flatten arrays and hashes sent
as arguents to functions.
Like Perl 6, we don't flatten implicitly either. Unlike Perl 6, explicit flattening is
kind of painful.

  use Perl6::Contexts;

  my @numbers = map int rand 100, 1 .. 100;
  sub_that_wants_a_bunch_of_numbers(@numbers);   # passes by reference - wrong
  sub_that_wants_a_bunch_of_numbers(\@numbers);  # same thing - wrong

In order to flatten things for subroutines that actually want flattened
arrays, use one of these tricks:

  sub_that_wants_a_bunch_of_numbers(@numbers[0 .. $#numbers]);
  sub_that_wants_a_bunch_of_numbers(@numbers->flatten());

C<< ->flatten() >> requires F<autobox>. See below. Perl 6's C<*> operator,
which forcefully unflattens arrays, is not available in Perl 5 or via
this module.

Subroutines called by code subjected to the rules of F<Perl6::Contexts> must
accept references to arrays and hashes I<unless> the array or hash in the
call to that subroutine was I<explicitly> flattened:

  use Perl6::Contexts;

  my @array = ( 1 .. 20 );
  sub_that_wants_an_array_ref(@array);

  sub sub_that_wants_an_array_ref {
      my $arrayref = shift;   # @array turned into a reference
      my @array = @$arrayref; # or use an autobox trick if you like
  }

This applies even if the subroutine or method is in another package entirely.
Note that the requirement that C<@$arrayref> be written that way and not
C<$arrayref> is an incompleteness of this module though obviously we aren't
going to munge modules that don't use us.
See the F<autobox> tricks below and of course C<$arrayref> may be used directly
as the array reference that it is.

=head2 autobox Interopation

This module works with L<autobox>. Normally L<autobox> requires a reference, a scalar, a number, a string,
or a code reference, which excludes arrays and hashes:

  use autobox;
  use autobox::Core;
  my @arr = ( 1 .. 20);
  @arr->sum->print;     # doesn't work without Perl6::Contexts
  (\@arr)->sum->print;  # works without Perl6::Contexts but ugly

Same goes for hashes.
(While this is a fluke side effect of what we're doing I was aware of the
consequence early on and it was a great motiviation to create this module, so
F<autobox> integration is a feature beyond any doubt.)

Often you'll want arrays and hashes to flatten when passed as arguments:

  use Perl6::Contexts;

  my @numbers = map int rand 100, 1 .. 100;
  sub_that_wants_a_bunch_of_numbers(@numbers);  # passes by reference - wrong

F<autobox> and F<autobox::Core> may be used to force array flattening:

  use Perl6::Contexts;
  use autobox;
  use autobox::Core;

  my @numbers = map int rand 100, 1 .. 100;
  sub_that_wants_a_bunch_of_numbers(@numbers->flatten);  # explicit flattening

To accomplish this without F<autobox>, you may take a slice of the entire array:

  use Perl6::Contexts;

  my @numbers = map int rand 100, 1 .. 100;
  sub_that_wants_a_bunch_of_numbers(@numbers[0 .. $#numbers]); # ugly but works

=head1 BUGS

Most of these bugs are fixable but why should I bother if no one is actually using
this module?
Want a bug fixes?
Email me.
A little encouragement goes a long way.

Until I get around to finishing reworking C<B::Generate>, C<B::Generate-1.06> needs
line 940 of C<B-Generate-1.06/lib/B/Generate.c> changed to read 
C<o = Perl_fold_constants(o);> (the word C<Perl> and an understore should be inserted).
This is in order to build C<B::Generate-1.06> on newer Perls.

C<..> and C<...> aren't yet recognized numeric operators.

C<@arr = ( @arr2, @arr3, @arr4 )> should not flatten (I think) but currently does.

Scalar variables used in conditionals (such as C<if> and C<and>) don't
dereference themselves and reference values are always true
(unless you do something special). 
Hence this will always die:

  use Perl6::Contexts;
  my @arr = ( );      # completely empty arrays evaluate false
  my $arrref = @arr;  # takes a reference
  die if $arrref;     # always dies - ERROR

You must use C< autobox > and C< autobox::Core > and write C<< die if $arrref->flatten() >>,
or else write the old Perl 5 stand by, C< @$arrref >.

C<push>, C<pop>, C<exists>, C<delete>, C<shift>, C<unshift>, C<sort>, C<map>,
C<join>, and C<grep> issue compile time warnings when used on a scalar even
though this scalar could only possibly be a reference.

  push $arrref, 1;

  # diagnostic: Type of arg 1 to push must be array (not scalar dereference)

Perl 6 handles this correctly. Perl 5 could with replacement versions of
those statements written in Perl. Perhaps in the next version this module will. 
Of course, it would be nice if the core did the "right thing" ;)

The unary C<*> operator doesn't flatten lists as it does in Perl 6. 
Instead, F<autobox> and C<< ->flatten >> must be used for this, or
synonymously, C<< ->elements >>.
As far as I know, this is unfixable without resorting to a source filter, 
which I won't do in this module.

C<scalar> is considered to provide numeric context. 
This is not consistent
with Perl 6, where C<string>, C<bool>, C<bit>, C<string>, C<int>, C<num>, and C<float>
generate contexts, much like C<scalar> does in Perl 5. 
This module should, but doesn't, export those keywords.

While C<0 + @arr> accidentally works to put C<@arr> in numeric context and get its length,
no unary C<~> (yet) exists to force string context (though it could - it would mean no
more negating strings full of bits without calling a function in another module to do it).

C<< my @array = $arrayref >> should, but doesn't, dereference C<$arrayref> and dump its
contents into C<@array>. 
This can, and should, be done but I haven't gotten to it yet.

Hashes in strings should interpolate but that's outside the scope of this module.
See L<Perl6::Interpolators> for an implementation.

Making users create temporaries is a kludge as ugly as any. 
I plan to roll this ability into F<B::Generate>.
Why are C<my $t1>, C<my $t2>, and so on, required?
Perl associates nameless lexical variables with operations to speed up the stack machine.
Each operation has its own virtually private scalar value, array value, hash value, or so on,
that it can push to the stack any time it likes without having to allocate it. Next time the
instruction runs again it knows that it can reuse the same variable. F<B::Generate> isn't
able to allocate these for instructions so I have to use preexisting named variables.

=head1 HISTORY

0.3 Fixes a serious bug where only the first of any number of arrays or hashes passed
to a subroutine would referencify. The logic to loop through through the bytecode
couldn't handle the bytecode changing out from under it and it lost its place.
Added several todo list items to the top of the file for myself and those curious 
about possible future development.

0.2 Fixes a show stopper bug that broke C<autobox> and method calls, where the same
array or hash would referencify twice. Code with anonymous subroutines 
triggered a fatal bug.

Versions fixing bugs I've found and adding features I think of will increment the minor
version number. 1.0 will be released after a sufficient amount of user feedback suggestions
that I'm not as far off in la-la land as I might be for all I know.
This la-la land caveat applies to the Perl 6 specification as well, which I am doubtlessly botching.

=head1 SEE ALSO

L<autobox> associates methods with primitive types allowing
more complex APIs for types than would be reasonable to
create built-in functions for. F<autobox>ing also 
simplifies complex expressions that would require a lot
of parenthesis by allowing the expression to be arranged
into more a logical structure.

L<autobox::Core> compliments F<autobox> with wrappers for most
built-in functions, some statements, some functionalish methods
from core modules, and some Perl 6-ish things.

Perl 6 is able to take C<$arrayref[0]> to mean C<$arrayref.[0]> which
is C<< $arrayref->[0] >> in Perl 5. This module won't get you that
but see L<Perl6::Variables>. 

L<Want> gives Perl 5 subroutines Perl 6-like information about the
context they execute in, including the number of result values
expected, boolean context, C<BOOL>, and various kinds of
reference contexts. It is a generalized replacement for the
built-in F<wantarray> function.

L<B> represents Perl internal data structures (including and especially
bytecode instructions for the virtual machine) as Perl objects within
F<perl> itself. L<B::Generate> extends L<B> with the capability to modify
this bytecode from within the running program (!!!). This module uses
these two modules to do what it does. L<Opcode> served as a reference,
and code was stolen from L<B::Utils>, L<B::Deparse>, and L<B::Concise>
(but with implicit permission - yes, Free Software programmers do steal
but never uninvited - seriously, I owe a debt of gratitude to those
whose work I've built on, especially Simon Cozens and Malcolm Beattie in this case).

L<http://perldesignpatterns.com/?PerlAssembly> attempts to document the Perl
internals I'm prodding so bluntly.

=head1 AUTHOR

SWALTERS, L<scott@slowass.net>

=cut

__END__

        # my $cv = *{'Sink::bathe'}{CODE};
        #  $curcv = B::svref_2object($cv);

    # $self->append_elem(B::COP->new($self->flags(), ''.$self->line(), 0));

    $parent->first($newns) if $parent and $parent->first() eq $self;
    $parent->last($newns) if $parent and $parent->last() eq $self;

    print "we're first child\n" if $parent and $parent->first() eq $self;
    print "we're last child\n" if $parent and $parent->last() eq $self;
    print "debug: first: ", $self, ' ', $parent->first(), "\n" if $parent;
    print "debug: last: ", $self, ' ', $parent->last(), "\n" if $parent;

# instead of replacing the op, just stick ours in front. that'll keep diagnostics correct
# and perl can still find the label - use prepend_elem
    B::OP::prepend_elem($newns);

# handle control structures

--------------

reference bytecode - for my reference, that is. Please disreguard. Thank you!

perl -MO=Concise -e 'my @bar = (1 .. 20); my $foo = @bar; print $foo, "\n";'

i  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <2> aassign[t4] vKS ->9
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av lKP/1 ->6
4              <$> const(AV ) s ->5
-        <1> ex-list lK ->8
6           <0> pushmark s ->7
7           <0> padav[@bar:1,3] lRM*/LVINTRO ->8
9     <;> nextstate(main 2 -e:1) v ->a
c     <2> sassign vKS/2 ->d                   <-- sassign
a        <0> padav[@bar:1,3] s ->b
b        <0> padsv[$foo:2,3] sRM*/LVINTRO ->c
d     <;> nextstate(main 3 -e:1) v ->e
h     <@> print vK ->i
e        <0> pushmark s ->f
f        <0> padsv[$foo:2,3] l ->g
g        <$> const(PV "\n") s ->h
-e syntax OK

vs

e     <2> sassign vKS/2 ->f                   <-- sassign
c        <1> refgen sK/1 ->d
-           <1> ex-list lKRM ->c
a              <0> pushmark sRM ->b
b              <0> padav[@bar:1,3] lRM ->c
d        <0> padsv[$foo:2,3] sRM*/LVINTRO ->e

vs

perl -MO=Concise -e 'my @bar = (1 .. 20); my $foo = @bar->size; print $foo, "\n";'
l  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <2> aassign[t4] vKS ->9
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av lKP/1 ->6
4              <$> const(AV ) s ->5
-        <1> ex-list lK ->8
6           <0> pushmark s ->7
7           <0> padav[@bar:1,3] lRM*/LVINTRO ->8
9     <;> nextstate(main 2 -e:1) v ->a
f     <2> sassign vKS/2 ->g                   <-- sassign
d        <1> entersub[t6] sKS/TARG ->e      
a           <0> pushmark s ->b
b           <0> padav[@bar:1,3] sM ->c
c           <$> method_named(PVIV "size") s ->d


perl -MO=Concise -e 'my @bar = (1 .. 20); my $foo = 0 + @bar; print $foo, "\n";'
k  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <2> aassign[t4] vKS ->9
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av lKP/1 ->6
4              <$> const(AV ) s ->5
-        <1> ex-list lK ->8
6           <0> pushmark s ->7
7           <0> padav[@bar:1,3] lRM*/LVINTRO ->8
9     <;> nextstate(main 2 -e:1) v ->a
e     <2> sassign vKS/2 ->f
c        <2> add[t6] sK/2 ->d
a           <$> const(IV 0) s ->b
b           <0> padav[@bar:1,3] s ->c
d        <0> padsv[$foo:2,3] sRM*/LVINTRO ->e
f     <;> nextstate(main 3 -e:1) v ->g
j     <@> print vK ->k
g        <0> pushmark s ->h
h        <0> padsv[$foo:2,3] l ->i
i        <$> const(PV "\n") s ->j


------ crap --------

# before:

g     <@> print vK ->h
a        <0> pushmark s ->b
e        <1> entersub[t5] lKS/TARG ->f
b           <0> pushmark s ->c
c           <0> padav[@foo:230,231] sM ->d
d           <$> method_named(PVIV "size\0000x822be60") l* ->e
f        <$> const(PV "\n") s ->g

# after (okey, not really the same code...):

-     <@> print vK ->-
-        <0> pushmark s ->-
-        <1> entersub[t5] lKS/TARG ->-
-           <0> pushmark s ->-
-           <1> refgen sK/1 ->-
-              <@> list lKRM ->-
-                 <0> pushmark sRM ->-
-                 <0> padav[@foo:266,267] lRM ->-
-           <$> method_named(PVIV "size\0000x8270308") l* ->-
-        <$> const(PV "\n") s ->-

my @a = (1 .. 20: (\@a)->size();
-e syntax OK
g  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <2> aassign[t4] vKS ->9
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av lKP/1 ->6
4              <$> const(AV ) s ->5
-        <1> ex-list lK ->8
6           <0> pushmark s ->7
7           <0> padav[@a:1,2] lRM*/LVINTRO ->8
9     <;> nextstate(main 2 -e:1) v ->a
f     <1> entersub[t5] vKS/TARG ->g
a        <0> pushmark s ->b
d        <1> refgen sKPM/1 ->e
-           <1> ex-list lKRM ->d
b              <0> pushmark sRM ->c
c              <0> padav[@a:1,2] lRM ->d
e        <$> method_named(PVIV "size") ->f

--------

example of calling a function with an array in list context on the arguent list:
foo 10, 20, @bar;

f     <1> entersub[t5] vKS/TARG,1 ->g
-        <1> ex-list K ->f
a           <0> pushmark s ->b
b           <$> const(IV 10) sM ->c
c           <$> const(IV 20) sM ->d
d           <0> padav[@bar:425,426] lM ->e
-           <1> ex-rv2cv sK/129 ->-
e              <$> gv(PVLV ) s ->f
g     <;> nextstate([none] 424 scalarrefs5.pl:13) v ->h
n     <1> entersub[t6] vKS/TARG ->o
h        <0> pushmark s ->i
i        <$> const(PV "blurgh") sM/BARE ->j
j        <$> const(IV 30) sM ->k
k        <$> const(IV 40) sM ->l
l        <0> padav[@bar:423,425] lM ->m
m        <$> method_named(PVIV "bjork") ->n

same modified, to take a reference to the list

h     <1> entersub[t5] vKS/TARG,1 ->i
-        <1> ex-list K ->h
a           <0> pushmark s ->b
b           <$> const(IV 10) sM ->c
c           <$> const(IV 20) sM ->d
f           <1> refgen lKM/1 ->g
-              <1> ex-list lKRM ->f
d                 <0> pushmark sRM ->e
e                 <0> padav[@bar:1,3] lRM ->f
-           <1> ex-rv2cv sK/129 ->-
g              <$> gv(*foo) s ->h

----------

This won't happen today...  
"Type of arg 1 to push must be array (not private variable)..."
mauke suggested overloading CORE::GLOBAL::push

push $a, 30

e     <@> push[t4] K/2 ->f
b        <0> pushmark s ->c
c        <0> padsv[$a:1,2] ->d
d        <$> const(IV 30) s ->e

should be munged to: push @$a, 30

f     <@> push[t5] vK/2 ->g
b        <0> pushmark s ->c
d        <1> rv2av[t4] lKRM/1 ->e             <--- just one little rv2av
c           <0> padsv[$a:1,2] sM/DREFAV ->d
e        <$> const(IV 30) s ->f

----------

perl -MO=Concise -e 'my @foo = (1..20); my $foo = "bar" . @foo . "baz";'

h  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
8     <2> aassign[t4] vKS ->9
-        <1> ex-list lK ->6
3           <0> pushmark s ->4
5           <1> rv2av lKP/1 ->6
4              <$> const(AV ) s ->5
-        <1> ex-list lK ->8
6           <0> pushmark s ->7
7           <0> padav[@foo:1,3] lRM*/LVINTRO ->8
9     <;> nextstate(main 2 -e:1) v ->a
g     <2> sassign vKS/2 ->h
e        <2> concat[t7] sKS/2 ->f
c           <2> concat[t6] sK/2 ->d
a              <$> const(PV "bar") s ->b
b              <0> padav[@foo:1,3] s ->c    <-- splice stuff in here
d           <$> const(PV "baz") s ->e
f        <0> padsv[$foo:2,3] sRM*/LVINTRO ->g

perl -MO=Concise -e 'my @foo = (1..20); my $foo = "bar@{foo}baz";'

9     <;> nextstate(main 2 -e:1) v ->a
j     <2> sassign vKS/2 ->k
-        <1> ex-stringify sK/1 ->i
-           <0> ex-pushmark s ->a
h           <2> concat[t8] sKS/2 ->i
f              <2> concat[t7] sK/2 ->g
a                 <$> const(PV "bar") s ->b
e                 <@> join[t6] sK/2 ->f         <-- join replaces padav
b                    <0> pushmark s ->c
-                    <1> ex-rv2sv sK/1 ->d
c                       <$> gvsv(*") s ->d
d                    <0> padav[@foo:1,3] l ->e  <--- padav moved here
g              <$> const(PV "baz") s ->h
i        <0> padsv[$foo:2,3] sRM*/LVINTRO ->j

# some goop to look up $" runtime

        # 6     <@> print vK ->7
        # 3        <0> pushmark s ->4
        # 5        <1> rv2sv sK/1 ->6
        # -           <@> scope sK ->5
        # -              <0> ex-nextstate v ->4
        # 4              <$> const(PV "$\"") s ->5

# mixed:

perl -MO=Concise 
my @foo = (1..20); print "bar" . join(${'$"'}, @foo), "baz";

9     <;> nextstate(main 3 -:1) v ->a
j     <@> print vK ->k
a        <0> pushmark s ->b
h        <2> concat[t6] sK/2 ->i
b           <$> const(PV "bar") s ->c
g           <@> join[t5] sK/2 ->h
c              <0> pushmark s ->d
e              <1> rv2sv sK/1 ->f
-                 <@> scope sK ->e
-                    <0> ex-nextstate v ->d
d                    <$> const(PV "$\"") s ->e
f              <0> padav[@foo:1,3] l ->g
i        <$> const(PV "baz") s ->j


# current actual generated bytecode:

-     <@> print vK ->-
-        <0> pushmark s ->-
-        <2> concat[t12] sKS/2 ->-
-           <2> concat[t10] sK/2 ->-
-              <$> const(PV "foo") s ->-
-              <@> join[$t1:105,107] sK/1 ->-
-                 <0> pushmark s ->-
-                 <1> rv2sv sK/1 ->-
-                    <$> const(PV "$\"") s ->-
-                 <0> padav[@arr:106,107] l ->-
-           <$> const(PV "\n") s ->-


perl -MO=Concise -e 'print $", "\n";'
7  <@> leave[1 ref] vKP/REFC ->(end)
1     <0> enter ->2
2     <;> nextstate(main 1 -e:1) v ->3
6     <@> print vK ->7
3        <0> pushmark s ->4
-        <1> ex-rv2sv sK/1 ->5
4           <$> gvsv(*") s ->5
5        <$> const(PV "\n") s ->6

-----

# XXX \(list) should (maybe) be converted to [list] - should be a matter of swapping a refgen with a srefgen


--------


Bug!

debug: go: leavesub
debug: go:   lineseq
debug: go:     sassign
debug: go:       shift
debug: go:         rv2av
debug: go:     sassign
debug: go:       shift
debug: go:         rv2av
debug: go:     print
debug: go:       aelem
debug: go:         rv2av
debug: go:     print
debug: go:       aelem
debug: go:         rv2av

  use Perl6::Contexts;

  sub do_something {
    my $array1_ref = shift;
    my $array2_ref = shift;
    print $array1_ref->[0], "\n";
    print $array2_ref->[0], "\n";
  }

  my @array1 = map int rand 100, 1 .. 10;
  my @array2 = map int rand 100, 1 .. 10;

  do_something(@array1, @array2);

only modifying the first one... reverse links (parent, previous) getting out of date?

fixed
