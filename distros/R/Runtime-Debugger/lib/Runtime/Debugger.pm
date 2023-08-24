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

use 5.012;
use strict;
use warnings;
use Data::Dumper;
use Filter::Simple;
use Term::ReadLine;
use Term::ANSIColor qw( colored );
use PadWalker       qw( peek_my  peek_our );
use Scalar::Util    qw( blessed reftype );
use Class::Tiny     qw( term attr debug );
use feature         qw( say state );
use parent          qw( Exporter );
use subs            qw( p uniq );

our $VERSION = '0.12';
our @EXPORT  = qw( run p );
our $FILTER  = 1;

=head1 NAME

Runtime::Debugger - Easy to use REPL with existing lexical support and DWIM tab completion.

(emphasis on "existing" since I have not yet found this support in other modules).

=head1 SYNOPSIS

Start the debugger:

    perl -MRuntime::Debugger -E 'eval run'

Same, but with some variables to play with:

    perl -MRuntime::Debugger -E 'my $str1 = "Func"; our $str2 = "Func2"; my @arr1 = "arr-1"; our @arr2 = "arr-2"; my %hash1 = qw(hash 1); our %hash2 = qw(hash 2); my $coderef = sub { "code-ref: @_" }; {package My; sub Func{"My-Func"} sub Func2{"My-Func2"}} my $obj = bless {}, "My"; eval run; say $@'

=head1 DESCRIPTION

"What? Another debugger? What about ... ?"

=head2 perl5db.pl

The standard perl debugger (C<perl5db.pl>) is a powerful tool.

Using C<per5db.pl>, one would normally be able to do this:

    # Insert a breakpoint in your code:
    $DB::single = 1;

    # Then run the perl debugger to navigate there quickly:
    PERLDBOPT='Nonstop' perl -d my_script

If that works for you, then dont' bother with this module!
(joke. still try it.)

=head2 Devel::REPL

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

=head2 Reply

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

=head2 Dilemma

I have this scenario:

 - A perl script gets executed.
 - The script calls a support module.
 - The module reads a test file.
 - The module string evals the string contents of the test file.
 - The test takes possibly minutes to run (Selenium).
 - The test is failing.
 - Not sure what is failing.

Normal workflow would be:

 - Step 1: Apply a fix.
 - Step 2: Run the test.
 - Step 3: Wait ... wait ... wait.
 - Step 4: Go to step 1 if test still fails.

=head2 Solution

This module basically inserts a read, evaluate, print loop (REPL)
wherever you need it.

    use Runtime::Debugger;
    eval run;

=head2 Tab Completion

This module has rich, DWIM tab completion support:

 - Press TAB with no input to view commands and available variables in the current scope.
 - Press TAB after an arrow ("->") to auto append either a "{" or "[" or "(".
    This depends on the type of variable before it.
 - Press TAB after a hash (or hash object) to list available keys. 
 - Press TAB anywhere else to list variables.

=head2 History

All commands run in the debugger are saved locally and loaded next time the module is loaded.

=head2 Data::Dumper

You can use "p" as a print command which can show a simple or complex data structure.

=head2 Ideas

Not sure how to avoid using eval here while keeping access to the top level lexical scope.

(Maybe through abuse of PadWalker and modifying input dynamically.)

Any ideas ? :)

=head2 New Variables

Currently it is not possible to create new lexicals (my) variables.

I have not yet found a way to run "eval" with a higher scope of lexicals.
(perhaps there is another way?)

You can make global variables though if:

 - By default ($var=123)
 - Using our (our $var=123)
 - Given the full path ($My::var = 123)

=head1 SUBROUTINES/METHODS

=cut

# Initialize

=head2 import

Updates the import list to disable source filtering if needed.

It appears that a source filter cannot process a one-liner :(

=cut

sub import {
    my ( $class, @args_raw ) = @_;
    my @args;

    # Source filters do not seem to work with one-liners.
    # Should manually invoke "eval run".
    if ( $0 eq "-e" ) {
        $FILTER = 0;
    }

    for my $arg ( @args_raw ) {
        if ( $arg eq "-nofilter" ) {
            $FILTER = 0;
            next;
        }
        push @args, $arg;
    }

    $class->export_to_level( 1, $class, @args );
}

FILTER {
    if ( $FILTER ) {
        $_ = run() . $_;
    }
};

=head2 run

Runs the REPL (dont forget eval!)

 eval run

Sets C<$@> to the exit reason like 'INT' (Control-C) or 'q' (Normal exit/quit).

=cut

sub run {
    <<'CODE';
    use strict;
    use warnings;
    use feature qw(say);
    my $repl = Runtime::Debugger->_init;
    eval {
        while ( 1 ) {
            eval $repl->_step;
            $repl->_show_error($@) if $@;
        }
    };
    $repl->_show_error($@) if $@;
CODE
}

sub _init {
    my ( $class ) = @_;

    # Setup the terminal.
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
        history_file => "$ENV{HOME}/.runtime_debugger.info",
        term         => $term,
        attr         => $attribs,
        debug        => $ENV{RUNTIME_DEBUGGER_DEBUG} // 0,
    }, $class;

    # https://metacpan.org/pod/Term::ReadLine::Gnu#Custom-Completion
    # Definition for list_completion_function is here: Term/ReadLine/Gnu/XS.pm
    $attribs->{attempted_completion_function} = sub { $self->_complete( @_ ) };

    $self->_restore_history;

    # Setup some signal handling.
    for my $signal ( qw( INT TERM HUP ) ) {
        $SIG{$signal} = sub { $self->_exit( $signal ) };
    }

    $self;
}

