#!perl

package MyObj;

sub Func1 { "My-Func1" }
sub Func2 { "My-Func2" }


package MyTest;

use 5.006;
use strict;
use warnings;
use Test::More tests => 73;
use Runtime::Debugger -nofilter;
use Term::ANSIColor qw( colorstrip );
use feature         qw( say );

#
# Test variables.
#

# Lexical variables.
my $my_str      = "Func1";
my @my_array    = "array-my";
my $my_arrayref = ["array-my"];
my %my_hash     = ( key1 => "a", key2 => "b", key3 => { key3b => "val" } );
my $my_hashref  = {qw(key1 a key2 b)};
my $my_coderef  = sub { "coderef-my: @_" };
my $my_obj      = bless { type => "my" }, "MyObj";

# Global variables.
our $our_str      = "Func2";
our @our_array    = "array-our";
our $our_arrayref = ["array-our"];
our %our_hash     = qw(key11 aa key22 bb);
our $our_hashref  = {qw(key11 aa key22 bb)};
our $our_coderef  = sub { "coderef-our: @_" };
our $our_obj      = bless { type => "our" }, "MyObj";

#eval run; exit;

my $INSTR;                # Simulated input string.
my $COMPLETION_RETURN;    # Possible completions.
my $repl = MyTest->_setup_testmode_debugger();

sub _setup_testmode_debugger {

    my $_repl = Runtime::Debugger->_init; # Scope recorded during first "_step".
    $Runtime::Debugger::VERSION = "0.01";  # To make testing the version easier.

    # Use a separate history file.
    my $history_file = "$ENV{HOME}/.runtime_debugger_testmode.info";
    unlink $history_file if -e $history_file;
    $_repl->{history_file} = $history_file;
    $_repl->_restore_history;

    # Avoiding the use of getc for testing.
    $_repl->attr->{getc_function} = sub {
        return 0 if not $INSTR;
        my $char;
        ( $char, $INSTR ) = $INSTR =~ / ^ (.) (.*) $ /x;
        ord $char;
    };

    # Wrapper arround the main completion function to capture
    # the results from "_complete".
    # (Its a bit tricky to capture the completions).
    $_repl->attr->{attempted_completion_function} = sub {
        my ( $text, @possible ) = $_repl->_complete( @_ );
        $COMPLETION_RETURN = [@possible];    # Save possible completions.
        ( $text, @possible );    # Return like normally would happen.
    };

    # Do not show prompt messages.
    open my $NULL, ">", "/dev/null" or die $!;
    $_repl->attr->{outstream} = $NULL;

    $_repl;
}

