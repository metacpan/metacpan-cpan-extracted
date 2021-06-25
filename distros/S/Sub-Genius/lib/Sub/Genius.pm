package Sub::Genius;

use strict;
use warnings;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use Digest::MD5 ();
use Storable    ();
use Cwd         ();

our $VERSION = q{0.314002};

# constructor
sub new {
    my $pkg  = shift;
    my %self = @_;
    my $self = \%self;
    bless $self, $pkg;
    die qq{'preplan' parameter required!\n} if not defined $self->{preplan};

    # set to undef to disable preprocessing
    if ( not exists $self->{preprocess} ) {
        $self->{preprocess} = 1;
    }

    # set to undef to disable caching
    if ( not exists $self->{cachedir} ) {
        $self->cachedir( sprintf( qq{%s/%s}, Cwd::cwd(), q{_Sub::Genius} ) );
    }

    # keep a historical record
    $self->original_preplan($self->preplan);

    # 'pre-process' plan - this step maximizes the chance of capturing
    # the same checksum for identical PREs that may just be formatted differently
    if ( $self->{preprocess} ) {
        $self->_trim;
        $self->_balkanize;
        $self->_normalize;
    }

    # generates checksum based on post-preprocessed form
    $self->checksum( Digest::MD5::md5_hex( $self->preplan ) );

    $self->pregex( FLAT::Regex::WithExtraOps->new( $self->preplan ) );
    return $self;
}

sub cachefile {
    my $self = shift;
    return ( $self->cachedir ) ? sprintf( qq{%s/%s}, $self->cachedir, $self->checksum ) : undef;
}

sub cachedir {
    my ( $self, $dir ) = @_;
    if ($dir) {
        $self->{cachedir} = $dir;
        if ( not -d $self->{cachedir} ) {
            mkdir $self->{cachedir}, 0700 || die $!;
        }
    }
    return $self->{cachedir};
}

sub checksum {
    my ( $self, $sum ) = @_;
    if ($sum) {
        $self->{checksum} = $sum;
    }
    return $self->{checksum};
}

sub do_cache {
    my $self = shift;
    return ( $self->cachedir and $self->checksum and $self->cachefile );
}