sub _step {
    my ( $self ) = @_;

    if ( not $self->{vars_all} ) {
        $self->_setup_vars;
        $self->help;    # Show help when first loading the debugger.
    }

    my $input = $self->term->readline( "perl>" ) // '';
    say "input_after_readline=[$input]" if $self->debug;

    # Change '#1' to '--maxdepth=1'
    if ( $input =~ / ^ p\b /x ) {
        $input =~ s/
            \s*
            \#(\d)     #2 to --maxdepth=2
            \s*
        $ /, '--maxdepth=$1'/x;
    }

    # Change "COMMAND ARG" to "$repl->COMMAND(ARG)".
    $input =~ s/ ^
        (
              help
            | hist
        ) \b
        (.*)
    $ /\$repl->$1($2)/x;

    $self->_exit( $input ) if $input eq 'q';

    say "input_after_step=[$input]" if $self->debug;
    $input;
}

# Completion

sub _complete {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    say ""                  if $self->debug;
    $self->_dump_args( @_ ) if $self->debug;

    # Note: return list is what will be shown as possiblities.

    # Empty - show commands and variables.
    return $self->_complete_empty( @_ ) if $line =~ / ^ \s* $ /x;

    # Help or History command - complete the word.
    return $self->_complete_h( @_ ) if $line =~ / ^ \s* h \w* $ /x;

    # Print command - space afterwards.
    return $self->_complete_p( @_ ) if $line =~ / ^ \s* p $ /x;

    # Method call or coderef - append "(".
    return $self->_complete_arrow( "$1", "$2", @_ )
      if $text =~ / ^ ( \$ \S+ ) -> (\S*) $ /x;

    # Hash or hashref - Show possible keys and string variables.
    return $self->_complete_hash( "$1", @_ )
      if substr( $line, 0, $end ) =~ /
        (
            [\$}@%]                 # Variable sigil.
            (?:
                (?!->|\s).)+        # Next if not a -> or space.
        )
        (?:->)?                     # Maybe a ->.
        \{                          # Opening brace.
        [^}]*                       # Any non braces.
    $ /x;

    # Otherwise assume its a variable.
    return $self->_complete_vars( @_ );
}

sub _complete_empty {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug;

    $self->_match(
        words   => $self->{commands_and_vars_all},
        partial => $text,
    );
}

sub _complete_h {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug;

    $self->_match(
        partial => $text,
        words   => [ "help", "hist" ],
        nospace => 1,
    );
}