sub _define_expected_vars {
    my ( $_repl ) = @_;

    {
        commands              => [ 'd', 'help', 'hist', 'p', 'q' ],
        commands_and_vars_all => [
            '$COMPLETION_RETURN', '$EOL',
            '$INSTR',             '$_repl',
            '$case',              '$eval_return',
            '$my_array',          '$my_arrayref',
            '$my_coderef',        '$my_hash',
            '$my_hashref',        '$my_obj',
            '$my_str',            '$our_array',
            '$our_arrayref',      '$our_coderef',
            '$our_hash',          '$our_hashref',
            '$our_obj',           '$our_str',
            '$repl',              '$stdin',
            '$stdout',            '$step_return',
            '%my_hash',           '%our_hash',
            '@my_array',          '@my_hash',
            '@our_array',         '@our_hash',
            'd',                  'help',
            'hist',               'p',
            'q',
        ],
        debug        => 0,
        history_file => "$ENV{HOME}/.runtime_debugger_testmode.info",
        vars_all     => [
            '$COMPLETION_RETURN', '$EOL',
            '$INSTR',             '$_repl',
            '$case',              '$eval_return',
            '$my_array',          '$my_arrayref',
            '$my_coderef',        '$my_hash',
            '$my_hashref',        '$my_obj',
            '$my_str',            '$our_array',
            '$our_arrayref',      '$our_coderef',
            '$our_hash',          '$our_hashref',
            '$our_obj',           '$our_str',
            '$repl',              '$stdin',
            '$stdout',            '$step_return',
            '%my_hash',           '%our_hash',
            '@my_array',          '@my_hash',
            '@our_array',         '@our_hash'
        ],
        vars_array    => [ '@my_array', '@my_hash', '@our_array', '@our_hash' ],
        vars_arrayref =>
          [ '$COMPLETION_RETURN', '$my_arrayref', '$our_arrayref' ],
        vars_code   => [ '$my_coderef', '$our_coderef' ],
        vars_global => [
            '$our_arrayref', '$our_coderef', '$our_hashref', '$our_obj',
            '$our_str',      '%our_hash',    '@our_array'
        ],
        vars_hash    => [ '%my_hash', '%our_hash' ],
        vars_hashref => [ '$case',    '$my_hashref', '$our_hashref' ],
        vars_lexical => [
            '$COMPLETION_RETURN', '$EOL',
            '$INSTR',             '$_repl',
            '$case',              '$eval_return',
            '$my_arrayref',       '$my_coderef',
            '$my_hashref',        '$my_obj',
            '$my_str',            '$repl',
            '$stdin',             '$stdout',
            '$step_return',       '%my_hash',
            '@my_array'
        ],


        vars_obj => [ '$_repl', '$my_obj', '$our_obj', '$repl' ],
        vars_ref => [
            '$COMPLETION_RETURN', '$_repl',
            '$case',              '$my_arrayref',
            '$my_coderef',        '$my_hashref',
            '$my_obj',            '$our_arrayref',
            '$our_coderef',       '$our_hashref',
            '$our_obj',           '$repl'
        ],
        vars_ref_else => [],
        vars_scalar   => [
            '$COMPLETION_RETURN', '$EOL',
            '$INSTR',             '$_repl',
            '$case',              '$eval_return',
            '$my_array',          '$my_arrayref',
            '$my_coderef',        '$my_hash',
            '$my_hashref',        '$my_obj',
            '$my_str',            '$our_array',
            '$our_arrayref',      '$our_coderef',
            '$our_hash',          '$our_hashref',
            '$our_obj',           '$our_str',
            '$repl',              '$stdin',
            '$stdout',            '$step_return'
        ],
        vars_string => [
            '$EOL',     '$INSTR', '$eval_return', '$my_str',
            '$our_str', '$stdin', '$stdout',      '$step_return'
        ],
    };
}

sub _define_help_stdout {
    [
        '',
        ' Runtime::Debugger 0.01',
        '',
        ' <TAB>       - Show options.',
        ' help        - Show this help section.',
        ' hist [N=20] - Show last N commands.',
        ' p VAR       - Data printer.',
        ' d DATA [#N] - Data dumper (with optional depth).',
        ' q           - Quit debugger.',
        ''
    ]
}

