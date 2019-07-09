package Scope::Upper;

use 5.006_001;

use strict;
use warnings;

=head1 NAME

Scope::Upper - Act on upper scopes.

=head1 VERSION

Version 0.32

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.32';
}

=head1 SYNOPSIS

L</reap>, L</localize>, L</localize_elem>, L</localize_delete> and L</WORDS> :

    package Scope;

    use Scope::Upper qw<
     reap localize localize_elem localize_delete
     :words
    >;

    sub new {
     my ($class, $name) = @_;

     localize '$tag' => bless({ name => $name }, $class) => UP;

     reap { print Scope->tag->name, ": end\n" } UP;
    }

    # Get the tag stored in the caller namespace
    sub tag {
     my $l   = 0;
     my $pkg = __PACKAGE__;
     $pkg    = caller $l++ while $pkg eq __PACKAGE__;

     no strict 'refs';
     ${$pkg . '::tag'};
    }

    sub name { shift->{name} }

    # Locally capture warnings and reprint them with the name prefixed
    sub catch {
     localize_elem '%SIG', '__WARN__' => sub {
      print Scope->tag->name, ': ', @_;
     } => UP;
    }

    # Locally clear @INC
    sub private {
     for (reverse 0 .. $#INC) {
      # First UP is the for loop, second is the sub boundary
      localize_delete '@INC', $_ => UP UP;
     }
    }

    ...

    package UserLand;

    {
     Scope->new("top");    # initializes $UserLand::tag

     {
      Scope->catch;
      my $one = 1 + undef; # prints "top: Use of uninitialized value..."

      {
       Scope->private;
       eval { require Cwd };
       print $@;           # prints "Can't locate Cwd.pm in @INC
      }                    #         (@INC contains:) at..."

      require Cwd;         # loads Cwd.pm
     }

    }                      # prints "top: done"

L</unwind> and L</want_at> :

    package Try;

    use Scope::Upper qw<unwind want_at :words>;

    sub try (&) {
     my @result = shift->();
     my $cx = SUB UP; # Point to the sub above this one
     unwind +(want_at($cx) ? @result : scalar @result) => $cx;
    }

    ...

    sub zap {
     try {
      my @things = qw<a b c>;
      return @things; # returns to try() and then outside zap()
      # not reached
     };
     # not reached
    }

    my @stuff = zap(); # @stuff contains qw<a b c>
    my $stuff = zap(); # $stuff contains 3

L</uplevel> :

    package Uplevel;

    use Scope::Upper qw<uplevel CALLER>;

    sub target {
     faker(@_);
    }

    sub faker {
     uplevel {
      my $sub = (caller 0)[3];
      print "$_[0] from $sub()";
     } @_ => CALLER(1);
    }

    target('hello'); # "hello from Uplevel::target()"

L</uid> and L</validate_uid> :

    use Scope::Upper qw<uid validate_uid>;

    my $uid;

    {
     $uid = uid();
     {
      if ($uid eq uid(UP)) { # yes
       ...
      }
      if (validate_uid($uid)) { # yes
       ...
      }
     }
    }

    if (validate_uid($uid)) { # no
     ...
    }

=head1 DESCRIPTION

This module lets you defer actions I<at run-time> that will take place when the control flow returns into an upper scope.
Currently, you can:

=over 4

=item *

hook an upper scope end with L</reap> ;

=item *

localize variables, array/hash values or deletions of elements in higher contexts with respectively L</localize>, L</localize_elem> and L</localize_delete> ;

=item *

return values immediately to an upper level with L</unwind>, L</yield> and L</leave> ;

=item *

gather information about an upper context with L</want_at> and L</context_info> ;

=item *

execute a subroutine in the setting of an upper subroutine stack frame with L</uplevel> ;

=item *

uniquely identify contexts with L</uid> and L</validate_uid>.

=back

=head1 FUNCTIONS

In all those functions, C<$context> refers to the target scope.

You have to use one or a combination of L</WORDS> to build the C<$context> passed to these functions.
This is needed in order to ensure that the module still works when your program is ran in the debugger.
The only thing you can assume is that it is an I<absolute> indicator of the frame, which means that you can safely store it at some point and use it when needed, and it will still denote the original scope.

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head2 C<reap>

    reap { ... };
    reap { ... } $context;
    &reap($callback, $context);