sub _complete_p {
    my $self = shift;
    my ( $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug;

    $self->_match( words => ["p"] );
}

sub _complete_arrow {
    my $self = shift;
    my ( $var, $partial_method, $text, $line, $start, $end ) = @_;
    my $ref = $self->{peek_all}->{$var} // "";
    $partial_method //= '';
    $self->_dump_args( @_ ) if $self->debug;
    say "ref: $ref"         if $self->debug;

    return if ref( $ref ) ne "REF";    # Coderef or object.

    # Object call or coderef.
    my $obj_or_coderef = $$ref;

    # Object.
    if ( blessed( $obj_or_coderef ) ) {
        say "IS_OBJECT: $obj_or_coderef" if $self->debug;

        my $methods = $self->{methods}{$obj_or_coderef};
        if ( not $methods ) {
            $methods = $self->_get_object_functions( $obj_or_coderef );
            $self->{methods}{$obj_or_coderef} = $methods;

            # push @$methods, "(";    # Access as method or hash refs.
            push @$methods, "{" if reftype( $obj_or_coderef ) eq "HASH";
            push @$methods, @{ $self->{vars_string} };
            @$methods = uniq sort @$methods;
        }
        say "methods: @$methods" if $self->debug;

        return $self->_match(
            words   => $methods,
            partial => $partial_method,
            prepend => "$var->",
            nospace => 1,
        );
    }

    # Coderef.
    if ( ref( $obj_or_coderef ) eq "CODE" ) {
        say "IS_CODE: $obj_or_coderef" if $self->debug;
        return $self->_match(
            words   => ["("],
            prepend => "$text",
            nospace => 1,
        );
    }

    # Hashref.
    if ( ref( $obj_or_coderef ) eq "HASH" ) {
        say "IS_HASH $obj_or_coderef" if $self->debug;
        return $self->_match(
            words   => ["{"],
            prepend => "$text",
            nospace => 1,
        );
    }

    # Arrayref.
    if ( ref( $obj_or_coderef ) eq "ARRAY" ) {
        say "IS_ARRAY: $obj_or_coderef" if $self->debug;
        return $self->_match(
            words   => ["["],
            prepend => "$text",
            nospace => 1,
        );
    }

    say "NOT OBJECT or CODEREF: $obj_or_coderef" if $self->debug;
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

sub _complete_hash {
    my $self = shift;
    my ( $var, $text, $line, $start, $end ) = @_;
    $self->_dump_args( @_ ) if $self->debug;

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
    $self->_dump_args( @_ ) if $self->debug;

    $self->_match(
        words   => $self->{vars_all},
        partial => $text,
        nospace => 1,
    );
}

=head2 _match

Returns the possible matches:

Input:

 words   => ARRAYREF, # What to look for.
 partial => STRING,   # Default: ""  - What you typed so far.
 prepend => "STRING", # Default: ""  - prepend to each possiblity.
 nospace => 0,        # Default: "0" - will not append a space after a completion.

=cut

sub _match {
    my $self  = shift;
    my %parms = @_;
    $self->_dump_args( @_ ) if $self->debug;

    # completion_word does not automationally get reset per call.
    # completion_suppress_append gets reset perl call.
    # attempted_completion_over gets reset perl call.
    $parms{partial} //= "";
    $parms{prepend} //= "";
    $self->attr->{completion_word}            = $parms{words};
    $self->attr->{completion_suppress_append} = 1 if $parms{nospace};
    $self->attr->{attempted_completion_over} =
      1;    # Will not use filename completion at all.

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
        "p",       # Exporting it.
        "q",       # Used in _step to stop the repl.
    );
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

    my $levels       = 3;    # How many levels until at "$repl=" or main.
    my $peek_my      = peek_my( $levels );
    my $peek_our     = peek_our( $levels );
    my %peek_all     = ( %$peek_our, %$peek_my );
    my @vars_lexical = keys %$peek_my;
    my @vars_global  = keys %$peek_our;
    my @vars_all     = uniq @vars_lexical, @vars_global;

    $self->{peek_my}      = $peek_my;
    $self->{peek_our}     = $peek_our;
    $self->{peek_all}     = \%peek_all;
    $self->{vars_lexical} = \@vars_lexical;
    $self->{vars_global}  = \@vars_global;
    $self->{vars_all}     = \@vars_all;
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
            if ( $self->debug or not $added_duplicates{$_} ) {
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

            say "Added $_: $var_scalar" if $self->debug;
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

            say "Added $_: $var_scalar, $var_array" if $self->debug;
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

 <TAB>       - Show options.
 help        - Show this help section.
 hist [N=20] - Show last N commands.
 p DATA [#N] - Prety print data (with optional depth),
 q           - Quit debugger.
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

=head2 hist

Show history of commands.

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
        open my $fh, '<', $self->{history_file} or die $!;
        while ( <$fh> ) {
            chomp;
            push @history, $_;
        }
        close $fh;
    }

    @history = ( "q" ) if not @history;    # avoid blank history.
    $self->_history( @history );
}

sub _save_history {
    my ( $self ) = @_;

    # Save current history.
    open my $fh, '>', $self->{history_file} or die $!;
    say $fh $_ for $self->_history;
    close $fh;
}

# Print

=head2 p

Data::Dumper::Dump anything.

 p 123
 p [1, 2, 3]

Can adjust the maxdepth (default is 1) to see with: "#Number".

 p { a => [1, 2, 3] } #1

Output:

 {
   'a' => 'ARRAY(0x55fd914a3d80)'
 }

Set maxdepth to '0' to show all nested structures.

=cut

sub p {

    # Use same function to change maxdepth of whats shown.
    my $maxdepth =
      1;    # Good default to often having to change it during display.
    if ( @_ > 1 and $_[-1] =~ / ^ --maxdepth=(\d+) $ /x )
    {       # Like with "tree" command.
        $maxdepth = $1;
        pop @_;
    }

    my $d = Data::Dumper
      ->new( \@_ )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Terse( 1 )
      ->Useqq( 1 )
      ->Maxdepth( $maxdepth );

    return $d->Dump if wantarray;
    print $d->Dump;
}

# List Utils.

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

=head2 attr

Internal use.

=head2 debug

Internal use.

=head2 term

Internal use.

=head1 ENVIRONMENT

Install required library:

 sudo apt install libreadline-dev

Enable this environmental variable to show debugging information:

 RUNTIME_DEBUGGER_DEBUG=1

=head1 SEE ALSO

=head2 L<https://perldoc.perl.org/perldebug>

L<Why not perl debugger?|/perl5db.pl>

=head2 L<https://metacpan.org/pod/Devel::REPL>

L<Why not Devel::REPL?|/Devel::REPL>

=head2 L<https://metacpan.org/pod/Reply>

L<Why not Reply?|/Reply>

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >> E<0x1f42a>E<0x1f977>

=head1 BUGS

- L<no new lexicals|/New Variables>

Please report any (other) bugs or feature requests to L<https://github.com/poti1/runtime-debugger/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Runtime::Debugger


You can also look for information at:

L<https://metacpan.org/pod/Runtime::Debugger>
L<https://github.com/poti1/runtime-debugger>


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

"\x{1f42a}\x{1f977}"