sub _define_test_cases {
    my ( $_repl ) = @_;

    # Special keyboard mappings.
    my $TAB = "\cI";    # Add to string to autocomplete.
    my $TAB_ALL =
      "\cI\e*";         # Add to string to autocomplete plus insert all matches.
                        # This calls "_complete" multiple times.

    my @cases = (

# # This should be enough data to test the module.
# {
#     name             => 'STRING',
#     input            => 'STRING',
#     nocolor          => ARRAYREF, # Keys of values from results to strip colors.
#     expected_results => {
#         stdin  => 'STRING', # Input.
#         comp   => ARRAYREF, # Result of tab completion
#                             # (empty if no TAB or only a single choice).
#         line   => 'STRING', # Line after "_step", but before "eval".
#         eval   => 'STRING', # Evaled line.
#         stdout => ARRAYREF, # Result of print split by newlines.
#     },
#     todo       => INT,      # Default: 0 (Mark the case as not ready).
#     debug      => INT,      # Default: 0 (Enable debugging for one case).
# },

        # Literal.
        {
            name             => 'simple line 1',
            input            => 'abc',
            expected_results => {
                line   => 'abc',
                stdout => [],
            }
        },
        {
            name             => 'simple line 2',
            input            => 'abc2',
            expected_results => {
                line   => 'abc2',
                stdout => [],
            }
        },

        # History - Do these first so case order wont matter for others.
        {
            name             => 'History - default lines',
            input            => 'hist',
            nocolor          => ["stdout"],
            expected_results => {
                stdout => [ '1 q', '2 abc', '3 abc2', '4 hist', ],
            },
        },
        {
            name             => 'History - explicit line to show',
            input            => 'hist 3',
            nocolor          => ["stdout"],
            expected_results => {
                stdout => [ '3 abc2', '4 hist', '5 hist 3' ],
            },
        },
        {
            name             => 'History - complete the command "h"',
            input            => 'h' . $TAB,
            expected_results => {
                comp   => [ "help", "hist" ],
                stdout => [],
            },
        },
        {
            name             => 'History - complete the command "hi"',
            input            => 'hi' . $TAB,
            nocolor          => ["stdout"],
            expected_results => {
                comp   => [],
                line   => '$repl->hist()',
                stdout =>
                  [ '1 q', '2 abc', '3 abc2', '4 hist 3', '5 h', '6 hist' ],
            },
        },

        # Empty.
        {
            name             => 'Empty',
            input            => '',
            expected_results => {
                line   => '',
                stdout => [],
            },
        },
        {
            name             => 'Empty TAB completion',
            input            => $TAB,
            expected_results => {
                comp   => $_repl->{commands_and_vars_all},
                stdout => [],
            },
        },

        # Help.
        {
            name             => 'Help',
            input            => 'help',
            nocolor          => ["stdout"],
            expected_results => {
                line   => '$repl->help()',         # "help" changes to this.
                eval   => '1',                     # Return value.
                stdout => _define_help_stdout(),
            },
        },
        {
            name             => 'Help - short "h"',
            input            => 'h',
            expected_results => {
                line   => 'h',
                stdout => [],
            },
        },
        {
            name             => 'Help - short "h<TAB>"',
            input            => 'h' . $TAB,
            expected_results => {
                comp   => [ 'help', 'hist' ],
                line   => 'h',
                stdout => [],
            },
        },

        # Data Dumper.
        {
            name             => 'Dump literal',
            input            => 'd 123',
            expected_results => {
                line   => 'd 123',
                stdout => ['123'],
            },
        },
        {
            name             => 'Dump TAB complete: "d<TAB>"',
            input            => 'd' . $TAB,
            expected_results => {
                line   => 'd ',
                stdout => [],
            },
        },
        {
            name             => 'Dump TAB complete: "d<TAB><TAB"',
            input            => 'd' . $TAB . $TAB,
            expected_results => {
                comp   => $_repl->{vars_all},
                line   => 'd ',
                stdout => [],
            },
        },

        # Dump - TAB complete partial.
        {
            name             => 'Dump TAB complete: "d $<TAB>"',
            input            => 'd $' . $TAB,
            expected_results => {
                comp   => $_repl->{vars_scalar},
                stdout => [],
            },
        },
        {
            name             => 'Dump TAB complete: d $o ',
            input            => 'd $o' . $TAB,
            expected_results => {
                comp   => [ grep { / ^ \$o /x } @{ $_repl->{vars_all} } ],
                stdout => [],
            },
        },
        {
            name  => 'Dump TAB complete: d $o<TAB>_ ',
            input => 'd $o' . $TAB . '_',    # Does not expand after tab.
            expected_results => {
                comp   => [ grep { / ^ \$o /x } @{ $_repl->{vars_all} } ],
                stdout => [],
            },
        },
        {
            name             => 'Dump TAB complete: d $<TAB>_str ',
            input            => 'd $o' . $TAB . '_str',
            expected_results => {
                comp   => [ grep { / ^ \$o /x } @{ $_repl->{vars_all} } ],
                stdout => [],
            },
        },
        {
            name             => 'Dump TAB complete: "d $my_<TAB> . $our_str"',
            input            => 'd $my_' . $TAB . ' . $our_str',
            expected_results => {
                comp   => [ grep { / ^ \$my_ /x } @{ $_repl->{vars_all} } ],
                line   => 'd $my_ . $our_str',
                stdout => [],
            },
        },
        {
            name             => 'Dump TAB complete: "d $my_s<TAB> . $our_str"',
            input            => 'd $my_s' . $TAB . ' . $our_str',
            expected_results => {
                line   => 'd $my_str . $our_str',
                stdout => [ '"' . $my_str . $our_str . '"' ],
            },
        },


        #
        # Scalars.
        #

        # All scalars.
        {
            name             => 'Complete scalar - "$"',
            input            => '$' . $TAB,
            expected_results => {
                comp => $_repl->{vars_scalar},
            },
        },


        #
        # Coderefs.
        #

        # TAB after coderef arrow.
        {
            name             => 'TAB after coderef arrow "$my_coderef->"',
            input            => '$my_coderef->' . $TAB,
            expected_results => {
                line   => '$my_coderef->(',
                stdout => [],
            },
        },
        {
            name             => 'TAB after coderef arrow "$our_coderef->"',
            input            => '$our_coderef->' . $TAB,
            expected_results => {
                line   => '$our_coderef->(',
                stdout => [],
            },
        },
        {
            name =>
              'TAB after coderef arrow - "$my_coderef->" before closing ")"',
            input            => '$my_coderef->' . $TAB . ')',
            expected_results => {
                line   => '$my_coderef->()',
                stdout => [],
            },
        },
        {
            name =>
              'TAB after coderef arrow - "$our_coderef->" before closing ")"',
            input            => '$our_coderef->' . $TAB . ')',
            expected_results => {
                line   => '$our_coderef->()',
                stdout => [],
            },
        },


        #
        # Methods.
        #

        # TAB after method call arrow.
        {
            name             => 'TAB after method call arrow - "$my_obj->"',
            input            => '$my_obj->' . $TAB,
            expected_results => {
                comp => [
                    sort map { '$my_obj->' . $_ } @{ $_repl->{vars_string} },
                    qw( Func1 Func2 { )
                ],
                line   => '$my_obj->',
                stdout => [],
            },
        },
        {
            name             => 'TAB after method call arrow - "$our_obj->"',
            input            => '$our_obj->' . $TAB,
            expected_results => {
                comp => [
                    sort map { '$our_obj->' . $_ } @{ $_repl->{vars_string} },
                    qw( Func1 Func2 { )
                ],
                line   => '$our_obj->',
                stdout => [],
            },
        },
        {
            name =>
              'TAB after method call arrow - "$my_obj->" before closing ")"',
            input            => '$my_obj->' . $TAB . ')',
            expected_results => {
                comp => [
                    sort map { '$my_obj->' . $_ } @{ $_repl->{vars_string} },
                    qw( Func1 Func2 { )
                ],
                line   => '$my_obj->)',
                stdout => [],
            },
        },
        {
            name =>
              'TAB after method call arrow - "$our_obj->" before closing ")"',
            input            => '$our_obj->' . $TAB . ')',
            expected_results => {
                comp => [
                    sort map { '$our_obj->' . $_ } @{ $_repl->{vars_string} },
                    qw( Func1 Func2 { )
                ],
                line   => '$our_obj->)',
                stdout => [],
            },
        },


        #
        # Arrays
        #

        # All arrays.
        {
            name             => 'Complete array - "@""',
            input            => '@' . $TAB,
            expected_results => {
                comp => $_repl->{vars_array},
            },
        },

        # Complete an array with a "$" or "@" sigil
        {
            name             => 'Complete array - "$my_array"',
            input            => '$my_array' . $TAB,
            expected_results => {
                comp => [ '$my_array', '$my_arrayref' ],
            },
        },
        {
            name             => 'Complete array - "$our_array"',
            input            => '$our_array' . $TAB,
            expected_results => {
                comp => [ '$our_array', '$our_arrayref' ],
            },
        },
        {
            name             => 'Complete array - "@my_arr"',
            input            => '@my_arr' . $TAB,
            expected_results => {
                line => '@my_array',
            },
        },
        {
            name             => 'Complete array - "@our_arr"',
            input            => '@our_arr' . $TAB,
            expected_results => {
                line => '@our_array',
            },
        },

        # TAB after arrayref arrow.
        {
            name             => 'TAB after arrayref arrow "$my_arrayref->"',
            input            => '$my_arrayref->' . $TAB,
            expected_results => {
                line   => '$my_arrayref->[',
                stdout => [],
            },
        },
        {
            name             => 'TAB after arrayref arrow "$our_arrayref->"',
            input            => '$our_arrayref->' . $TAB,
            expected_results => {
                line   => '$our_arrayref->[',
                stdout => [],
            },
        },

        # TAB after arrayref arrow and bracket.
        {
            name  => 'TAB after arrayref arrow and bracket - "$my_arrayref->["',
            input => '$my_arrayref->[' . $TAB,
            expected_results => {
                comp   => $_repl->{vars_all},
                line   => '$my_arrayref->[',
                stdout => [],
            },
        },
        {
            name => 'TAB after arrayref arrow and bracket - "$our_arrayref->["',
            input            => '$our_arrayref->[' . $TAB,
            expected_results => {
                comp   => $_repl->{vars_all},
                line   => '$our_arrayref->[',
                stdout => [],
            },
        },

        # Can update an array.
        {
            name  => 'Can update an array - add element',
            input => 'push @my_array, qw( elem1 elem2 ); d \@my_array',
            expected_results => {
                'stdout' =>
                  [ '[', '  "array-my",', '  "elem1",', '  "elem2"', ']' ]
            },
        },
        {
            name             => 'Can update an array - remove element',
            input            => 'shift @my_array; d \@my_array',
            expected_results => {
                'stdout' => [ '[', '  "elem1",', '  "elem2"', ']' ]
            },
        },

        #
        # Hashs.
        #

        # All hashs.
        {
            name             => 'Complete hash - "%""',
            input            => '%' . $TAB,
            expected_results => {
                comp => $_repl->{vars_hash},
            },
        },

        # Complete a hash with a "$" or "@" or "%" sigil
        {
            name             => 'Complete hash - "$my_hash"',
            input            => '$my_hash' . $TAB,
            expected_results => {
                comp => [ '$my_hash', '$my_hashref' ],
            },
        },
        {
            name             => 'Complete hash - "$our_hash"',
            input            => '$our_hash' . $TAB,
            expected_results => {
                comp => [ '$our_hash', '$our_hashref' ],
            },
        },
        {
            name             => 'Complete hash - "@my_ha"',
            input            => '@my_ha' . $TAB,
            expected_results => {
                line => '@my_hash',
            },
        },
        {
            name             => 'Complete hash - "@our_ha"',
            input            => '@our_ha' . $TAB,
            expected_results => {
                line => '@our_hash',
            },
        },
        {
            name             => 'Complete hash - "%my_ha"',
            input            => '%my_ha' . $TAB,
            expected_results => {
                line => '%my_hash',
            },
        },
        {
            name             => 'Complete hash - "%our_ha"',
            input            => '%our_ha' . $TAB,
            expected_results => {
                line => '%our_hash',
            },
        },

        # TAB after after hashref arrow.
        {
            name             => 'TAB after after hashref arrow - "$my->"',
            input            => '$my_hashref->' . $TAB,
            expected_results => {
                line => '$my_hashref->{',
            },
        },
        {
            name             => 'TAB after after hashref arrow - "$our->"',
            input            => '$our_hashref->' . $TAB,
            expected_results => {
                line => '$our_hashref->{',
            },
        },

#       # TAB after after hashref arrow (2nd level).
#       {
#           name             => 'TAB after after hashref arrow (2nd level) - "$my->"',
#           input            => '$my_hashref->{k1}' . $TAB,
#           expected_results => {
#               line => '$my_hashref->{}{',
#           },
#       },

        # TAB after hashref arrow and brace.
        {
            name             => 'TAB after hashref arrow and brace - "$my->{"',
            input            => '$my_hashref->{' . $TAB,
            expected_results => {
                comp => [ sort keys %$my_hashref, @{ $_repl->{vars_string} } ],
                line => '$my_hashref->{',
                stdout => [],
            },
        },
        {
            name             => 'TAB after hashref arrow and brace - "$our->{"',
            input            => '$our_hashref->{' . $TAB,
            expected_results => {
                comp => [ sort keys %$our_hashref, @{ $_repl->{vars_string} } ],
                line => '$our_hashref->{',
                stdout => [],
            },
        },

        # TAB after hash brace (no arrow).
        {
            name             => 'TAB after hash brace (no arrow) - "$my{"',
            input            => '$my_hash{' . $TAB,
            expected_results => {
                comp => [ sort keys %my_hash, @{ $_repl->{vars_string} } ],
                line => '$my_hash{',
            },
        },
        {
            name             => 'TAB after hash brace (no arrow) - "$our{"',
            input            => '$our_hash{' . $TAB,
            expected_results => {
                comp   => [ sort keys %our_hash, @{ $_repl->{vars_string} } ],
                line   => '$our_hash{',
                stdout => [],
            },
        },

# TODO: TAB after hash brace (no arrow), 2nd level.
#  {
#      name             => 'TAB after hash brace (no arrow), 2nd level - "$my{key}{"',
#      input            => '$my_hash{key3}{' . $TAB,
#      expected_results => {
#          comp => [ sort keys %{$my_hash{key3}} ],
#          line => '$my_hash{key3}{',
#      },
#  },

        # Can update a hash.
        {
            name  => 'Can update a hash - add key',
            input => '$my_hash{new_key} = "new_val"; say np %my_hash',
            expected_results => {
                stdout => [
                    '{',
                    '    key1      "a",',
                    '    key2      "b",',
                    '    key3      {',
                    '        key3b   "val"',
                    '    },',
                    '    new_key   "new_val"',
                    '}',
                ],
            },
        },
        {
            name             => 'Can update a hash - remove key',
            input            => 'delete $my_hash{key1}; say np %my_hash',
            expected_results => {
                stdout => [
                    '{',
                    '    key2      "b",',
                    '    key3      {',
                    '        key3b   "val"',
                    '    },',
                    '    new_key   "new_val"',
                    '}',
                ],
            },
        },

    );

    @cases;
}

sub init_case {
    {
        name             => 'Help - upon running _step first time',
        input            => '',
        nocolor          => ["stdout"],
        expected_results => {
            line   => '',
            stdout => _define_help_stdout(),
        },
    };
}

sub _run_case {
    my ( $_repl, $case ) = @_;
    my $stdin = $case->{input} // '';
    my $step_return;
    my $eval_return;
    my $stdout = "";
    my $EOL    = "\cM";    # Append to string to trigger end of line.
    $INSTR             = $stdin . $EOL;
    $COMPLETION_RETURN = [];

    $_repl->debug( 1 ) if $case->{debug};

    # Run while capturing terminal output.
    eval {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$stdout or die $!;
        open STDERR, ">>", \$stdout or die $!;

        $step_return = $repl->_step;
        $eval_return = eval $step_return // "";
        chomp $stdout;
    };
    $_repl->_show_error( $@ ) if $@;    # Probably a developer issue.

    $_repl->debug( 0 ) if $case->{debug};

    # Run the debugger with an input string and capture all the results.
    my $results_all = {
        stdin  => $stdin,
        comp   => $COMPLETION_RETURN,             # All completions.
        line   => $step_return,
        eval   => $eval_return,
        stdout => [ split /\n/, $stdout, -1 ],    # Much easier to debug later.
    };

    # Update the results.
    my $nocolor = $case->{nocolor};
    if ( $nocolor and @$nocolor ) {
        for my $key ( @$nocolor ) {
            my $val = $results_all->{$key};
            my $ref = ref $val;
            if ( $ref eq "SCALAR" ) {
                $results_all->{$key} = colorstrip( $val );
            }
            elsif ( $ref eq "ARRAY" ) {
                $_ = colorstrip( $_ ) for @$val;
            }
            else {
                warn "Cannot apply 'nocolor' due to unsupport type '$ref'\n";
                d $results_all;
            }
        }
    }

    # Limit results to expected_results.
    my %results;
    my $expected_results = $case->{expected_results};
    my @keys             = keys %$expected_results;
    @results{@keys} = @$results_all{@keys};

    # Compare.
    my $fail;
  TODO: {
        local $TODO = $case->{name} if $case->{todo};
        $fail = not is_deeply \%results, $expected_results, $case->{name};
    }

    # Error dump.
    my $last;
    if ( $case->{debug} or ( $fail and !$case->{todo} ) ) {
        say "";
        say "GOT:";
        say explain $results_all;

        say "";
        say "EXPECT:";
        say explain $expected_results;

        $last++;
    }

    $last;
}

sub _test_repl_vars {
    my ( $_repl ) = @_;

    # Test specific repl keys.
    my $expected = _define_expected_vars( $_repl );

    for ( sort keys %$expected ) {
        my $same = is_deeply $_repl->{$_}, $expected->{$_},
          "_repl->{$_} is correct";
        if ( not $same ) {
            say explain "\n$_ => ", $_repl->{$_};
        }
    }
}

_run_case( $repl, init_case() );

for my $case ( _define_test_cases( $repl ) ) {
    last if _run_case( $repl, $case );
}

_test_repl_vars( $repl );

__END__