Adds a destructor that calls C<$callback> (in void context) when the upper scope represented by C<$context> ends.

=head2 C<localize>

    localize $what, $value;
    localize $what, $value, $context;

Introduces a C<local> delayed to the time of first return into the upper scope denoted by C<$context>.
C<$what> can be :

=over 4

=item *

A glob, in which case C<$value> can either be a glob or a reference.
L</localize> follows then the same syntax as C<local *x = $value>.
For example, if C<$value> is a scalar reference, then the C<SCALAR> slot of the glob will be set to C<$$value> - just like C<local *x = \1> sets C<$x> to C<1>.

=item *

A string beginning with a sigil, representing the symbol to localize and to assign to.
If the sigil is C<'$'>, L</localize> follows the same syntax as C<local $x = $value>, i.e. C<$value> isn't dereferenced.
For example,

    localize '$x', \'foo' => HERE;

will set C<$x> to a reference to the string C<'foo'>.
Other sigils (C<'@'>, C<'%'>, C<'&'> and C<'*'>) require C<$value> to be a reference of the corresponding type.

When the symbol is given by a string, it is resolved when the actual localization takes place and not when L</localize> is called.
Thus, if the symbol name is not qualified, it will refer to the variable in the package where the localization actually takes place and not in the one where the L</localize> call was compiled.
For example,

    {
     package Scope;
     sub new { localize '$tag', $_[0] => UP }
    }

    {
     package Tool;
     {
      Scope->new;
      ...
     }
    }

will localize C<$Tool::tag> and not C<$Scope::tag>.
If you want the other behaviour, you just have to specify C<$what> as a glob or a qualified name.

Note that if C<$what> is a string denoting a variable that wasn't declared beforehand, the relevant slot will be vivified as needed and won't be deleted from the glob when the localization ends.
This situation never arises with C<local> because it only compiles when the localized variable is already declared.
Although I believe it shouldn't be a problem as glob slots definedness is pretty much an implementation detail, this behaviour may change in the future if proved harmful.

=back

=head2 C<localize_elem>

    localize_elem $what, $key, $value;
    localize_elem $what, $key, $value, $context;

Introduces a C<local $what[$key] = $value> or C<local $what{$key} = $value> delayed to the time of first return into the upper scope denoted by C<$context>.
Unlike L</localize>, C<$what> must be a string and the type of localization is inferred from its sigil.
The two only valid types are array and hash ; for anything besides those, L</localize_elem> will throw an exception.
C<$key> is either an array index or a hash key, depending of which kind of variable you localize.

If C<$what> is a string pointing to an undeclared variable, the variable will be vivified as soon as the localization occurs and emptied when it ends, although it will still exist in its glob.

=head2 C<localize_delete>

    localize_delete $what, $key;
    localize_delete $what, $key, $context;

Introduces the deletion of a variable or an array/hash element delayed to the time of first return into the upper scope denoted by C<$context>.
C<$what> can be:

=over 4

=item *

A glob, in which case C<$key> is ignored and the call is equivalent to C<local *x>.

=item *

A string beginning with C<'@'> or C<'%'>, for which the call is equivalent to respectively C<local $a[$key]; delete $a[$key]> and C<local $h{$key}; delete $h{$key}>.

=item *

A string beginning with C<'&'>, which more or less does C<undef &func> in the upper scope.
It's actually more powerful, as C<&func> won't even C<exists> anymore.
C<$key> is ignored.

=back

=head2 C<unwind>

    unwind;
    unwind @values, $context;

Returns C<@values> I<from> the subroutine, eval or format context pointed by or just above C<$context>, and immediately restarts the program flow at this point - thus effectively returning C<@values> to an upper scope.
If C<@values> is empty, then the C<$context> parameter is optional and defaults to the current context (making the call equivalent to a bare C<return;>) ; otherwise it is mandatory.

The upper context isn't coerced onto C<@values>, which is hence always evaluated in list context.
This means that

    my $num = sub {
     my @a = ('a' .. 'z');
     unwind @a => HERE;
     # not reached
    }->();

will set C<$num> to C<'z'>.
You can use L</want_at> to handle these cases.

