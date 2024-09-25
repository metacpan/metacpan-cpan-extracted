package Runtime::Debugger;

=head1 LOGO

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

=cut

use 5.018;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Data::Printer use_prototypes => 0;
use Term::ReadLine;
use Term::ANSIColor qw( colored );
use PadWalker       qw( peek_our  peek_my );
use Scalar::Util    qw( blessed reftype );
use Class::Tiny     qw( term attr debug levels_up );
use YAML::XS();
use re      qw( eval );       # For debug.
use feature qw( say );
use parent  qw( Exporter );
use subs    qw( uniq );

our $VERSION = '1.05';
our @EXPORT  = qw( run repl d dd np p );
our %PEEKS;

=head1 NAME

Runtime::Debugger - Easy to use REPL with existing lexical support and DWIM tab completion.

(emphasis on "existing" since I have not yet found this support in other modules).

=cut

=head1 SYNOPSIS

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

=cut

=head1 DESCRIPTION

"What? Another debugger? What about ... ?"

=cut

=head2 Other Modules

=head3 perl5db.pl

The standard perl debugger (C<perl5db.pl>) is a powerful tool.

Using C<per5db.pl>, one would normally be able to do this:

    # Insert a breakpoint in your code:
    $DB::single = 1;

    # Then run the perl debugger to navigate there quickly:
    PERLDBOPT='Nonstop' perl -d my_script

If that works for you, then dont' bother with this module!
(joke. still try it.)

=head3 Devel::REPL

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

=head3 Reply

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

=cut

=head2 This Module

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
such as using C<Term::ReadLine> for readline
support,tab completion, and history (up arrow).

=cut

=head3 Attempts

This module has changed in its approach quite a
few times since it turns out to be quite tricky
to perform C<eval_in_scope>.

=head4 Source Filter

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

=head4 Back To Eval

Then I decided to go back to using a command like:

 use Runtime::Debugger;
 eval run;

Where run would basically generates the REPL
code and eval would use the current scope to
apply the code.

Side note: other Debuggers I had tried before this
one, do not update lexical variables in the
current scope. So this, I think, is unique in this debugger.

=head4 Next pitfall

I learned later that C<eval run> would under
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

=head4 Still can eval run

Using C<eval run> is still possible (for now).

Just be aware that it does not evaluate correctly
under certain circumstances.

=cut

=head2 Solution

Simply add these lines:

    use Runtime::Debugger;
    repl;

This will basically insert a read, evaluate,
print loop (REPL).

This should work for more cases (just try not
to use nasty perl magic).

=head3 Goal

To reach the current solution, it was essential
to go back to the main goal.

And the goal/idea is simple, be able to evaluate
an expression in a specific scope/context.

Basically looking for something like:

 peek_my(SCOPE)

But instead for eval:

 eval_in_scope(SCOPE)

Given C<eval_in_scope(1)>, that would evaluate an expression,
but in a scope/context one level higher.

=head3 Implementation

=head4 Scope

In order to eval a string of perl code correctly,
we need to figure out at which level the variable
is located.

Thats not hard to do: just look through increasing
C<caller()> levels until finding the first whose
package name is not thia module's.

=head4 Peek

Given the scope level, peek_my/our is utilized
to grab all the variables in that scope.

Having these variables:

 my  $var = 111;
 our $var = 222;

There can only be a single variable (glob) of
a name. When multiple, the lexical one would
be used.

=head4 Preprocess

Then we need to preprocess the piece of perl code
that would be evaled.

At this stage variables would be replaced which
their equivalent representation at found in
peek_my/our.

This code:

 say $var

Might be replaced with something like this:

 say ${$PEEKS{'$var'}}

This transformation would normally be done
seamlessly and hidden from the user.

=head4 Eval

Finally, eval the string.

And we pretend to have done C<eval_in_scope>.

=head3 Future Ideas

One idea would be to create an XS function
which can perform an eval in a specific scope,
but without the translation magic that is
currently being done.

This might appear like peek_my, but for eval.
So something like this:

 eval_in_scope("STRING_TO_EVAL", SCOPE_LEVEL);

=cut

=head1 FUNCTIONS

=cut

# API

=head2 run

DEPRECATED! (Use C<repl> instead)

Runs the REPL.

 eval run

