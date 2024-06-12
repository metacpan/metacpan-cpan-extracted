# LOGO

     ____              _   _
    |  _ \ _   _ _ __ | |_(_)_ __ ___   ___
    | |_) | | | | '_ \| __| | '_ ` _ \ / _ \
    |  _ <| |_| | | | | |_| | | | | | |  __/
    |_| \_\\__,_|_| |_|\__|_|_| |_| |_|\___|

     ____       _
    |  _ \  ___| |__  _   _  __ _  __ _  ___ _ __
    | | | |/ _ \ '_ \| | | |/ _` |/ _` |/ _ \ '__|
    | |_| |  __/ |_) | |_| | (_| | (_| |  __/ |
    |____/ \___|_.__/ \__,_|\__, |\__, |\___|_|
                            |___/ |___/

# NAME

Runtime::Debugger - Easy to use REPL with existing lexical support and DWIM tab completion.

(emphasis on "existing" since I have not yet found this support in other modules).

# SYNOPSIS

In a script:

    use Runtime::Debugger;
    repl;

On the commandline:

    perl -MRuntime::Debugger -E 'repl'

Same, but with some variables to play with:

    perl -MRuntime::Debugger -E 'my $str1 = "Func"; our $str2 = "Func2"; my @arr1 = "arr-1"; our @arr2 = "arr-2"; my %hash1 = qw(hash 1); our %hash2 = qw(hash 2); my $coderef = sub { "code-ref: @_" }; {package My; sub Func{"My-Func"} sub Func2{"My-Func2"}} my $obj = bless {}, "My"; repl; say $@'

From another script/function:

    my $var_to_find = 111;

    sub other {
        use Runtime::Debugger;
        repl( levels_up => 1 );
    }

# DESCRIPTION

"What? Another debugger? What about ... ?"

## Other Modules

### perl5db.pl

The standard perl debugger (`perl5db.pl`) is a powerful tool.

Using `per5db.pl`, one would normally be able to do this:

    # Insert a breakpoint in your code:
    $DB::single = 1;

    # Then run the perl debugger to navigate there quickly:
    PERLDBOPT='Nonstop' perl -d my_script

If that works for you, then dont' bother with this module!
(joke. still try it.)

### Devel::REPL

This is a great and extendable module!

Unfortunately, I did not find a way to get the lexical variables
in a scope. (maybe I missed a plugin?!)

Example:

    perl -MDevel::REPL -E '
        my  $my_var  = 111;                # I want to access this
        our $our_var = 222;                # and this.
        my $repl = Devel::REPL->new;
        $repl->load_plugin($_) for qw(
            History
            LexEnv
            DDS
            Colors
            Completion
            CompletionDriver::INC
            CompletionDriver::LexEnv
            CompletionDriver::Keywords
            CompletionDriver::Methods
        );
        $repl->run;
    '

Sample Output:

    $ print $my_var
    Compile error: Global symbol "$my_var" requires explicit package name ...

    $ print $our_var
    Compile error: Global symbol "$our_var" requires explicit package name ...

### Reply

This module also looked nice, but same issue.

Example:

    perl -MReply -E '
        my $var=111;
        Reply->new->run;
    '

Sample Output:

    > print $var
    1
    > my $var2 = 222
    222
    > print $var2
    1

## This Module

While debugging some long-running, perl,
Selenium test files, I basically got bored
during the long waits, and created a simple
Read Evaluate Print Loop (REPL) to avoid
the annoyong waits between test tries.

Originally I would have a hot key
command to drop in a snippet of code like
this into my test code to essentially insert
a breakpoint/pause.

One can then examine what's going on in that
area of code.

Originally the repl code snippet was something
as simple as this:

    while(1){
      my $in = <STDIN>;
      chomp $in;
      last if $in eq 'q';
      eval $in;
    }

With that small snippet I could pause in a long
running test (which I didn't write) and try out
commands to help me to understand what needs to
be updated in the test (like a ->click into a
field before text could be entered).

And I was quite satisfied.

From there, this module increased in features
such as using `Term::ReadLine` for readline
support,tab completion, and history (up arrow).

### Attempts

This module has changed in its approach quite a
few times since it turns out to be quite tricky
to perform `eval_in_scope`.

#### Source Filter

To make usage of this module as simple as
possible, I tried my hand at source filters.

My idea was that by simply adding this line
of code:

    use Runtime::Debugger;

That would use a source filter to add in the REPL code.

This solution was great, but source filters can only
be applied at COMPILE TIME (That was new to me as well).

Unfortunately, the tests I am dealing with are
read as a string then evaled.

So, source filters, despite how clean they would
make my solution, would not work for my use cases.

Next idea.

#### Back To Eval

Then I decided to go back to using a command like:

    use Runtime::Debugger;
    eval run;

Where run would basically generates the REPL
code and eval would use the current scope to
apply the code.

Side note: other Debuggers I had tried before this
one, do not update lexical variables in the
current scope. So this, I think, is unique in this debugger.

#### Next pitfall

I learned later that `eval run` would under
certain circumstances not work:

First call would print 111, while the exact
same eval line would print undef afterwards.

    sub {
        my $v = 111;
        eval q(
            # my $v = $v; # Kind of a fix.
            eval 'say $v'; # 111
            eval 'say $v'; # undef
        );
    }->();

#### Still can eval run

Using `eval run` is still possible (for now).

Just be aware that it does not evaluate correctly
under certain circumstances.

## Solution

Simply add these lines:

    use Runtime::Debugger;
    repl;

This will basically insert a read, evaluate,
print loop (REPL).

This should work for more cases (just try not
to use nasty perl magic).

### Goal

To reach the current solution, it was essential
to go back to the main goal.

And the goal/idea is simple, be able to evaluate
an expression in a specific scope/context.

Basically looking for something like:

    peek_my(SCOPE)

But instead for eval:

    eval_in_scope(SCOPE)

Given `eval_in_scope(1)`, that would evaluate an expression,
but in a scope/context one level higher.

### Implementation

#### Scope

In order to eval a string of perl code correctly,
we need to figure out at which level the variable
is located.

Thats not hard to do: just look through increasing
`caller()` levels until finding the first whose
package name is not thia module's.

#### Peek

Given the scope level, peek\_my/our is utilized
to grab all the variables in that scope.

Having these variables:

    my  $var = 111;
    our $var = 222;

There can only be a single variable (glob) of
a name. When multiple, the lexical one would
be used.

#### Preprocess

Then we need to preprocess the piece of perl code
that would be evaled.

At this stage variables would be replaced which
their equivalent representation at found in
peek\_my/our.

This code:

    say $var

Might be replaced with something like this:

    say ${$PEEKS{'$var'}}

This transformation would normally be done
seamlessly and hidden from the user.

#### Eval

Finally, eval the string.

And we pretend to have done `eval_in_scope`.

### Future Ideas

One idea would be to create an XS function
which can perform an eval in a specific scope,
but without the translation magic that is
currently being done.

This might appear like peek\_my, but for eval.
So something like this:

    eval_in_scope("STRING_TO_EVAL", SCOPE_LEVEL);

# FUNCTIONS

## run

DEPRECATED! (Use `repl` instead)

Runs the REPL.

    eval run

Sets `$@` to the exit reason like
'INT' (Control-C) or 'q' (Normal exit/quit).

Note: This method is more stable than repl(), but at the same
time has limits. [See also](#lossy-undef-variable)

## repl

Works like eval, but without [the lossy bug](#lossy-undef-variable)

repl (
    history\_file => "$ENV{HOME}/.runtime\_debugger.yml",
    debug        => $ENV{RUNTIME\_DEBUGGER\_DEBUG} // 0,
    levels\_up    => 0,
);

Can specify the level at which to perform an eval
in relation to the level of this function call:

    levels_up => 0,  # Default
    levels_up => 1,  # One scope/level above this.
                     # Useful for scripts using this.
    levels_up => -1, # One level below for internals.

## \_apply\_peeks

Transform variables in a code string
into references to the same variable
as found with peek\_my/our.

Try to insert the peek\_my/our references
(peeks) only when needed (should appear
natural to the user).

Ok to transform:

    say "@a"

NOT ok to transform:

    say "%h"

## Tab Completion

This module has rich, DWIM tab completion support:

    Press TAB when:

    - No input - view commands and variables.

    - After arrow ("->") - to auto append either a "{" or "[" or "(".
      (Depends on variable type)

    - After a hash) - show keys.

    - Otherwise - show variables.

## \_match

Wrapper to simplify completion function.

Input:

    words   => ARRAYREF, # What to look for.
    partial => STRING,   # Default: ""  - What you typed so far.
    prepend => "STRING", # Default: ""  - prepend to each possiblity.
    nospace => 0,        # Default: "0" - will not append a space after a completion.

Returns the possible matches:

## help

Show help section.

## History

All commands run in the debugger are saved locally and loaded next time the module is loaded.

## hist

Can use hist to show a history of commands.

By default will show 20 commands:

    hist

Same thing:

    hist 20

Can show more:

    hist 50

## d

Data::Dumper::Dump anything.

You can use "d" as a print command which
can show a simple or complex data structure.

    d 123
    d [1, 2, 3]

## dd

Devel::Peek::Dump.

You can use "dd" to see the inner contents
of a structure/variable.

    dd @var
    dd [1..3]

## p

Data::Printer::p

You can use "p" as a print command which
can show a simple or complex data structure
with colors.

Some example uses:

    p 123
    p [1, 2, 3]
    p $scalar
    p \@array
    p \%hash
    p $object

## uniq

Returns a unique list of elements.

List::Util in lower than v5.26 does not
provide a unique function.

## Internal Properties

### attr

Internal use.

### debug

Internal use.

### levels\_up

Internal use.

### term

Internal use.

# ENVIRONMENT

Install required library:

    sudo apt install libreadline-dev

Enable this environmental variable to
show debugging information:

    RUNTIME_DEBUGGER_DEBUG=1

# SEE ALSO

## [https://perldoc.perl.org/perldebug](https://perldoc.perl.org/perldebug)

[Why not perl debugger?](#perl5db-pl)

## [https://metacpan.org/pod/Devel::REPL](https://metacpan.org/pod/Devel::REPL)

[Why not Devel::REPL?](#devel-repl)

## [https://metacpan.org/pod/Reply](https://metacpan.org/pod/Reply)

[Why not Reply?](#reply)

# AUTHOR

Tim Potapov, `<tim.potapov[AT]gmail.com>` 🐪🥷

# BUGS

## Control-C

Doing a Control-C may occassionally break
the output in your terminal (exit with 'q'
when possible).

Simply run any one of these:

    reset
    tset
    stty echo

## New Variables

Currently it is not possible to create new
lexicals (my) variables.

You can create new global variables by:

    - Default
      $var=123

    - Using our
      $our $var=123

    - Given the full path
      $My::var = 123

## Lossy undef Variable

inside a long running (and perhaps complicated)
script, a variable may become undef.

This piece of code demonstrates the problem
with using c&lt;eval run>.

    sub Func {
        my ($code) = @_;
        $code->();
    }

    Func( sub{
        my $v2 = 222;

        # This causes issues.
        use Runtime::Debugger;
        eval run;

        # Whereas, this one works.
        use Runtime::Debugger;
        repl;
    });

This issue is described here [https://www.perlmonks.org/?node\_id=11158351](https://www.perlmonks.org/?node_id=11158351)

## Other

Please report any (other) bugs or feature
requests to [https://github.com/poti1/runtime-debugger/issues](https://github.com/poti1/runtime-debugger/issues).

# SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Runtime::Debugger

You can also look for information at:

[https://metacpan.org/pod/Runtime::Debugger](https://metacpan.org/pod/Runtime::Debugger)

[https://github.com/poti1/runtime-debugger](https://github.com/poti1/runtime-debugger)

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
