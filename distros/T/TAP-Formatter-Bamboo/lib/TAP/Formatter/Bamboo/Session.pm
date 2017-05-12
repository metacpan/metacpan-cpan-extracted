package TAP::Formatter::Bamboo::Session;

use Moose;
use MooseX::NonMoose;
extends qw(
    TAP::Formatter::Console::Session
);

has '_output' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

sub _initialize {
    my ($self, $arg_for) = @_;
    $arg_for ||= {};

    return $self->SUPER::_initialize($arg_for);
}

sub result {
    my ($self, $result) = @_;
    $self->_output( $self->_output . $result->raw() . "\n" );
}

sub close_test {
    my $self   = shift;
    my $parser = $self->parser;

    my $results = {
        description => $self->name,
        start_time => $parser->start_time,
        end_time => $parser->end_time,
        tests_run => $parser->tests_run,
        failed => scalar($parser->failed),
        parse_errors => scalar($parser->parse_errors),
        output => $self->_output,
    };

    my @fail_reasons = _fail_reasons($parser);
    if(@fail_reasons) {
        $results->{fail_reasons} = \@fail_reasons;
        print STDERR "FAIL " . $self->name . "\n" .
            join("", map { "    $_\n" } @fail_reasons);
    }
    else {
        print { $self->formatter->stdout } "PASS " . $self->name . "\n";
    }

    push(@{$self->formatter->_test_results}, $results);
}

sub _fail_reasons {
    my( $parser ) = @_;

    my @reasons = ();
    if( $parser->failed ) {
        push(@reasons, "failed tests (" . join( ', ', $parser->failed ) . ")");
    }
    if( $parser->todo_passed ) {
        push(@reasons, "unexpected TODO passed (" . join( ', ', $parser->todo_passed ) . ")");
    }
    if( $parser->parse_errors ) {
        push(@reasons, "parse errors (" . join( ', ', $parser->parse_errors ) . ")");
    }
    if( !@reasons && $parser->exit != 0) {
        push(@reasons, "non-zero exit code (" . $parser->exit . ")");
    }

    if( !@reasons && $parser->has_problems ) {
        push(@reasons, "unknown reason (probably some bug encountered)");
    }

    return @reasons;
}

1;