Sets C<$@> to the exit reason like
'INT' (Control-C) or 'q' (Normal exit/quit).

Note: This method is more stable than repl(), but at the same
time has limits. L<See also|/Lossy undef Variable>

=cut

sub run {
    <<'CODE';

######################################
#            REPL CODE
######################################
use strict;
use warnings;
use feature qw(say);
my $repl = Runtime::Debugger->_init;
local $@;
eval {          # Catch loop exit.
    while ( 1 ) {
        eval $repl->_step;
        $repl->_show_error($@) if $@;
    }
};
$repl->_show_error($@) if $@;
######################################
CODE
}

=head2 repl

Works like eval, but without L<the lossy bug|/Lossy undef Variable>

repl (
    history_file => "$ENV{HOME}/.runtime_debugger.yml",
    debug        => $ENV{RUNTIME_DEBUGGER_DEBUG} // 0,
    levels_up    => 0,
);

Can specify the level at which to perform an eval
in relation to the level of this function call:

 levels_up => 0,  # Default
 levels_up => 1,  # One scope/level above this.
                  # Useful for scripts using this.
 levels_up => -1, # One level below for internals.

=cut

sub repl {
    my $repl = __PACKAGE__->_init( @_ );

    local $@;
    eval {    # Catch loop exit.
        while ( 1 ) {
            $repl->_repl_step;
            $repl->_show_error( $@ ) if $@;
        }
    };
    $repl->_show_error( $@ ) if $@;
}

# Initialize

sub _init {
    my ( $class, %args ) = @_;

    # Setup the terminal.
    $Term::ReadLine::Gnu::has_been_initialized = 0;
    my $term    = Term::ReadLine->new( $class );
    my $attribs = $term->Attribs;
    $term->ornaments( 0 );    # Remove underline from terminal.

    # Treat '$my->[' as one word.
    $attribs->{completer_word_break_characters} =~ s/ [>] //xg;
    $attribs->{completer_word_break_characters} .= '[';

    # Be able to complete: '$scalar', '@array', '%hash'.
    $attribs->{special_prefixes} = '$@%&';

    # Build the debugger object.
    my $self = bless {
        history_file => "$ENV{HOME}/.runtime_debugger.yml",
        term         => $term,
        attr         => $attribs,
        debug        => $ENV{RUNTIME_DEBUGGER_DEBUG} // 0,
        levels_up    => 0,
        %args,
    }, $class;

    # https://metacpan.org/pod/Term::ReadLine::Gnu#Custom-Completion
    # Definition for list_completion_function is here: Term/ReadLine/Gnu/XS.pm
    $attribs->{attempted_completion_function} = sub { $self->_complete( @_ ) };

    $self->_restore_history;

    $self->_setup_vars;

    # Setup some signal handling.
    for my $signal ( qw( INT TERM HUP ) ) {
        $SIG{$signal} = sub { $self->_exit( $signal ) };
    }

    $self;
}

sub _setup_vars {
    my ( $self ) = @_;

    $self->_set_peeks;
    $self->_split_vars_by_types;

    $self->{commands} = [ $self->_define_commands ];
    $self->{commands_and_vars_all} =
      [ @{ $self->{commands} }, @{ $self->{vars_all} } ];

    $self->_normalize_var_defaults;

    $self;
}

sub _set_peeks {
    my ( $self ) = @_;

    # Get the current variables in the invoking scope.
    #
    # CAUTION: avoid having the same name for a lexical and global
    # variable since the last variable declared would "win".

    # How many levels until at "$repl=" or main.
    my $levels   = $self->_calc_scope;
    my $peek_our = peek_our( $levels );
    my $peek_my  = peek_my( $levels );

    # Add a reference to the repl.
    $peek_my->{'$repl'} = \$self;

    # Link for cleaner access later.
    %PEEKS = ( %$peek_our, %$peek_my );

    # Get just the variable names.
    my @vars_lexical = keys %$peek_my;
    my @vars_global  = keys %$peek_our;
    my @vars_all     = uniq @vars_lexical, @vars_global;

    $self->{peek_my}      = $peek_my;
    $self->{peek_our}     = $peek_our;
    $self->{peek_all}     = \%PEEKS;
    $self->{vars_lexical} = \@vars_lexical;
    $self->{vars_global}  = \@vars_global;
    $self->{vars_all}     = \@vars_all;
}

