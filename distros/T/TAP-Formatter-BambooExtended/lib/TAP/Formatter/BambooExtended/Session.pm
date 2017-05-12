package TAP::Formatter::BambooExtended::Session;

use strict;
use warnings;

use parent qw(TAP::Formatter::Console::Session);

use TAP::Parser::ResultFactory ();

our $VERSION = '1.01';

sub _initialize {
    my ($self, $arg_for) = @_;

    # variables that we use for ourselves
    $self->{'_results'} = [];

    return $self->SUPER::_initialize($arg_for || {});
}

sub result {
    my ($self, $result) = @_;
    push(@{$self->{'_results'}}, $result);
    return;
}

sub close_test {
    my $self = shift;
    my $parser = $self->parser();

    my $results = {
        'description'  => $self->name(),
        'start_time'   => $parser->start_time(),
        'end_time'     => $parser->end_time(),
        'tests_run'    => $parser->tests_run(),
        'failed'       => scalar($parser->failed()),
        'parse_errors' => scalar($parser->parse_errors()),
        'results'      => $self->{'_results'},
    };

    my @fail_reasons = _fail_reasons($parser);
    if (@fail_reasons) {
        print STDERR "FAIL " . $self->name() . "\n" .  join("", map { "    $_\n" } @fail_reasons);
    } else {
        print { $self->formatter->stdout() } "PASS " . $self->name() . "\n";
    }

    my $is_ok = (scalar(@fail_reasons) ? 'not ok' : 'ok');
    unshift(@{$self->{'_results'}}, TAP::Parser::ResultFactory->make_result({
        'ok'          => $is_ok,
        'explanation' => join("", map { "    $_\n" } @fail_reasons),
        'directive'   => '',
        'type'        => 'test',
        'test_num'    => scalar(@{$self->{'_results'}}),
        'description' => $self->name(),
        'raw'         => "${is_ok} - ${\$self->name()}",
    }));

    $self->formatter->add_test_results($results);
    return;
}

sub _fail_reasons {
    my $parser = shift;
    my @reasons = ();

    if ($parser->failed()) {
        push(@reasons, "failed tests (" . join(', ', $parser->failed()) . ")");
    }
    if ($parser->todo_passed()) {
        push(@reasons, "unexpected TODO passed (" . join(', ', $parser->todo_passed()) . ")");
    }
    if ($parser->parse_errors()) {
        push(@reasons, "parse errors (" . join(', ', $parser->parse_errors()) . ")");
    }
    if (!@reasons && $parser->exit() != 0) {
        push(@reasons, "non-zero exit code (" . $parser->exit(). ")");
    }
    if (!@reasons && $parser->has_problems()) {
        push(@reasons, "unknown reason (probably some bug encountered)");
    }

    return wantarray ? @reasons : \@reasons;
}

1;