# strips comments and empty lines
sub _trim {
    my $self = shift;
    my $_pre = q{};
    my @pre  = ();
  STRIP:
    foreach my $line ( split /\n/, $self->{preplan} ) {
        next STRIP if ( $line =~ m/^\s*#|^\s*$/ );
        my @line = split /\s*#/, $line;
        push @pre, $line[0];
    }
    $self->preplan( join qq{\n}, @pre );
    return $self->preplan;
}

sub _balkanize {
    my $self = shift;
    if ( $self->{preplan} =~ m/[#\[\]]+/ ) {
        die qq{plan to be bracketized must not contain '#', '[', or ']'};
    }
    my $_pre = q{};
    my @pre  = ();
  STRIP:
    foreach my $line ( split /\n/, $self->{preplan} ) {

        # supports strings with namespace delim, '::'
        $line =~ s/([a-zA-Z:_\d]+)/\[$1\]/g;
        push @pre, $line;
    }
    $self->preplan( join qq{\n}, @pre );
    return $self->preplan;
}

# currently, removes all spaces and newlines
sub _normalize {
    my $self     = shift;
    my @pre      = split /\n/, $self->{preplan};
    my $minified = join qq{}, @pre;
    $minified =~ s/[\s]+//g;
    $self->preplan($minified);
    return $self->preplan;
}

# accessor for original plan
sub original_preplan {
    my ( $self, $pp ) = @_;
    if ($pp) {
        $self->{original_preplan} = $pp;
    }
    return $self->{original_preplan};
}

# accessor for original plan
sub preplan {
    my ( $self, $pp ) = @_;
    if ($pp) {
        $self->{preplan} = $pp;
    }
    return $self->{preplan};
}

# accessor for original
sub pregex {
    my ( $self, $pregex ) = @_;
    if ($pregex) {
        $self->{pregex} = $pregex;
    }
    return $self->{pregex};
}

# set/updated whenever ->next() and friends are called, simple way to
# query what plan was last created; RO, not destructive on current 'plan'
sub plan {
    my $self = shift;
    return $self->{plan};
}

# setter/getter for DFA
sub dfa {
    my ( $self, $dfa ) = @_;
    if ($dfa) {
        $self->{DFA} = $dfa;
    }
    return $self->{DFA};
}

# Converts plan -> PFA -> NFA -> DFA:
# NOTE: plan is not generated here, much call ->next()
#  can pass param to underlying ->dfa also, like 'reset => 1'
sub init_plan {
    my ( $self, %opts ) = @_;

    # requires plan (duh)
    die qq{Need to call 'new' with 'preplan => q{PRE...}' to initialize\n} if not $self->pregex;

    # convert PRE to DFA
    $self->convert_pregex_to_dfa(%opts);

    # warn if DFA is not acyclic (infinite strings accepted)
    if ( $self->dfa->is_infinite ) {
        if ( not $self->{'allow-infinite'} ) {
            warn qq{(fatal) Infinite language detected. To avoid, do not use Kleene Star (*).\n};
            die qq{  pass in 'allow-infinite => 1' to constructor to disable this warning.\n};
        }
    }

    # else - currently no meaningful way to control 'infinite' languages, this needs to
    # be investigated

    # returns $self, for chaining in __PACKAGE__->run_any
    return $self;
}

# to force a reset, pass in, C<reset => 1>.; this makes a lot of cool things
sub convert_pregex_to_dfa {
    my ( $self, %opts ) = @_;

    # look for cached DFA
    if ( not $self->{reset} and $self->do_cache ) {
        if ( -e $self->cachefile ) {
            $self->dfa( Storable::retrieve( $self->cachefile ) );
            return $self->dfa;
        }
    }

    if ( not $self->dfa or defined $opts{reset} ) {
        $self->dfa( $self->pregex->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks );

        # save to cache
        if ( $self->do_cache ) {
            Storable::store( $self->dfa, $self->cachefile );
        }
    }
    return $self->dfa;
}

# Acyclic String Iterator
#   force a reset, pass in, C<reset => 1>.
sub next {
    my ( $self, %opts ) = @_;

    die qq{(fatal) Use 'inext' instead of 'next' for infinite languages.\n} if $self->dfa->is_infinite;

    if ( not defined $self->{_acyclical_iterator} or $opts{reset} ) {
        $self->{_acyclical_iterator} = $self->dfa->init_acyclic_iterator(q{ });
    }

    $self->{plan} = $self->{_acyclical_iterator}->();

    return $self->{plan};
}

# accepts the same parameters as a constructor, used to re-initialize
# the current reference
sub plan_nein {
    my $pkg  = shift;
    my $self = __PACKAGE__->new(@_);

    # also returns $self for convenience
    return $self;
}

# wrapper that combines C<init_plan> and C<run_once> to present an idiom,
#    my $final_scope = Sub::Genius->new($preplan)->run_any( scope => { ... });
sub run_any {
    my ( $self, %opts ) = @_;
    $self->init_plan;
    my $final_scope = $self->run_once(%opts);
    return $final_scope;
}

# Runs any single serialization ONCE
# defaults to main::, specify namespace of $sub
#
# * ns      => q{Some::NS}  # specify name space
# * scope   => { }          # specify initial state of pipeline accumulator
# * verbose => 0|1          # output runtime diagnostics
sub run_once {
    my ( $self, %opts ) = @_;

    # initialize scope
    $opts{scope} //= {};

    # appends '::' (no check if '::' is at the end to encourage a standard idiom)
    if ( not defined $opts{ns} ) {
        $opts{ns} = q{main::};
    }
    else {
        $opts{ns} .= q{::};
    }

    # only call interator if $self->{plan} has not yet been set
    $self->next if not $self->plan;

    # check plan is set, just to be sure
    if ( my $preplan = $self->plan ) {
        if ( $opts{verbose} ) {
            print qq{plan: "$preplan" <<<\n\nExecute:\n\n};
        }
        my @seq = split( / /, $preplan );

        # main run loop - run once
        local $@;
        foreach my $sub (@seq) {
            eval sprintf( qq{%s%s(\$opts{scope});}, $opts{ns}, $sub );
            die $@ if $@;    # be nice and die for easier debuggering
        }
    }
    return $opts{scope};
}

#
# D R A G O N S
#            ~~~> *E X P E R I M E N T A L* (not even in POD yet)
#

# Deep (Infinite) String Iterator
#   force a reset, pass in, C<reset => 1>.
#
# To us:
#   my $sq = Sub::Genius=->new(preplan => q{a&b*c}, => 'allow-infinite' => 1);
#   $sq->init_plan;
#
#
sub inext {
    my ( $self, %opts ) = @_;
    local $| = 1;
    $opts{max} //= 5;
    if ( not defined $self->{_deepdft_iterator} or $opts{reset} ) {
        $self->{_deepdft_iterator} = $self->dfa->init_deepdft_iterator( $opts{max}, q{ } );
    }

    $self->{plan} = $self->{_deepdft_iterator}->();

    return $self->{plan};
}

1;

__END__
=head1 THIS MODULE IS I<EXPERIMENTAL>

Until further noted, this module subject to extreme fluxuations in
interfaces and implied approaches. The hardest part about this will be
managing all the cool and bright ideas stemming from it.

=head1 NAME

Sub::Genius - Manage concurrent C<Perl> semantics in the
uniprocess execution model of C<perl>.

=head2 In Other Words

L<Sub::Genius> generates a correctly ordered, sequential series of
subroutine calls from a declarative I<plan> that may be parallel or
concurrent in nature.  This allows a concurrency plan to be I<serialized>
or I<linearized> properly for execution in a uniprocess (or single CPU)
environment.

Sub::Genius introduces all the joys and pains of multi-threaded, shared
memory programming to the uniprocess environment that is C<perl>.

After all, if we're going to I<fake the funk out of coroutines> [4],
let's do it correctly. C<:)>

[6], an exposition of L<sequential consistency> in the I<Chapel> programming
language also provides quite an interesting read. Chapel itself is
interested, as are the other I<high productivity> high performance
computing languages that came out during the first decade of this century
(X10, Fortress, etc).

=head1 SYNOPSIS

    # D E F I N E  T H E  P L A N
    my $preplan = q{( A B )  &   ( C D )      (Z)};
    #                 \ /          \ /         |
    #>>>>>>>>>>>     (L1) <shuff>  (L2) <cat>  L3
     
    # C O N V E R T  T H E  P L A N  T O  D F A 
    my $sq = Sub::Genius->new(preplan => $preplan);

    # I N I T  T H E  P L A N
    $sq->init_plan;
     
    # R U N  T H E  P L A N
    $sq->run_once;
    print qq{\n};
    
    # NOTE: sub declaration order has no bearing on anything
     
    sub A { print qq{A}  } #-\
    sub B { print qq{B}  } #--- Language 1
     
    sub C { print qq{C}  } #-\
    sub D { print qq{D}  } #--- Language 2
     
    sub Z { print qq{\n} } #--- Language 3

The following expecity execution of the defined subroutines are all
valid according to the PRE description above:

    # valid execution order 1
      A(); B(); C(); D(); Z();
    
    # valid execution order 2
      A(); C(); B(); D(); Z();
    
    # valid execution order 3
      A(); C(); D(); B(); Z();
    
    # valid execution order 4
      C(); A(); D(); B(); Z();
    
    # valid execution order 5
      C(); D(); A(); B(); Z();

In the example above, using a PRE to describe the relationship among
subroutine names (these are just multicharacter C<symbols>); we are
expressing the following constraints:

=over 4

=item C<sub A>

I<must> run before C<sub B>

=item C<sub C>

I<must> run before C<sub D>

=item C<sub Z>

is I<always> called last

=back


=head2 Meaningful Subroutine Names

C<FLAT> allows single character symbols to be expressed with out any
decorations;

    my $preplan = q{ s ( A (a b) C & ( D E F ) ) f };  # define plan
    my $sq = Sub::Genius->new(preplan => $preplan);    # convert plan

The I<concatentation> of single symbols is implied, and spaces between
symbols doesn't even matter. The following is equivalent to the PRE above,

    my $preplan = q{s(A(ab)C&(DEF))f};                 # define plan
    my $sq = Sub::Genius->new(preplan => $preplan);    # convert plan

It's important to note immediately after the above example, that the PRE
may contain C<symbols> that are made up of more than one character.

But this is a mess, so we can use longer subroutine names as symbols and
break it up in a more readable way:

    # define plan
    my $preplan = q{
      start
        (
          sub_A
          (
            sub_a
            sub_b
          )
          sub_C
        &
         (
          sub_D
          sub_E
          sub_F
         )
        )
      fin
    };
    # convert plan
    my $sq = Sub::Genius->new(preplan => $preplan);

This is much nicer and starting to look like a more natural expression
of concurrent semantics, and allows the expression of subroutines as
meaningful symbols.

=head2 Inline Comments

A final convenience provided during the preprocessing of PREs (which can
be turned I<off> with C<< preprocess => 0 >> passed to C<new>), is the
support of inline comments and empty lines.

For example,

    # define plan
    my $preplan = q{
      start         # Language 1 (L1) always runs first
        (
          sub_A     # Language 2 (L2) 
          ( 
            sub_a   # L2
            sub_b   # L2
          )
          sub_C     # L2
        &           #<~ shuffle's L2 and L3
         (
          sub_D     # L3
          sub_E     # L3
          sub_F     # L3
         )
        )
      fin           # Language 4 (L4) always runs last
    };
    # convert plan
    my $sq = Sub::Genius->new(preplan => $preplan);

=head1 DESCRIPTION 

L<Sub::Genius> generates a correctly ordered, sequential series of
subroutine calls from a declarative I<plan> that may be parallel or
concurrent in nature.  This allows a concurrency plan to be I<serialized>
or I<linearized> properly for execution in a uniprocess (or single CPU)
environment.

It does this by marrying the ability of L<FLAT> to generate a valid string
based on a I<Parallel Regular Expression> with the concept of that string
I<correctly> describing a I<sequentially consistent> ordering of C<Perl>
subroutine calls. This approach allows one to declare a I<concurrent
execution plan> that contains both I<total> ordering and I<partial>
ordering constraints among subroutine calls.

Totally ordered means, I<subroutine B must follow
subroutine A>.

   my $preplan = q{ A   B };

Partially ordered means, I<subroutine A may lead or lag subroutine B, both
must be executed>.

   my $preplan = q{ A & B };

Using this concept, C<Sub::Genius> can generate a valid sequential ordering
of subroutine calls from a declarative I<plan> that may directly express
I<concurrency>.

=head2 C<perl>'s Uniprocess Memory Model and Its Execution Environment

While the language C<Perl> is not necessarily constrained by a uniprocess
execution model, the runtime provided by C<perl> is. This has necessarily
restricted the expressive semantics that can very easily be extended
to C<DWIM> in a concurrent execution model. The problem is that C<perl>
has been organically grown over the years to run as a single process. It
is not immediately obvious to many, even seasoned Perl programmers, why
after all of these years does C<perl> not have I<real> threads or admit
I<real> concurrency and semantics. Accepting the truth of the uniprocess
model makes it clear and brings to it a lot of freedom. This module is
meant to facilitate shared memory, multi-process reasoning to C<perl>'s
fixed uniprocess reality.

The uniprocess model ease of reasoning, particularly in the case of
shared memory programming semantics and consistency thereof. See [3]
for more background on this.

=head2 Atomics and Barriers

When speaking of concurrent semantics in C<Perl>, the topic of atomic
primatives often comes up, because in a truly multi-process execution
environment, they are very important to coordinating the competitive access
of resources such as files and shared memory. Since this execution model
necessarily serializes parallel semantics in a C<sequentially consistent>
way, there is no need for any of these things. Singular lines of execution
need no coordination because there is no competition for any resource
(e.g., a file, memory, network port, etc).


=head2 The Expressive I<Power> of Regular Languages

This module is firmly grounded on the power afforded in expressiveness by
using Regular Language properties to express concurrency. Expansion into
more I<powerful> languages such as I<context sensitive> or I<context free>
is not part of the goal. For anyone interested in this topic, it's a relevant to
consider that since symbols in the PRE are mapped to subroutine names; it
does add computational power when a subroutine is given a C<state> variable,
effectively turning them into I<coroutines>. Memory is power; it doesn't
provide unlimited power, but it is the thing that makes Context Sensitive
Languages more power than Regular Languages, etc.

Given the paragraph above, C<Sub::Genius> may also be described as a way to
explore more or more valid execution orderings which have been derived from
a graph that contains all valid orderings. This graph (the DFA) described
precisely by the PRE.

=head2 Use of Well Known Regular Language Properties

C<Sub::Genius> uses C<FLAT>'s ability to tranform a Regular Expression,
of the Regular Language variety (not a C<Perl> regex!) into a Deterministic
Finite Automata (DFA); once this has been achieved, the DFA is minimized and
depth-first enumeration of the valid "strings" accepted by the original
Regular Expression may be considered I<sequentially consistent>. The
I<parallel> semantics of the Regular Expression are achieved by the
addition of the C<shuffle> of two or more Regular Languages. The result
is also a Regular Language.

From [1],

    A shuffle w of u and v can be loosely defined as a word that is obtained
    by first decomposing u and v into individual pieces, and then combining
    (by concatenation) the pieces to form w, in a way that the order of
    the pieces in each of u and v is preserved.

This means that it preserves the total ordering required by regular
languages I<u> and I<v>, but admits the partial ordering - or shuffling - of
the languages of both. This ultimately means that a valid string resulting
from this combination is necessarily I<sequentially consistent>. Which,
from [2],

    ... the result of any execution is the same as if the operations of
    all the processors were executed in some sequential order, and the
    operations of each individual processor appear in this sequence in
    the order specified by its program.

And it is the C<shuffle> operator that provides the I<concurrent> semantics
to be expressed rather I<naturally>, and in a way the human mind can understand.
This, above all, is absolultely I<critical> for bridging the gap between the
concurrent semantics people clamor for in I<Perl> and the inherent uniprocess
environment presented in the C<perl> C<runtime>.

=head2 Regular Language Operators

The following operator are available via C<FLAT>:

=over 4

=item I<concatentation>: C<L1 L2>

there is no character for this, it is implied when two symbols are directly
next to one another. E.g., C<a b c d>, which can also be expressed as
C<abcd> or even C<[a][b][c][d]>.
    
=item examples,

      my $preplan = q{  a        b        c   };       # single char symbol
      my $preplan = q{symbol1 symbol2 symbol3 };       # multi-char symbol

=item C<|> - I<union>: C<L1 | L2>

If it looks like an C<or>, that is because it is. E.g., C<a|b|c|d> means
a valid string is, C<'a' or 'b' or 'c' or 'd'>. An I<or> is a union. In
Regular Languages, it combines the valid set of strings from each I<or>'d
language together. So the resulting language accepts all strings from I<L1>
and all strings from I<L2>.

=item examples,

      my $preplan = q{  a     |    b    |    c   };    # single char symbol
      my $preplan = q{symbol1 | symbol2 | symbol3};    # multi-car symbol

=item C<&> - I<shuffle>: C<L1 & L2>

It is the addition of this operator, which is I<closed> under Regular
Languages, that allows concurrency to be expressed. It is also generates
a I<Parallel Finite Automata>, which is an I<e-NFA> with an additional
special transition, represented by L<lambda>. It's still closed under RLs,
it's just a way to express a constraint on the NFA that preserves the
total and partial ordering among shuffled languages. It is this property
that leads to guaranteeing I<sequential consistency>.

=item B<E.g.>,

      my $preplan = q{   a    &    b    &    c   };    # single char symbol
      my $preplan = q{symbol1 & symbol2 & symbol3};    # multi-car symbol

=item C<*> - I<Kleene Star>: C<L1*>

Creates an I<infinite> language; accepts either nothing, or an infinitely
repeating concatentation of valid strings accepted originally by I<L1>.

L<Sub::Genius> currently will die if one attempts to use this, but it is
supported just fine by C<FLAT>. It's not supported in this module because
it admits an I<infinite> language. That's not to say it's not useful for
towards the aims of this module; but it's not currently understood by
the merely I<sub-genius> module author(s) how to leverage this operator.

=item B<E.g.>,

      my $preplan = q{    a     &     b*     &   c};  # single char symbol
      my $preplan = q{symbol1 & symbol2* & symbol3};  # multi-car symbol

B<Note>: the above PRE is not supported in L<Sub::Genius>, but may be in
the future.  One may tell C<Sub::Genius> to not C<die> when an infinite
language is detected by passing the C<infinite> flag in the constructor; but
currently the behavior exhibited by this module is considered I<undefined>:

=item B<E.g.>,

      # single char symbol
      my $preplan = q{    a     &     b*     &   c      };
      
      # without 'allow-infinite'=>1, C<new> will fail here
      my $sq = Sub::Genius->new(preplan => $preplan, 'allow-infinite' => 1);

=back

=head2 Precedence Using Parentheses

C<(>, C<)>

Parenthesis are supported as a way to group constituent I<languages>,
provide nexting, and exlicitly express precendence. Many examples in this
document use parenthesis liberally for clarity.

      my $preplan = q{ s ( A (a b) C & ( D E F ) ) f };

For example, the following I<preplan> takes advantage of parentheses
effectively to isolate six (6) distinct Regular Languages (C<init>, L1-4,
C<fin>) and declare their total and partial ordering constraints that
must be obeyed when serialized. The example is also nicely illustrative
of the making a I<plan> more readable using comments (not to suggest an
I<idiom> :)).

    # define plan
    my $preplan = q{
      ##########################################################
      # Plan Summary:                                          #
      #  'init' is called first, then 4 out of 8 subroutines   #
      #   are called based on the union ('|', "or") of each    #
      #   sub Regular Language. 'fin' is always called last    #
      ##########################################################
    
      init # always first
      (
        (alpha   | charlie) &   # L1  - 'alpha'   or 'charlie'
        (whiskey | delta)   &   # L2  - 'whiskey' or 'delta'
        (bravo   | tango)   &   # L3  - 'bravo'   or 'tango'
        (foxtrot | zulu)        # L4  - 'foxtrot' or 'zulu'
        # note: no '&'    ^^^^^ since it's last in the chain
      )
      fin  # always last
    };

=head1 RUNTIME METHODS

A minimal set of methods is provided, more so to not suggest the right
way to use this module.

=over 4

=item C<new>

B<Required parameter:>

C<< preplan => $preplan >>

Constructor, requires a single scalar string argument that is a valid
PRE accepted by L<FLAT>.

    my $preplan = q{
      start
        (
          subA
          (
            subB_a subB_b
          )
          subC
        &
          subD subE subF
        )
      finish
    };

    my $sq = Sub::Genius->new(preplan => $preplan);

B<Optional pramameter:>

=over 4

=item C<< cachedir => $dir >>

Sets default cache directory, which by default is C<$(pwd)/_Sub::Genius>.

If set to C<undef>, caching is disabled.

=item C<< preprocess => undef|0 >>

Disables the current preprocessing, which strips comments and adds brackets
to all I<words> in the PRE.

=item C<< q{allow-infinite} => 1 >>

Default is C<undef> (I<off>).

Note: due to the need to explore the advantages of supporting I<infinite>
languages, i.e., PREs that contain a C<Kleene> star; C<init_plan> will
C<die> after it compiles the PRE into a min DFA. It checks this using the
C<FLAT::DFA::is_finite> subroutine, which simply checks for the presence
of cycles. Once this is understood more clearly, this restriction may be
lifted. This module is all about correctness, and only finite languages
are being considered at this time.

The reference, if captured by a scalar, can be wholly reset using the same
parameters as C<new> but calling the C<plan_nein> methods. It's a minor
convenience, but one all the same.

=back

=item C<cachedir>

Accessor for obtaining the value of the cache directory, either the default
value or as set via C<new>.

=item C<checksum>

Accessor for obtaining the MD5 checksum of the PRE, specified by using the
C<preplan> parameter via C<new>.

=item C<cachefile>

Acessor for getting the full path of the cache file associated with the PRE;
this file may or may not exist.

=item C<init_plan>

This takes the PRE provided in the C<new> constructure, and runs through
the conversion process provded by L<FLAT> to an equivalent mininimzed
DFA. It's this DFA that is then used to generate the (currently) finite
set of strings, or I<plans> that are acceptible for the algorithm or
steps being implemented.

    my $preplan = q{
      start
        (
          subA
          (
            subB_a subB_b
          )
          subC
        &
          subD subE subF
        )
      finish
    };
    
    my $sq = Sub::Genius->new(preplan => $preplan);
    
    $sq->init_plan;

B<Note:> I<Caching>

It is during this call that the DFA associated with the I<preplan> PRE is
I<compiled> into a DFA. That also means, this is where cached DFAs are
read in; or if not yet cached, are saved after the process to convert the
PRE to a DFA.

As is mentioned several times, caching may be disabled by passing the parameter,
C<< cachedir => undef >> in the C<new> constructor.

=item C<run_once>

Returns C<scope> as affected by the assorted subroutines.

Accepts two parameters, both are optional:

=over 4

=item ns => q{My::Sequentially::Consistent::Methods}

Defaults to C<main::>, allows one to specify a namespace that points to a library
of subroutines that are specially crafted to run in a I<sequentialized> environment.
Usually, this points to some sort of willful obliviousness, but might prove to be
useful nonetheless.

=item scope => {}

Allows one to initiate the execution scoped memory, and may be used to manage
a data flow pipeline. Useful and consistent only in the context of a single
plan execution. If not provided, C<scope> is initialized as an empty anonymous
hash reference:

    my $final_scope = $sq->run_once( scope   => {}, verbose => undef, );

=item verbose => 1|0

Default is falsy, or I<off>. When enabled, outputs arguably useless diagnostic
information.

=back

Runs the execution plan once, returns whatever the last subroutine executed
returns:

    my $preplan = join(q{&},(a..z));
    my $sq  = Sub::Genius->new(preplan => $preplan);
    $preplan   = $sq->init_plan;
    my $final_scope = $sq->run_once;

=item C<next>

C<run_once> calls C<next> on C<$self> if it has not been run explicitly
after C<init_plan>, but it will continue to call it if C<run_once> is
run I<again>. This means that the C<preplan> will remain in place until
C<next> is called once again.

An example of iterating over all valid strings in a loop follows:

    while (my $preplan = $sq->next) {
      print qq{Plan: $preplan\n};
      $sq->run_once;
    }

Once the interator has generated I<all> valid strings, the loop above
concludes.

Note, in the above example, the concept of I<pipelining> is violated
since the loop is running each plan ( with no guaranteed ordering ) in
turn. C<$scope> is only meaningful within each execution context. Dealing
with multiple returned final scopes is not part of this module, but can
be captured during each iteration for future processessing:

    my @all_final_scopes = ();
    while (my $preplan = $sq->next_plan()) {
      print qq{Plan: $preplan\n};
      my $final_scope = $sq->run_once;
      push @all_final_scopes, { $preplan => $final_scope };
    }
    # now do something with all the final scopes collected
    # by @all_final_scopes

There are also no deterministic guarantees of the ordering of valid
strings (i.e., sequentially consistent execution plans).

L<FLAT> provides some utility methods to pump FAs for valid strings;
effectively, its the enumeration of paths that exist from an initial
state to a final state. There is nothing magical here. The underlying
method used to do this actually creates an interator.

When C<next> is called the first time, an interator is created, and the
first string is returned. There is currently no way to specify which
string (or C<plan>) is returned first, which is why it is important that
the concurrent semantics declared in the PRE are done in such a way that
any valid string presented is considered to be sequentially consistent
with the memory model used in the implementation of the subroutines.

Perl provides the access to these memories by use of their lexical variable
scoping (C<my>, C<local>) and the convenient way it allows one to make a
subroutine maintain persistent memory (i.e., make it a coroutine) using
the C<state> keyword. See more about C<PERL's UNIPROCESS MEMORY MODEL
AND ITS EXECUTION ENVIRONMENT> in the section above of the same name.

At this time C<Sub::Genius> only permits I<finite> languages by default,
therefore there is always a finite list of accepted strings. The list
may be long, but it's finite.

As an example, the following admits a large number of orderings in a realtively
compact DFA, in fact there are 26! (factorial) such valid orderings:

    my $preplan = join(q{&},(a..z));
    my $final_scope = Sub::Genius->new(preplan => $preplan)->run_once;

Thus, the following will take long time to complete; but it will complete:

    my $ans; # global to all subroutines executed
    while ($my $preplan = $sq->next_plan()) {
      $sq->run_once;
    }
    print qq{ans: $ans\n};

Done right, the output after 26! iterations may very well be:

    ans: 42

A formulation of 26 subroutines operating over shared memory in which all
cooperative execution of all 26! orderings reduces to C<42> is left as an
excercise for the reader.

=item C<run_any>

For convenience, this wraps up the steps of C<plan>, C<init_plan>, C<next>,
and C<run_once>. It presents a simple one line interfaces:

    my $preplan = q{
      start
        (
          subA
          (
            subB_a subB_b
          )
          subC
        &
          subD subE subF
        )
      finish
    };
    
    Sub::Genius->new(preplan => $preplan)->run_any();

=item C<plan_nein>

I<DEPRECATED> - this was a not a well thought out idea and will be removed
in the very near term, if it does not remove itself first. C<< >:E >>

Using an existing reference instantiation of C<Sub::Genius>, resets
everything about the instance. It's effectively link calling C<new> on the
instance without having to recapture it.

=back

=head1 PERFORMANCE CONSIDERATIONS

L<FLAT> is very useful for fairly complex semantics, but the number of
FA states grows extremely large as it moves from the non-deterministic
realm to to the deterministic.

What that means in most cases, is that the more non-deterministic the PRE
(e.g., the more C<shuffles> or C<&>'s), the longer it will take for the
final DFA to be created. It would not be hard to overwhelm a system's
memory with a PRE like the one suggested above,

    my $preplan = join(q{&},(a..z));

This suggests all 26 letter combinations of all of the lower case letters
of the alphabet (26! such combinations, as noted above) must be accounted
for in the final minimized DFA, which is really just a large graph.

The algorithms inplemented in L<FLAT> to convert from a PRE to a PFA
(equivalent to a PetriNet) to a NFA to a DFA, and finally to a minimized
DFA are the basic' ones discussed in any basic CS text book on automata,
e.g., [5].

To get around the potential for performance issues related to converting
PREs to DFAs, there are two current approaches. The first and most obvious
one is caching, discussed immediately in the following section. After this,
the idea of I<lazy sequentilization> - or delaying the conversion of a
PRE until the last possible moment - is introduced with a proof of concept
example that works I<now>.

=head1 CACHING 

The practicality of converting the PRE to a DFA suitable for generating
valid execution orders is reached relatively quickly as more C<shuffle>s
are added.  For this reason, C<init_plan> looks for a cache file. If
available, it's loaded saving potentally long start up times.

=head2 How Caching Works in C<Sub::Genius>

Caching of the PRE is done after it has been I<compiled> into a DFA, which
is called most directly via C<init_plan>. Unless the constructor has been
created specifically turning it off via C<cachedir=>undef>, L<Storable>'s
C<store> method is used to save it to the C<cachedir>. Internally, a C<md5>
checksum is generated using L<Digest::MD5>'s C<md5_hex> method on the PRE
after it's been I<preprocessed>. If the constructor is passed the flag
to disable preprocessing, the checksum is generated in consideration of
the PRE as specified using the C<preplan> parameter of C<new>.

The lifecycle of caching, assuming default behavior is:

=over 4

=item 1. constructor used to create instance with C<preplan> specified

=item 2. C<preplan>

is I<preprocessed> to strip comments, blank spaces, and put square braces
around all I<words>

=item 3. a checksum

is generated using the value of post-preprocessed C<preplan> field

=item 4. calling C<init_plan>

first looks for a cached file representing the DFA's checksum; if found
it C<retrieve>s this file and this is the DFA moving forward

=item 5. if no such cached DFA exists

then internally the L<FLAT> enabled process to convert a PRE to a DFA is
invoked; this is the step that has the potential for taking an inordinate
amount of time

=item 6. the DFA is saved

in C<cachedir> with the file name that matches the value of C<checksum>.

=back

=head2 Role of Checksumming and PRE Normalization

The current implementation of the checksumming of PREs is done by
normalizing the provide PRE during the I<preprocess> step. This includes:
stripping comments, adding square backets (C<[]>) around all words
(C<\w>) including single characters, eliminating all new lines, and
finally eliminating all spaces. This effectively creates a minimized PRE
that retains all Regular Expression operators, delimits all symbols by a
circumfix square brace pair, eliminates all spaces, and eliminates all
new lines. With this approach, caching is effective for all PREs that
minimize to the same exact form regardless of any spacing or comments
that might be present.

=head2 Final Notes on Caching

Caching for C<compiled> things, in lieu of better performance for
necessarily complext algorithms, seems an acceptible cheat. Well known
examples of this included L<Inline> (e.g., the C<_Inline> default directory)
and the caching of rendered template by L<Template> Toolkit.

This could be couched as a I<benefit>, but the truth is that it would be
better if caching DFAs was not necessary. In the case for very complex
or I<highly> shuffled PREs, it is necessary to precompile - and maybe
even on much more performant machines than the one the code using them
will run on. It may just be the nature of taming this beast.

This also suggests I<best practices> if this module, or the approach it
purports, ever reaches some degree of interesting. It is reasonable to
imagine the rendering of I<frozen> DFAs (the I<compiled> form of PREs
used to generate valid execution plans) is like a compilation step, just
like building XS modules necessarily requires the compiling of code during
module installation. It could also be, that assuming C<store>'d files are
platform independent, that a repository of these can be mainted somewhere
like in a git repo for distribution. Indeed, there could be entire modules
on CPAN that provide libraries to DFAs that ensure sequential consistency
for a large variety of applications.

Until this is proven in the wild, it's just speculation. For now, it's
sufficient to state that caching is a necessary part of this approach
and may be for some time. The best we can do is provide a convenient
way to handle it, and it's taking a hint from modules like C<Inline>
that we start off on the right footing.

As a final note, caching I<can> be disabled in the constructure,

    my $sq = Sub::Genius->new( preplan => $preplan, cachedir => undef );

=head1 LAZY OR NESTED LINEARIZATION

This concept bears more exploration, but the idea is basically to encapsulate
additional calls to C<Sub::Genious> inside of subroutines contained in higher
level PREs. This kind of thing is done often, a good example is L<Web::Scraper>'s
concept of nested scrapers.

For example, all of the words in the following C<$preplan> simply represent
calls to subroutines, albeit constrained to the orderings implied by the PRE
operators present: 

    my $preplan = q{
      init
      ( subA
          &
          (
            subB
       
            _DO_LAZY_SEQ_   #<~ this subroutine encapsulates another PRE
      
            subC
          )
          &
        subD
      )
      fin
    };
     
    my $sq = Sub::Genius->new(preplan => $preplan)->init_plan;
     
    my $final_scope = $sq->run_any;
     
    sub _DO_LAZY_SEQ_ {
      my $scope = shift;
      my $inner_preplan = q{
        subA
          &
        subB
          &
        subC
          & 
        subD
          &
        subE #<~ new to this PRE!
      };
      return Sub::Genius->new(preplan => $inner_preplan)->run_any;
    }
     
    # new sub required to support the lazily linearized PRE
    sub subE {
      my $scope = shift;
      print qq{Sneaky sneak subE says, "Hi!"\n};
      return $scope;
    }
     
    # ... assume all other subs are defined, we define _DO_LAZY_SEQ_ with
    # its own $preplan;

The above idea does work and benefits from caching as well as the top
level. Future enhancements may provide some builtin I<lazy> enablement
routines. But for now, it suffices to demonstrate that this is a viable
approach.

=head1 DEBUGGING AND TOOLS

C<stubby>

This module installs a tool called L<stubby> into your local C<$PATH>. For
the time being it is located in the C<./bin> directory of the distribution
and on Github. It will help anyone interested in getting an idea of what
programming using this model is like.

See L<stubby> for more information, but it currently allows for both stub
code generation to get one started on using this module; and the ability
to pre-cache (or I<compile>) PREs into the DFA needed to generate valid
execution plans. It's the conversion from a PRE to this DFA that the most
potentially expensive aspect of this approach.

See L<stubby> for more information, but it currently allows for both stub
code generation to get one started on using this module; and the ability
to pre-cache (or I<compile>) PREs into the DFA needed to generate valid
execution plans.

C<fash>

This tool is I<just> a C<bash> script that makes it easier to called L<FLAT>
powered C<perl> one-liners more efficiently.

Using this tool, one may explore the details of the PRE they are wishing
to use. It allows one to also leverage external tools, such as I<graphviz>,
I<JFLAP>[6], and image programs for seeing the underlying automata structures
implied by the PRE being used. I<Debugging> programs written using the
model provided for by L<Sub::Genius> is certainly going to require some time
debugging. C<fash> is just one way to do it.

This is a shell wrapper around L<FLAT> that provides nice things, like
the ability to dump PFAs generated from a PRE in I<graphviz> format. It
can also dump interesting things like the AST resulting from the parsing
of the PRE (done so by C<RecDescent::Parser>).

B<Note>: with C<fash>, multi character symbols must be encased in square backets.
This is because it calls L<FLAT> routines directly.

Example I<dump> of the I<Parallel Finite Automata> that is described by the PRE
in the C<fash> command below, in GraphViz C<dot> format:

    $ fash pfa2gv "[abc]&[def]" | dot -Tpng > my-pfa.png

Then open up C<my-pfa.png> and see a nice image of your pet Finite Automate
(which may I<surprise> you).

To see all of the useful commands one may use to explore the PRE when
determining how to describe the semantics being expressed when using
L<Sub::Genius>.

    $ fash help

=head2 See Also

L<stubby> and L<fash>.

=head1 SEE ALSO

L<Pipeworks>, L<Sub::Pipeline>, L<Process::Pipeline>, L<FLAT>,
L<Graph::PetriNet>

=head2 Good Reads

=over 4

=item * 1. L<https://www.planetmath.org/shuffleoflanguages>

=item * 2. Leslie Lamport, "How to Make a Multiprocessor Computer That Correctly
Executes Multiprocess Programs", IEEE Trans. Comput. C-28,9 (Sept. 1979), 690-691.

=item * 3. L<https://www.hpl.hp.com/techreports/Compaq-DEC/WRL-95-7.pdf>

=item * 4. L<https://troglodyne.net/video/1615853053>

=item * 5. Introduction to Automata Theory, Languages, and Computation; Hopcroft, Motwani,
Ullman. Any year.

=item * 6. L<https://chapel-lang.org/docs/language/spec/memory-consistency-model.html#sequential-consistency-for-data-race-free-programs>

=back

=head1 COPYRIGHT AND LICENSE

Same terms as perl itself.

=head1 AUTHOR

OODLER 577 E<lt>oodler@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I<TEODESIAN> (@cpan) is acknowledged for his support and interest in
this project, in particular his work lifting the veil off of what
passes for I<concurrency> these days; namely, I<most of the "Async"
modules out there are actually fakin' the funk with coroutines.>. See
L<https://troglodyne.net/video/1615853053> for a fun, fresh, and informative
video on the subject.