=head2 C<yield>

    yield;
    yield @values, $context;

Returns C<@values> I<from> the context pointed by or just above C<$context>, and immediately restarts the program flow at this point.
If C<@values> is empty, then the C<$context> parameter is optional and defaults to the current context ; otherwise it is mandatory.

L</yield> differs from L</unwind> in that it can target I<any> upper scope (besides a C<s///e> substitution context) and not necessarily a sub, an eval or a format.
Hence you can use it to return values from a C<do> or a C<map> block :

    my $now = do {
     local $@;
     eval { require Time::HiRes } or yield time() => HERE;
     Time::HiRes::time();
    };

    my @uniq = map {
     yield if $seen{$_}++; # returns the empty list from the block
     ...
    } @things;

Like for L</unwind>, the upper context isn't coerced onto C<@values>.
You can use the fifth value returned by L</context_info> to handle context coercion.

=head2 C<leave>

    leave;
    leave @values;

Immediately returns C<@values> from the current block, whatever it may be (besides a C<s///e> substitution context).
C<leave> is actually a synonym for C<yield HERE>, while C<leave @values> is a synonym for C<yield @values, HERE>.

Like for L</yield>, you can use the fifth value returned by L</context_info> to handle context coercion.

=head2 C<want_at>

    my $want = want_at;
    my $want = want_at $context;

Like L<perlfunc/wantarray>, but for the subroutine, eval or format context located at or just above C<$context>.

It can be used to revise the example showed in L</unwind> :

    my $num = sub {
     my @a = ('a' .. 'z');
     unwind +(want_at(HERE) ? @a : scalar @a) => HERE;
     # not reached
    }->();

will rightfully set C<$num> to C<26>.

=head2 C<context_info>

    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask,
        $hinthash) = context_info $context;

Gives information about the context denoted by C<$context>, akin to what L<perlfunc/caller> provides but not limited only to subroutine, eval and format contexts.
When C<$context> is omitted, it defaults to the current context.

The returned values are, in order :

=over 4

=item *

I<(index 0)> : the namespace in use when the context was created ;

=item *

I<(index 1)> : the name of the file at the point where the context was created ;

=item *

I<(index 2)> : the line number at the point where the context was created ;

=item *

I<(index 3)> : the name of the subroutine called for this context, or C<undef> if this is not a subroutine context ;

=item *

I<(index 4)> : a boolean indicating whether a new instance of C<@_> was set up for this context, or C<undef> if this is not a subroutine context ;

=item *

I<(index 5)> : the context (in the sense of L<perlfunc/wantarray>) in which the context (in our sense) is executed ;

=item *

I<(index 6)> : the contents of the string being compiled for this context, or C<undef> if this is not an eval context ;

=item *

I<(index 7)> : a boolean indicating whether this eval context was created by C<require>, or C<undef> if this is not an eval context ;

=item *

I<(index 8)> : the value of the lexical hints in use when the context was created ;

=item *

I<(index 9)> : a bit string representing the warnings in use when the context was created ;

=item *

I<(index 10)> : a reference to the lexical hints hash in use when the context was created (only on perl 5.10 or greater).

=back

=head2 C<uplevel>

    my @ret = uplevel { ...; return @ret };
    my @ret = uplevel { my @args = @_; ...; return @ret } @args, $context;
    my @ret = &uplevel($callback, @args, $context);

Executes the code reference C<$callback> with arguments C<@args> as if it were located at the subroutine stack frame pointed by C<$context>, effectively fooling C<caller> and C<die> into believing that the call actually happened higher in the stack.
The code is executed in the context of the C<uplevel> call, and what it returns is returned as-is by C<uplevel>.

    sub target {
     faker(@_);
    }

    sub faker {
     uplevel {
      map { 1 / $_ } @_;
     } @_ => CALLER(1);
    }

    my @inverses = target(1, 2, 4); # @inverses contains (0, 0.5, 0.25)
    my $count    = target(1, 2, 4); # $count is 3

Note that if C<@args> is empty, then the C<$context> parameter is optional and defaults to the current context ; otherwise it is mandatory.

L<Sub::Uplevel> also implements a pure-Perl version of C<uplevel>.
Both are identical, with the following caveats :

=over 4

=item *

The L<Sub::Uplevel> implementation of C<uplevel> may execute a code reference in the context of B<any> upper stack frame.
The L<Scope::Upper> version can only uplevel to a B<subroutine> stack frame, and will croak if you try to target an C<eval> or a format.

=item *

Exceptions thrown from the code called by this version of C<uplevel> will not be caught by C<eval> blocks between the target frame and the uplevel call, while they will for L<Sub::Uplevel>'s version.
This means that :

    eval {
     sub {
      local $@;
      eval {
       sub {
        uplevel { die 'wut' } CALLER(2); # for Scope::Upper
        # uplevel(3, sub { die 'wut' })  # for Sub::Uplevel
       }->();
      };
      print "inner block: $@";
      $@ and exit;
     }->();
    };
    print "outer block: $@";

will print "inner block: wut..." with L<Sub::Uplevel> and "outer block: wut..." with L<Scope::Upper>.

=item *

L<Sub::Uplevel> globally overrides the Perl keyword C<caller>, while L<Scope::Upper> does not.

=back

A simple wrapper lets you mimic the interface of L<Sub::Uplevel/uplevel> :

    use Scope::Upper;

    sub uplevel {
     my $frame = shift;
     my $code  = shift;
     my $cxt   = Scope::Upper::CALLER($frame);
     &Scope::Upper::uplevel($code => @_ => $cxt);
    }

Albeit the three exceptions listed above, it passes all the tests of L<Sub::Uplevel>.

=head2 C<uid>

    my $uid = uid;
    my $uid = uid $context;

Returns an unique identifier (UID) for the context (or dynamic scope) pointed by C<$context>, or for the current context if C<$context> is omitted.
This UID will only be valid for the life time of the context it represents, and another UID will be generated next time the same scope is executed.

    my $uid;

    {
     $uid = uid;
     if ($uid eq uid()) { # yes, this is the same context
      ...
     }
     {
      if ($uid eq uid()) { # no, we are one scope below
       ...
      }
      if ($uid eq uid(UP)) { # yes, UP points to the same scope as $uid
       ...
      }
     }
    }

    # $uid is now invalid

    {
     if ($uid eq uid()) { # no, this is another block
      ...
     }
    }

For example, each loop iteration gets its own UID :

    my %uids;

    for (1 .. 5) {
     my $uid = uid;
     $uids{$uid} = $_;
    }

    # %uids has 5 entries

The UIDs are not guaranteed to be numbers, so you must use the C<eq> operator to compare them.

To check whether a given UID is valid, you can use the L</validate_uid> function.

=head2 C<validate_uid>

    my $is_valid = validate_uid $uid;

Returns true if and only if C<$uid> is the UID of a currently valid context (that is, it designates a scope that is higher than the current one in the call stack).

    my $uid;

    {
     $uid = uid();
     if (validate_uid($uid)) { # yes
      ...
     }
     {
      if (validate_uid($uid)) { # yes
       ...
      }
     }
    }

    if (validate_uid($uid)) { # no
     ...
    }

=head1 CONSTANTS

=head2 C<SU_THREADSAFE>

True iff the module could have been built when thread-safety features.

=head1 WORDS

=head2 Constants

=head3 C<TOP>

    my $top_context = TOP;

Returns the context that currently represents the highest scope.

=head3 C<HERE>

    my $current_context = HERE;

The context of the current scope.

=head2 Getting a context from a context

For any of those functions, C<$from> is expected to be a context.
When omitted, it defaults to the current context.

=head3 C<UP>

    my $upper_context = UP;
    my $upper_context = UP $from;

The context of the scope just above C<$from>.
If C<$from> points to the top-level scope in the current stack, then a warning is emitted and C<$from> is returned (see L</DIAGNOSTICS> for details).

=head3 C<SUB>

    my $sub_context = SUB;
    my $sub_context = SUB $from;

The context of the closest subroutine above C<$from>.
If C<$from> already designates a subroutine context, then it is returned as-is ; hence C<SUB SUB == SUB>.
If no subroutine context is present in the call stack, then a warning is emitted and the current context is returned (see L</DIAGNOSTICS> for details).

=head3 C<EVAL>

    my $eval_context = EVAL;
    my $eval_context = EVAL $from;

The context of the closest eval above C<$from>.
If C<$from> already designates an eval context, then it is returned as-is ; hence C<EVAL EVAL == EVAL>.
If no eval context is present in the call stack, then a warning is emitted and the current context is returned (see L</DIAGNOSTICS> for details).

=head2 Getting a context from a level

Here, C<$level> should denote a number of scopes above the current one.
When omitted, it defaults to C<0> and those functions return the same context as L</HERE>.

=head3 C<SCOPE>

    my $context = SCOPE;
    my $context = SCOPE $level;

The C<$level>-th upper context, regardless of its type.
If C<$level> points above the top-level scope in the current stack, then a warning is emitted and the top-level context is returned (see L</DIAGNOSTICS> for details).

=head3 C<CALLER>

    my $context = CALLER;
    my $context = CALLER $level;

The context of the C<$level>-th upper subroutine/eval/format.
It kind of corresponds to the context represented by C<caller $level>, but while e.g. C<caller 0> refers to the caller context, C<CALLER 0> will refer to the top scope in the current context.
If C<$level> points above the top-level scope in the current stack, then a warning is emitted and the top-level context is returned (see L</DIAGNOSTICS> for details).

=head2 Examples

Where L</reap> fires depending on the C<$cxt> :

    sub {
     eval {
      sub {
       {
        reap \&cleanup => $cxt;
        ...
       }     # $cxt = SCOPE(0) = HERE
       ...
      }->(); # $cxt = SCOPE(1) = UP = SUB = CALLER(0)
      ...
     };      # $cxt = SCOPE(2) = UP UP =  UP SUB = EVAL = CALLER(1)
     ...
    }->();   # $cxt = SCOPE(3) = SUB UP SUB = SUB EVAL = CALLER(2)
    ...

Where L</localize>, L</localize_elem> and L</localize_delete> act depending on the C<$cxt> :

    sub {
     eval {
      sub {
       {
        localize '$x' => 1 => $cxt;
        # $cxt = SCOPE(0) = HERE
        ...
       }
       # $cxt = SCOPE(1) = UP = SUB = CALLER(0)
       ...
      }->();
      # $cxt = SCOPE(2) = UP UP = UP SUB = EVAL = CALLER(1)
      ...
     };
     # $cxt = SCOPE(3) = SUB UP SUB = SUB EVAL = CALLER(2)
     ...
    }->();
    # $cxt = SCOPE(4), UP SUB UP SUB = UP SUB EVAL = UP CALLER(2) = TOP
    ...

Where L</unwind>, L</yield>, L</want_at>, L</context_info> and L</uplevel> point to depending on the C<$cxt>:

    sub {
     eval {
      sub {
       {
        unwind @things => $cxt;   # or yield @things => $cxt
                                  # or uplevel { ... } $cxt
        ...
       }
       ...
      }->(); # $cxt = SCOPE(0) = SCOPE(1) = HERE = UP = SUB = CALLER(0)
      ...
     };      # $cxt = SCOPE(2) = UP UP = UP SUB = EVAL = CALLER(1) (*)
     ...
    }->();   # $cxt = SCOPE(3) = SUB UP SUB = SUB EVAL = CALLER(2)
    ...

    # (*) Note that uplevel() will croak if you pass that scope frame,
    #     because it cannot target eval scopes.

=head1 DIAGNOSTICS

=head2 C<Cannot target a scope outside of the current stack>

This warning is emitted when L</UP>, L</SCOPE> or L</CALLER> end up pointing to a context that is above the top-level context of the current stack.
It indicates that you tried to go higher than the main scope, or to point across a C<DESTROY> method, a signal handler, an overloaded or tied method call, a C<require> statement or a C<sort> callback.
In this case, the resulting context is the highest reachable one.

=head2 C<No targetable %s scope in the current stack>

This warning is emitted when you ask for an L</EVAL> or L</SUB> context and no such scope can be found in the call stack.
The resulting context is the current one.

=head1 EXPORT

The functions L</reap>, L</localize>, L</localize_elem>, L</localize_delete>,  L</unwind>, L</yield>, L</leave>, L</want_at>, L</context_info> and L</uplevel> are only exported on request, either individually or by the tags C<':funcs'> and C<':all'>.

The constant L</SU_THREADSAFE> is also only exported on request, individually or by the tags C<':consts'> and C<':all'>.

Same goes for the words L</TOP>, L</HERE>, L</UP>, L</SUB>, L</EVAL>, L</SCOPE> and L</CALLER> that are only exported on request, individually or by the tags C<':words'> and C<':all'>.

=cut

use base qw<Exporter>;

our @EXPORT      = ();
our %EXPORT_TAGS = (
 funcs  => [ qw<
  reap
  localize localize_elem localize_delete
  unwind yield leave
  want_at context_info
  uplevel
  uid validate_uid
 > ],
 words  => [ qw<TOP HERE UP SUB EVAL SCOPE CALLER> ],
 consts => [ qw<SU_THREADSAFE> ],
);
our @EXPORT_OK   = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 CAVEATS

It is not possible to act upon a scope that belongs to another perl 'stack', i.e. to target a scope across a C<DESTROY> method, a signal handler, an overloaded or tied method call, a C<require> statement or a C<sort> callback.

Be careful that local variables are restored in the reverse order in which they were localized.
Consider those examples:

    local $x = 0;
    {
     reap sub { print $x } => HERE;
     local $x = 1;
     ...
    }
    # prints '0'
    ...
    {
     local $x = 1;
     reap sub { $x = 2 } => HERE;
     ...
    }
    # $x is 0

The first case is "solved" by moving the C<local> before the C<reap>, and the second by using L</localize> instead of L</reap>.

The effects of L</reap>, L</localize> and L</localize_elem> can't cross C<BEGIN> blocks, hence calling those functions in C<import> is deemed to be useless.
This is an hopeless case because C<BEGIN> blocks are executed once while localizing constructs should do their job at each run.
However, it's possible to hook the end of the current scope compilation with L<B::Hooks::EndOfScope>.

Some rare oddities may still happen when running inside the debugger.
It may help to use a perl higher than 5.8.9 or 5.10.0, as they contain some context-related fixes.

Calling C<goto> to replace an L</uplevel>'d code frame does not work :

=over 4

=item *

for a C<perl> older than the 5.8 series ;

=item *

for a C<DEBUGGING> C<perl> run with debugging flags set (as in C<perl -D ...>) ;

=item *

when the runloop callback is replaced by another module.

=back

In those three cases, L</uplevel> will look for a C<goto &sub> statement in its callback and, if there is one, throw an exception before executing the code.

Moreover, in order to handle C<goto> statements properly, L</uplevel> currently has to suffer a run-time overhead proportional to the size of the callback in every case (with a small ratio), and proportional to the size of B<all> the code executed as the result of the L</uplevel> call (including subroutine calls inside the callback) when a C<goto> statement is found in the L</uplevel> callback.
Despite this shortcoming, this XS version of L</uplevel> should still run way faster than the pure-Perl version from L<Sub::Uplevel>.

Starting from C<perl> 5.19.4, it is unfortunately no longer possible to reliably throw exceptions from L</uplevel>'d code while the debugger is in use.
This may be solved in a future version depending on how the core evolves.

=head1 DEPENDENCIES

L<perl> 5.6.1.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<XSLoader> (core since perl 5.6.0).

=head1 SEE ALSO

L<perlfunc/local>, L<perlsub/"Temporary Values via local()">.

L<Alias>, L<Hook::Scope>, L<Scope::Guard>, L<Guard>.

L<Sub::Uplevel>.

L<Continuation::Escape> is a thin wrapper around L<Scope::Upper> that gives you a continuation passing style interface to L</unwind>.
It's easier to use, but it requires you to have control over the scope where you want to return.

L<Scope::Escape>.

=head1 AUTHOR

Vincent Pit C<< <vpit at cpan.org> >>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-scope-upper at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scope-Upper>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scope::Upper

=head1 ACKNOWLEDGEMENTS

Inspired by Ricardo Signes.

The reimplementation of a large part of this module for perl 5.24 was provided by David Mitchell.
His work was sponsored by the Perl 5 Core Maintenance Grant from The Perl Foundation.

Thanks to Shawn M. Moore for motivation.

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Scope::Upper
