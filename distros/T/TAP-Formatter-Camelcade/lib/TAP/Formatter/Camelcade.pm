package TAP::Formatter::Camelcade;
use strict;
use warnings FATAL => 'all';
use base 'TAP::Formatter::Base';
use TAP::Formatter::Camelcade::Session;
use TAP::Formatter::Camelcade::MessageBuilder;
use Cwd;

our $VERSION = '0.003';

sub open_test{
    my ( $self, $test, $parser ) = @_;

    my $pwd = getcwd;

    my $location = "myfile://$test";
    $test =~ s/^$pwd[\\\/]//;

    my $session = TAP::Formatter::Camelcade::Session->new({
        name      => $test,
        formatter => $self,
        parser    => $parser,
        location  => $location
    });

    $session->header;

    return $session;
}

#@returns TAP::Formatter::Camelcade::MessageBuilder
sub builder{
    return 'TAP::Formatter::Camelcade::MessageBuilder';
}

sub _should_show_count {
    return 0;
}

#@override
sub _initialize {
    my ($self, $arg_for) = @_;
    builder->test_reporter_attached->print;
    $self->SUPER::_initialize($arg_for);
}

#@override
sub prepare {
    my ($self, @tests) = @_;
    $self->SUPER::prepare(@tests);
    builder->testing_started;
}

#@override
sub summary {
    my ($self, $aggregate, $interrupted) = @_;
    if( $ENV{TAP_FORMATTER_CAMELCADE_TIME} ){
        $self->_test_summary($aggregate, $interrupted);
    }
    else{
        $self->SUPER::summary($aggregate, $interrupted);
    }
    builder->testing_finished;
}

my $MAX_ERRORS = 5;

sub _test_summary{
    my ($self,
        #@type TAP::Parser::Aggregator
        $aggregate, $interrupted) = @_;
    my @t     = $aggregate->descriptions;
    my $tests = \@t;

    my $runtime = 'TEST_MODE_STATS;'; # $aggregate->elapsed_timestr;

    my $total  = $aggregate->total;
    my $passed = $aggregate->passed;

    # if ( $self->timer ) {
    #     $self->_output( $self->_format_now(), "\n" );
    # }

    $self->_failure_output("Test run interrupted!\n")
        if $interrupted;

    # TODO: Check this condition still works when all subtests pass but
    # the exit status is nonzero

    if ( $aggregate->all_passed ) {
        $self->_output_success("All tests successful.\n");
    }

    # ~TODO option where $aggregate->skipped generates reports
    if ( $total != $passed or $aggregate->has_problems ) {
        $self->_output("\nTest Summary Report");
        $self->_output("\n-------------------\n");
        for my $test (@$tests) {
            $self->_printed_summary_header(0);
            my ($parser) = $aggregate->parsers($test);
            $self->_output_summary_failure(
                'failed',
                [ '  Failed test:  ', '  Failed tests:  ' ],
                $test, $parser
            );
            $self->_output_summary_failure(
                'todo_passed',
                "  TODO passed:   ", $test, $parser
            );

            # ~TODO this cannot be the default
            #$self->_output_summary_failure( 'skipped', "  Tests skipped: " );

            if ( my $exit = $parser->exit ) {
                $self->_summary_test_header( $test, $parser );
                $self->_failure_output("  Non-zero exit status: $exit\n");
            }
            elsif ( my $wait = $parser->wait ) {
                $self->_summary_test_header( $test, $parser );
                $self->_failure_output("  Non-zero wait status: $wait\n");
            }

            if ( my @errors = $parser->parse_errors ) {
                my $explain;
                if ( @errors > $MAX_ERRORS && !$self->errors ) {
                    $explain
                        = "Displayed the first $MAX_ERRORS of "
                        . scalar(@errors)
                        . " TAP syntax errors.\n"
                        . "Re-run prove with the -p option to see them all.\n";
                    splice @errors, $MAX_ERRORS;
                }
                $self->_summary_test_header( $test, $parser );
                $self->_failure_output(
                    sprintf "  Parse errors: %s\n",
                        shift @errors
                );
                for my $error (@errors) {
                    my $spaces = ' ' x 16;
                    $self->_failure_output("$spaces$error\n");
                }
                $self->_failure_output($explain) if $explain;
            }
        }
    }
    my $files = @$tests;
    $self->_output("Files=$files, Tests=$total, $runtime\n");
    my $status = $aggregate->get_status;
    $self->_output("Result: $status\n");
}

1;

# ABSTRACT: Converts test events from TAP::Harness to the TeamCity format