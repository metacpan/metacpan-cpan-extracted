#!perl

package MyObj;

package MyTest;

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Runtime::Debugger;
use Term::ANSIColor qw( colorstrip );
use feature         qw( say );

my $repl = Runtime::Debugger->_init;    # Scope recorded during first "_step".
my $INSTR;                              # Simulated input string.
my $COMPLETION_RETURN;                  # Possible completions.

MyTest->_setup_testmode_debugger( $repl );

sub _setup_testmode_debugger {
    my ( $self, $_repl ) = @_;

    $Runtime::Debugger::VERSION = "0.01";  # To make testing the version easier.

    # Use a separate history file.
    my $history_file = "$ENV{HOME}/.runtime_debugger_testmode.info";
    open my $fh, ">", $history_file or die $!;
    close $fh;
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

sub _define_help_stdout {
    [
        '',
        ' Runtime::Debugger 0.01',
        '',
        ' <TAB>          - Show options.',
        ' <Up/Down>      - Scroll history.',
        ' help           - Show this section.',
        ' hist [N=5]     - Show last N commands.',
        ' p DATA         - Data printer (colored).',
        ' d DATA         - Data dumper.',
        ' dd DATA, [N=3] - Dump internals (with depth).',
        ' q              - Quit debugger.',
        ''
    ]
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

    $_repl->debug( 2 ) if $case->{debug};

    # Run while capturing terminal output.
    eval {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$stdout or die $!;
        open STDERR, ">>", \$stdout or die $!;

        $step_return = $repl->_build_step;
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

_run_case( $repl, init_case() );