sub _calc_scope {
    my ( $self ) = @_;

    my $scope = 0;
    my $pkg   = __PACKAGE__;
    my $caller;

    # Find the first scope level outside
    # this package.
    1 while ( ( $caller = caller( ++$scope ) ), $caller and $caller eq $pkg );

    $scope += $self->levels_up;

    say "scope: $scope" if $self->debug;

    $scope;
}

sub _split_vars_by_types {
    my ( $self ) = @_;
    my @queue = @{ $self->{vars_all} // [] };

    # Separate variables by types.
    my %already_stored;
    my %added_duplicates;    # These are ok to have twice.

    while ( local $_ = shift @queue ) {

        # Show duplcate variables with same name (probably different sigil).
        if ( $already_stored{$_} ) {
            if ( $self->debug >= 2 or not $added_duplicates{$_} ) {
                $self->_show_error(
                        "Skipping variable with same name: '$_' "
                      . "(maybe same name, but different sigil?)" );
            }
            next;
        }

        $already_stored{$_}++;    # First time seeing it then.

        if ( / ^ \$ /x ) {
            push @{ $self->{vars_scalar} }, $_;

            my $ref  = $self->{peek_all}{$_};
            my $type = ref( $ref );
            if ( $type eq "SCALAR" ) {
                push @{ $self->{vars_string} }, $_;
            }
            elsif ( $type eq "REF" ) {
                push @{ $self->{vars_ref} }, $_;
                if ( blessed( $$ref ) ) {
                    push @{ $self->{vars_obj} }, $_;
                }
                elsif ( ref( $$ref ) eq "CODE" ) {
                    push @{ $self->{vars_code} }, $_;
                }
                elsif ( ref( $$ref ) eq "HASH" ) {
                    push @{ $self->{vars_hashref} }, $_;
                }
                elsif ( ref( $$ref ) eq "ARRAY" ) {
                    push @{ $self->{vars_arrayref} }, $_;
                }
                else {
                    push @{ $self->{vars_ref_else} }, $_;
                }
            }
            else {
                push @{ $self->{vars_scalar_else} }, $_;
            }
        }
        elsif ( / ^ \@ /x ) {
            push @{ $self->{vars_array} }, $_;

            # Allow access via @array, $array[0]
            my $var_scalar = '$' . substr( $_, 1 );
            push @{ $self->{vars_all} }, $var_scalar;
            push @queue,                 $var_scalar;
            $self->{peek_all}{$var_scalar} =
              $self->{peek_all}{$_};
            $added_duplicates{$var_scalar}++;

            say "Added $_: $var_scalar" if $self->debug >= 2;
        }
        elsif ( / ^ % /x ) {
            push @{ $self->{vars_hash} }, $_;

            # Allow access via %hash, $hash{key} and @hash{key,key}
            my $var_scalar = '$' . substr( $_, 1 );
            my $var_array  = '@' . substr( $_, 1 );
            push @{ $self->{vars_all} }, $var_scalar, $var_array;
            push @queue,                 $var_scalar, $var_array;
            $self->{peek_all}{$var_scalar} = $self->{peek_all}{$var_array} =
              $self->{peek_all}{$_};
            $added_duplicates{$var_scalar}++;
            $added_duplicates{$var_array}++;

            say "Added $_: $var_scalar, $var_array" if $self->debug >= 2;
        }
        else {
            push @{ $self->{vars_else} }, $_;
        }
    }
}

sub _normalize_var_defaults {
    my ( $self ) = @_;

    my @vars = qw(
      vars_lexical
      vars_global
      vars_all

      vars_scalar
      vars_string
      vars_ref
      vars_obj
      vars_code
      vars_hashref
      vars_arrayref
      vars_ref_else
      vars_scalar_else

      vars_array

      vars_hash

      vars_else

      commands
      commands_and_vars_all
    );

    # Make sure all "vars_*" are defined, sorted, and uniq:
    for ( @vars ) {
        $self->{$_} = [ uniq sort @{ $self->{$_} // [] } ];
    }

}

=head2 _apply_peeks

Transform variables in a code string
into references to the same variable
as found with peek_my/our.

Try to insert the peek_my/our references
(peeks) only when needed (should appear
natural to the user).

Ok to transform:

 say "@a"

NOT ok to transform:

 say "%h"

=cut

sub _apply_peeks {
    my ( $self, $code ) = @_;
    my $r = $self->_define_regex;

    $code =~ s{
        ($r->{text})
    }{
        local $_ = "$1";
        p \%+ if $self->debug >= 2;

        if($+{unquoted}){
            s/$r->{var_unquoted}/$self->_to_peek(%+)/ge;
        }
        elsif($+{quoted}){
            s/$r->{var_quoted}/$self->_to_peek(%+)/ge;
        }

        $_;
    }xge;

    $code;
}

sub _define_regex {
    my ( $self ) = @_;

    # Some are mainly defined here just to
    # keep my editor code folding functional.
    my $var_name = qr{ [_A-Za-z]\w* }x;
    my $any_3    = qr{ .{0,3} }x;
    my $qq       = '"';
    my $q        = "'";

    {

        var_unquoted => qr{
            (?<var>
                (?<sigil> [\$\@%] )
                (?<name> $var_name )
            )
            (?= (?<next> $any_3 ) )
        }x,

        var_quoted => qr{
            (?<! \\ )  # Should not be escaped.
            (?<var>
                (?<sigil> [\$\@] )
                (?<name> $var_name )
            )
            (?= (?<next> $any_3 ) )
        }x,

        text => qr{

            # Not any (common) form of quotes.
            (?<unquoted>
                (?:
                    (?!
                          $qq
                        | $q
                        | \b q[qrw]? \b
                    ) .
                )++ # Should not be empty.
            )
            (?{ say "unquoted: |$`:$&:$'|" if $self->debug >= 2 })

            |

            # Otherwise, some form of quotes.
            # Figure out which to decide whether
            # to keep %h as %h or expand.

            # Double quotes.
            $qq
                (?<quoted>
                    (?>               # Do not backtrack.
                        [^$qq\\]*     # None quote or escape.
                        (?:           # maybe followed by
                            \\.       # an escape
                            [^$qq\\]* # and more none quotes or escapes.
                        )*
                    )
                )
            $qq
            (?{ say "$qq:      |$`:$&:$'|" if $self->debug >= 2 })

            |

            # Single quotes.
            # (no capture to skip it).
            $q
                (?>
                    [^$q\\]*
                    (?:
                        \\.
                        [^$q\\]*
                    )*
                )
            $q
            (?{ say "$q:       |$`:$&:$'|" if $self->debug >= 2 })

            |

            # qq and qr operators.
            \b q[qr] \b \s* (?<quoted>
                  (?&PARENS)
                | (?&CURLY)
                | (?&SQUARE)
                | (?&ANGLE)
            )
            (?{ say "q[qr]:    |$`:$&:$'|" if $self->debug >= 2 })

            |

            # q and qw operators.
            # (no capture to skip it).
            \b qw? \b \s* (?:
                  (?&PARENS)
                | (?&CURLY)
                | (?&SQUARE)
                | (?&ANGLE)
            )
            (?{ say "qw?:      |$`:$&:$'|" if $self->debug >= 2 })

            # Sub pattern definitions.
            (?(DEFINE)
                (?<PARENS>
                    \(                      (?{ say "  parenS  |$`:$&:$'|" if $self->debug >= 2 })
                        (?:                 (?{ say "  parenA  |$`:$&:$'|" if $self->debug >= 2 })
                              [^()\\]++     (?{ say "  parenB  |$`:$&:$'|" if $self->debug >= 2 })
                            | \\.           (?{ say "  parenC  |$`:$&:$'|" if $self->debug >= 2 })
                            | (?&PARENS)    (?{ say "  parenD  |$`:$&:$'|" if $self->debug >= 2 })
                        )*+                 (?{ say "  parenE  |$`:$&:$'|" if $self->debug >= 2 })
                    \)
                )
                (?<CURLY>
                    \{
                        (?:
                              [^{}\\]++
                            | \\.
                            | (?&CURLY)
                        )*+
                    \}
                )
                (?<SQUARE>
                    \[
                        (?:
                              [^\[\]\\]++
                            | \\.
                            | (?&SQUARE)
                        )*+
                    \]
                )
                (?<ANGLE>
                    <
                        (?:
                              [^<>\\]++
                            | \\.
                            | (?&ANGLE)
                        )*+
                    >
                )
            )
        }x,

    };
}

sub _to_peek {
    my ( $repl, %match ) = @_;
    my $var   = $match{var};
    my $sigil = $match{sigil};
    my $name  = $match{name};
    my $next  = $match{next} // "";

    my $is_curly = '{';    # To make my editor happy.

    # Find the true variable with sigil.
    if ( $next =~ / ^ \[ /x ) {    # Array ref.
        $var = "\@$name";
    }
    elsif ( $next =~ / ^ $is_curly /x ) {    # Hash ref.
        $var = "\%$name";
    }

    my $ref = ref $PEEKS{$var};
    my $val = sprintf( '$%s::PEEKS{qq(%s)}', __PACKAGE__, quotemeta( $var ), );

    if ( $repl->debug ) {
        say "var:   $var";
        say "sigil: $sigil";
        say "next:  $next";
        say "ref:   $ref";
    }

    if ( $ref eq 'REF' ) {
        $val = "\${$val}";
    }
    elsif ( $ref eq 'SCALAR' ) {
        $val = "\${$val}";
    }
    elsif ( $ref eq 'ARRAY' ) {
        $val = "${sigil}{$val}";
    }
    elsif ( $ref eq 'HASH' ) {
        $val = "${sigil}{$val}";
    }
    else {
        return $var;
    }

    $val;
}

sub _step {
    my ( $repl ) = @_;

    # Show help when first loading the debugger.
    if ( not $repl->{step_counter}++ ) {
        $repl->help;
    }

    my $input = $repl->term->readline( "perl>" ) // '';
    say "input_after_readline=[$input]" if $repl->debug;

    # Change "COMMAND ARG" to "$repl->COMMAND(ARG)".
    $input =~ s/ ^
        (
              help
            | hist
        ) \b
        (.*)
    $ /\$repl->$1($2)/x;

    $repl->_exit( $input ) if $input eq 'q';

    say "input_after_step=[$input]" if $repl->debug;
    $input;
}

sub _repl_step {
    my ( $repl ) = @_;

    my $input = $repl->_build_step;

    eval $input;
}

sub _build_step {
    my ( $repl ) = @_;

    # Show help when first loading the debugger.
    $repl->help if not $repl->{step_counter}++;

    my $input = $repl->term->readline( "perl>" ) // '';
    say "input_after_readline=[$input]" if $repl->debug;

    # Change "COMMAND ARG" to "$repl->COMMAND(ARG)".
    $input =~ s/ ^
        (
              help
            | hist
        ) \b
        (.*)
    $ /\$repl->$1($2)/x;

    $repl->_exit( $input ) if $input eq 'q';

    $input = $repl->_apply_peeks( $input );

    say "input_after_step=[$input]" if $repl->debug;

    $input;
}

# Tab Completion

=head2 Tab Completion

This module has rich, DWIM tab completion support:

 Press TAB when:

 - No input - view commands and variables.

 - After arrow ("->") - to auto append either a "{" or "[" or "(".
   (Depends on variable type)

 - After a hash) - show keys.

 - Otherwise - show variables.

=cut

sub _complete {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    say ""                  if $self->debug >= 2;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    # Note: return list is what will be shown as possiblities.

    # Empty - show commands and variables.
    return $self->_complete_empty( @_ ) if $line =~ / ^ \s* $ /x;

    # Help or History command - complete the word.
    return $self->_complete_h( @_ ) if $line =~ / ^ \s* h \w* $ /x;

    # Dump/Print command - space afterwards.
    return $self->_complete_pd( @_ ) if $line =~ / ^ \s* (?: p | dd? ) $ /x;

    # Method call or coderef - append "(".
    return $self->_complete_arrow( "$1", "$2", @_ )
      if $text =~ / ^ ( \$ \S+ ) -> (\S*) $ /x;

    # Hash or hashref - Show possible keys and string variables.
    return $self->_complete_hash( "$1", @_ )
      if substr( $line, 0, $end ) =~ $self->_is_hash_match();

    # Otherwise assume its a variable.
    return $self->_complete_vars( @_ );
}

sub _complete_empty {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    $self->_match(
        words   => $self->{commands_and_vars_all},
        partial => $text,
    );
}

sub _complete_h {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    $self->_match(
        partial => $text,
        words   => [ "help", "hist" ],
        nospace => 1,
    );
}

sub _complete_pd {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    $self->_match(
        words   => [ "d", "dd", "p" ],
        partial => $text,
    );
}

sub _complete_arrow {
    my $self = shift;
    my ( $var, $partial_method, $text, $line, $start, $end ) = @_;
    my $ref = $self->{peek_all}->{$var} // "";
    $partial_method //= '';
    $self->_dump_args( @_ ) if $self->debug >= 2;
    say "ref: $ref"         if $self->debug >= 2;

    return if ref( $ref ) ne "REF";    # Coderef or object.

    # Object call or coderef.
    my $obj_or_coderef = $$ref;

    # Object.
    if ( blessed( $obj_or_coderef ) ) {
        say "IS_OBJECT: $obj_or_coderef" if $self->debug >= 2;

        my $methods = $self->{methods}{$obj_or_coderef};
        if ( not $methods ) {
            $methods = $self->_get_object_functions( $obj_or_coderef );
            $self->{methods}{$obj_or_coderef} = $methods;

            # push @$methods, "(";    # Access as method or hash refs.
            push @$methods, "{" if reftype( $obj_or_coderef ) eq "HASH";
            push @$methods, @{ $self->{vars_string} };
            @$methods = uniq sort @$methods;
        }
        say "methods: @$methods" if $self->debug >= 2;

        return $self->_match(
            words   => $methods,
            partial => $partial_method,
            prepend => "$var->",
            nospace => 1,
        );
    }

    # Coderef.
    if ( ref( $obj_or_coderef ) eq "CODE" ) {
        say "IS_CODE: $obj_or_coderef" if $self->debug >= 2;
        return $self->_match(
            words   => ["("],
            prepend => "$text",
            nospace => 1,
        );
    }

    # Hashref.
    if ( ref( $obj_or_coderef ) eq "HASH" ) {
        say "IS_HASH $obj_or_coderef" if $self->debug >= 2;
        return $self->_match(
            words   => ["{"],
            prepend => "$text",
            nospace => 1,
        );
    }

    # Arrayref.
    if ( ref( $obj_or_coderef ) eq "ARRAY" ) {
        say "IS_ARRAY: $obj_or_coderef" if $self->debug >= 2;
        return $self->_match(
            words   => ["["],
            prepend => "$text",
            nospace => 1,
        );
    }

    say "NOT OBJECT or CODEREF: $obj_or_coderef" if $self->debug >= 2;
    return;
}

sub _get_object_functions {
    my ( $self, $obj ) = @_;
    my $class = ref $obj;
    no strict 'refs';

    my @functions = grep {
        !/ ^
        (?:
            import
        )
        $ /x
      }
      grep { not / ^ [A-Z_]+ $ /x }    # Skip special functions.
      sort
      keys %{"${class}::"};

    \@functions;
}

sub _is_hash_match {
    my ( $self ) = @_;
    my $is_curly = '}';                # To make my editor happy.

    qr{
        (
            [\$${is_curly}@%]       # Variable sigil.
            (?: (?!->|\s). )+       # Next if not a -> or space.
        )
        (?:->)?                     # Maybe a ->.
        \{                          # Opening brace.
        [^\}]*                      # Any non braces.
        $                           # EOL.
    }x;
}

sub _complete_hash {
    my $self = shift;
    my ( $var, $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    my @hash_keys = @{ $self->{vars_string} };
    my $ref       = $self->{peek_all}{$var} // '';
    $ref = $$ref if reftype( $ref ) eq "REF";
    push @hash_keys, keys %$ref if reftype( $ref ) eq "HASH";

    $self->_match(
        words   => [ sort @hash_keys ],
        partial => $text,
        nospace => 1,
    );
}

sub _complete_vars {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    $self->_match(
        words   => $self->{vars_all},
        partial => $text,
        nospace => 1,
    );
}

=head2 _match

Wrapper to simplify completion function.

Input:

 words   => ARRAYREF, # What to look for.
 partial => STRING,   # Default: ""  - What you typed so far.
 prepend => "STRING", # Default: ""  - prepend to each possiblity.
 nospace => 0,        # Default: "0" - will not append a space after a completion.

Returns the possible matches:

=cut

sub _match {
    my $self  = shift;
    my %parms = @_;
    $self->_dump_args( @_ ) if $self->debug >= 2;

    # completion_word does NOT automationally get reset per call.
    # completion_suppress_append gets reset per call.
    # attempted_completion_over gets reset per call.
    $self->attr->{completion_word}            = $parms{words};
    $self->attr->{completion_suppress_append} = 1 if $parms{nospace};
    $self->attr->{attempted_completion_over}  = 1;  # Avoid filename completion.

    $parms{partial} //= "";
    $parms{prepend} //= "";

    # Return possible matches.
    map { "$parms{prepend}$_" }
      $self->term->completion_matches( $parms{partial},
        $self->attr->{list_completion_function} );
}

sub _dump_args {
    my $self = shift;
    my $sub  = ( caller( 1 ) )[3];
    $sub =~ s/ ^ .* :: //x;    # Short sub name.
    my $args = join ",", map { defined( $_ ) ? "'$_'" : "undef" } @_;
    printf "%-20s %s\n", $sub, "($args)";
}

sub _define_commands {
    (
        "help",    # Changed in _step to $repl->help().
        "hist",    # Changed in _step to $repl->hist().
        "p",       # From Data::Printer and exporting it.
        "d",       # Exporting it.
        "dd",      # Exporting it.
        "q",       # Used in _step to stop the repl.
    );
}

# Help

=head2 help

Show help section.

=cut

sub help {
    my ( $self ) = @_;

    my $help = $self->_define_help;

    say $self->_color_help( $help );
}

sub _define_help {
    my ( $self ) = @_;
    my $version  = $self->VERSION;
    my $class    = ref $self;

    <<"HELP";

 $class $version

 <TAB>          - Show options.
 <Up/Down>      - Scroll history.
 help           - Show this section.
 hist [N=5]     - Show last N commands.
 p DATA         - Data printer (colored).
 d DATA         - Data dumper.
 dd DATA, [N=3] - Dump internals (with depth).
 q              - Quit debugger.
HELP
}

sub _color_help {
    my ( $self, $string ) = @_;
    my @lines = split /\n/, $string, -1;

    for ( @lines ) {

        # Module version line.
        if ( /::/ ) {
            s/ ^ \s+ \K (\S+) \s+ (\S+) $ /
                colored($1,"YELLOW") . " " . colored($2, "GREEN")
            /xme;
        }

        # Command and description line.
        elsif ( / - / ) {
            my ( $command_plus, $desc ) = split / - /;
            my ( $commands, $options ) = split "", $command_plus, 2;

            $command_plus =~ s/
                ^ \s+
                    \K
                    (\S+)           # Commmand.
                    (.+)            # Options.
                $
                /
                    colored("$1", "YELLOW")
                  . colored("$2", "GREEN")
                /xge;

            $_ = join " - ", ( $command_plus, colored( $desc, "DARK" ), );
        }

    }

    $string = join "\n", @lines;

    $string;
}

# History

=head2 History

All commands run in the debugger are saved locally and loaded next time the module is loaded.

=cut

=head2 hist

Can use hist to show a history of commands.

By default will show 20 commands:

 hist

Same thing:

 hist 20

Can show more:

 hist 50

=cut

sub hist {
    my ( $self, $levels ) = @_;
    my @history_raw = $self->_history;
    return if not @history_raw;

    my @history =
      map {
        sprintf "%s %s",
          colored( $_ + 1,           "YELLOW" ),
          colored( $history_raw[$_], "GREEN" );
      } ( 0 .. $#history_raw );

    # Show a limited amount of items from history.
    $levels //= 20;
    @history = splice @history, -$levels if $levels < @history;

    say for @history;
}

sub _history {
    my $self = shift;

    # Setter.
    return $self->term->SetHistory( @_ ) if @_;

    # Getter.
    # Last command should be the first you see upon hiting arrow up
    # and also without any duplicates.
    my @history = reverse uniq reverse $self->term->GetHistory;
    pop @history
      if @history and $history[-1] eq "q";    # Don't record quit command.

    $self->term->SetHistory( @history );

    @history;
}

sub _restore_history {
    my ( $self ) = @_;
    my @history;

    # Restore last history.
    if ( -e $self->{history_file} ) {
        my $all = eval { YAML::XS::LoadFile( $self->{history_file} ) };
        if ( $@ ) {
            warn "$@\n";
            return;
        }
        $all //= {};
        @history = @{$all->{history} //= [] };
    }

    @history = ( "q" ) if not @history;    # avoid blank history.
    $self->_history( @history );
}

sub _save_history {
    my ( $self ) = @_;

    # Save current history.
    eval {
        YAML::XS::DumpFile(
            $self->{history_file},
            {
                history => [ $self->_history ],
            },
        );
    };
    warn "$@\n" if $@;
}

# Print

=head2 d

Data::Dumper::Dump anything.

You can use "d" as a print command which
can show a simple or complex data structure.

 d 123
 d [1, 2, 3]

=cut

sub d {
    my $d = Data::Dumper
      ->new( \@_ )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Terse( 1 )
      ->Useqq( 1 );

    return $d->Dump if wantarray;
    print $d->Dump;
}

=head2 dd

Devel::Peek::Dump.

You can use "dd" to see the inner contents
of a structure/variable.

 dd @var
 dd [1..3]

=cut

sub dd {
    require Devel::Peek;
    Devel::Peek::Dump( @_ );
}

=head2 p

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

=cut

# Misc

=head2 uniq

Returns a unique list of elements.

List::Util in lower than v5.26 does not
provide a unique function.

=cut

sub uniq (@) {
    my %h;
    grep { not $h{$_}++ } @_;
}

# Cleanup

sub _exit {
    my ( $self, $how ) = @_;

    $self->_save_history;

    die "Exit via '$how'\n";
}

sub Term::ReadLine::DESTROY {
    my ( $self ) = @_;

    # Make sure to fix the terminal incase of errors.
    # This will reset the terminal similar to
    # what these should do:
    # - "reset"
    # - "tset"
    # - "stty echo"
    #
    # Using this DESTROY function since "$self->{term}"
    # is already destroyed by the time we call "_exit".
    $self->deprep_terminal;
}

sub _show_error {
    my ( $self, $error ) = @_;

    # Remove eval line numbers.
    $error =~ s/ at \(eval .+//;

    say colored( $error, "RED" );
}

# Pod

=head2 Internal Properties

=head3 attr

Internal use.

=head3 debug

Internal use.

=head3 levels_up

Internal use.

=head3 term

Internal use.

=cut

=head1 ENVIRONMENT

Install required library:

 sudo apt install libreadline-dev

Enable this environmental variable to
show debugging information:

 RUNTIME_DEBUGGER_DEBUG=1

=cut

=head1 SEE ALSO

=head2 L<https://perldoc.perl.org/perldebug>

L<Why not perl debugger?|/perl5db.pl>

=head2 L<https://metacpan.org/pod/Devel::REPL>

L<Why not Devel::REPL?|/Devel::REPL>

=head2 L<https://metacpan.org/pod/Reply>

L<Why not Reply?|/Reply>

=cut

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >> E<0x1f42a>E<0x1f977>

=cut

=head1 BUGS

=head2 Control-C

Doing a Control-C may occassionally break
the output in your terminal (exit with 'q'
when possible).

Simply run any one of these:

 reset
 tset
 stty echo

=head2 New Variables

Currently it is not possible to create new
lexicals (my) variables.

You can create new global variables by:

 - Default
   $var=123

 - Using our
   $our $var=123

 - Given the full path
   $My::var = 123

=head2 Lossy undef Variable

inside a long running (and perhaps complicated)
script, a variable may become undef.

This piece of code demonstrates the problem
with using c<eval run>.

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

This issue is described here L<https://www.perlmonks.org/?node_id=11158351>

=head2 Other

Please report any (other) bugs or feature
requests to L<https://github.com/poti1/runtime-debugger/issues>.

=cut

=head1 SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Runtime::Debugger

You can also look for information at:

L<https://metacpan.org/pod/Runtime::Debugger>

L<https://github.com/poti1/runtime-debugger>

=cut

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

"\x{1f42a}\x{1f977}"
