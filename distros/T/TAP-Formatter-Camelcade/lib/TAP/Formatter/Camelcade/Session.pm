package TAP::Formatter::Camelcade::Session;
use strict;
use warnings FATAL => 'all';
use base 'TAP::Formatter::Session';
use TAP::Formatter::Camelcade::MessageBuilder;
use Time::HiRes qw/time/;
use Digest::MD5 qw/md5_hex/;

#@returns TAP::Formatter::Camelcade::MessageBuilder
sub builder {
    return 'TAP::Formatter::Camelcade::MessageBuilder';
}

=pod

Invoked for every line of parsed result

=cut

sub result {
    my $self = shift;
    #@type TAP::Parser::Result
    my $result = shift;

    my $type = $result->type;
    if ($type eq 'plan') {
        $self->handle_plan($result);
    }
    elsif ($type eq 'pragma') {
        $self->handle_pragma($result);
    }
    elsif ($type eq 'test') {
        $self->handle_test($result);
    }
    elsif ($type eq 'comment') {
        $self->handle_comment($result);
    }
    elsif ($type eq 'bailout') {
        $self->handle_bailout($result);
    }
    elsif ($type eq 'version') {
        $self->handle_version($result);
    }
    elsif ($type eq 'unknown') {
        $self->handle_unknown($result);
    }
    elsif ($type eq 'yaml') {
        $self->handle_yaml($result);
    }
    else {
        die "Unknown type: $type";
    }
}

=pod

We are keeping last test failure to append comments into it

=cut

sub close_pending_test {
    my $self = shift;
    my $pending_test = $self->get_pending_test;
    $self->{last_test} = undef;
    if (!defined $pending_test) {
        return;
    }
    $self->set_last_time;
    my $test_output = join "\n", @{$pending_test->{output}};
    $test_output //= "";
    $test_output =~ s{(\A\n+|\n+\z)}{}gs;
    if ($pending_test->{is_ok}) {
        if ($pending_test->{is_skip}) {
            builder->test_ignored(
                $pending_test->{name},
                $test_output,
                $pending_test->{nodeId},
                $pending_test->{parentNodeId},
            );
        }
        elsif (length $test_output > 0) {
            builder->stderr(
                $pending_test->{name},
                $test_output,
                $pending_test->{nodeId},
                $pending_test->{parentNodeId},
            );
        }
    }
    else {
        my @extra = ();
        if ($test_output) {
            my $normalized_output = $test_output;
            $normalized_output =~ s{^\s*# }{}gmi;
            #            use v5.10; say STDERR "Normalized as $normalized_output";
            if ($normalized_output =~ m{         got: '(.*?)'\n    expected: '(.*)'}s) {
                @extra = (
                    type     => 'comparisonFailure',
                    actual   => $1,
                    expected => $2
                );
            }
        }
        $test_output =~ s/^\s+//gm;

        builder->test_failed(
            $pending_test->{name},
            $pending_test->{explanation} // "",
            $pending_test->{nodeId},
            $pending_test->{parentNodeId},
            details => $test_output,
            @extra
        );

        $self->{failures}++;
    }
    builder->test_finished(@$pending_test{qw/name duration nodeId parentNodeId/});
}

sub start_test {
    my $self = shift;
    #@type TAP::Parser::Result::Test
    my $test = shift;

    my $last_time = $self->get_last_time;
    my $test_name = $self->_compute_test_name($test);
    my $test_duration = int((time - $last_time) * 1000);
    $self->close_pending_test;
    $self->{last_test} = {
        name         => $test_name,
        duration     => $ENV{TAP_FORMATTER_CAMELCADE_DURATION} // $test_duration,
        is_ok        => scalar $test->is_ok,
        is_skip      => scalar $test->has_directive,
        output       => [],
        explanation  => scalar $test->explanation,
        nodeId       => scalar $self->generate_test_id($test_name),
        parentNodeId => scalar $self->get_parent_node_id
    };
    builder->test_started(@{$self->{last_test}}{qw/name nodeId parentNodeId/});
}

sub set_last_time {
    my $self = shift;
    $self->{last_time} = time;
}

sub get_last_time {
    my $self = shift;
    return $self->{last_time} // time;
}

sub get_pending_test {
    my $self = shift;
    return $self->{last_test};
}

sub _compute_test_name {
    shift;
    #@type TAP::Parser::Result::Test
    my $result = shift;
    my $base_name = "";
    my $description = $result->description;
    my $explanation = $result->explanation;
    if( $description ){
        $base_name = $description;
        if( $explanation ){
            $base_name .= " ($explanation)";
        }
    }
    elsif( $explanation){
        $base_name = $explanation;
    }

    $base_name =~ s/^-\s//;
    $base_name ||= 'Unnamed test (#' . $result->number . ')';
    my $directive = $result->directive // "";
    return join" ", ($directive ? ($directive) : ()), $base_name;
}

sub handle_plan {
    my $self = shift;
    #@type TAP::Parser::Result::Plan
    my $result = shift;
    $self->close_pending_test;

    if ($result->directive eq 'SKIP') {
        builder->output($result->explanation);
    }
}

sub handle_pragma {
    my $self = shift;
    #@type TAP::Parser::Result::Pragma
    my $result = shift;
    $self->process_as_comment($result);
}

=pod

Invoked for every test result

=cut

sub handle_test {
    my $self = shift;
    #@type TAP::Parser::Result::Test
    my $result = shift;

    my $test_name = $self->_compute_test_name($result);
    if ($self->is_subtest($test_name)) {
        $self->finish_subtest;
    }
    else {
        $self->start_test($result);
    }
}

sub handle_comment {
    my $self = shift;
    #@type TAP::Parser::Result::Comment
    my $result = shift;

    my $comment = $result->raw;

    if ($comment =~ /^\s*# Subtest: (.+)$/) {
        $self->start_subtest($1);
    }
    else {
        my $last_test = $self->get_pending_test;
        if ($last_test) {
            push @{$last_test->{output}}, $comment;
        }
        else {
            builder->warning($comment);
        }
    }
}

sub handle_bailout {
    my $self = shift;
    #@type TAP::Parser::Result::Bailout
    my $result = shift;
    $self->process_as_comment($result);
}

sub handle_version {
    my $self = shift;
    #@type TAP::Parser::Result::Version
    my $result = shift;
    $self->process_as_comment($result);
}

sub handle_unknown {
    my $self = shift;
    #@type TAP::Parser::Result::Unknown
    my $result = shift;
    my $raw = $result->raw;
    if ($self->in_in_subtest && $raw =~ /^\s*(((?:not )?ok) ([0-9]+)(?: (- .*))?)$/) {
        my $test_raw = $1;
        my $is_ok = $2;
        my $test_num = $3;
        my $description = $4 // "";
        $self->result(TAP::Parser::Result::Test->new({
            raw         => $test_raw,
            ok          => $is_ok,
            test_num    => $test_num,
            description => $description,
            type        => 'test',
            explanation => '',
            directive   => '',
        }));
    }
    elsif ($raw =~ /^\s+# Subtest: (.+)$/) {
        $self->start_subtest($1);
    }
    elsif ($raw =~ /^\s*\d+\.\.\d+$/) {
        # ignore
    }
    else {
        $self->process_as_comment($result);
    }
}

#@returns TAP::Parser::Result::Comment
sub process_as_comment {
    my $self = shift;
    #@type TAP::Parser::Result
    my $result = shift;
    my $comment = $result->raw;
    $comment =~ s/^\s+//;
    # use Data::Dumper;    print STDERR "Handling: ".Dumper($result);
    $self->result(TAP::Parser::Result::Comment->new({
        raw     => scalar $result->raw,
        type    => 'comment',
        comment => $comment
    }));
}

sub handle_yaml {
    my $self = shift;
    #@type TAP::Parser::Result::YAML
    my $result = shift;
    $self->process_as_comment($result);
}

sub close_test {
    my $self = shift;
    $self->finish_suite;
}

#@override
sub _initialize {
    my ($self, $arg_for) = @_;

    $self->{location} = delete $$arg_for{location};

    $self->SUPER::_initialize($arg_for);
    $self->{subtests} = [];
    $self->{suites} = [];
    $self->{counter} = 0;
    $self->{failures} = 0;
    # $arg_for has parser, name, formatter
    $self->start_suite($self->name, $self->{location});
    $self->set_last_time;
    return $self;
}

sub start_suite {
    my $self = shift;
    my $name = shift;
    my $location = shift;
    my $suite = {
        name         => $name,
        nodeId       => scalar $self->generate_suite_id($name, $location),
        parentNodeId => scalar $self->get_parent_node_id(),
        location     => $location || $name
    };
    push @{$self->{suites}}, $suite;
    builder->test_suite_started(@$suite{qw/name location nodeId parentNodeId/});
}

sub generate_suite_id {
    my $self = shift;
    my $name = shift;
    my $location = shift;
    my $new_id = join '-', $location || $name, $ENV{TAP_FORMATTER_CAMELCADE_DURATION} ? () : ($$, time), $self->{counter}++;
    return $ENV{TAP_FORMATTER_CAMELCADE_DURATION} ? $new_id : md5_hex($new_id);
}

sub generate_test_id {
    my $self = shift;
    my $name = shift;
    my $new_id = join '-', $self->get_parent_node_id, $name, $self->{counter}++;
    return $ENV{TAP_FORMATTER_CAMELCADE_DURATION} ? $new_id : md5_hex($new_id);
}

sub get_current_suite {
    my $self = shift;
    if (scalar @{$self->{suites}} == 0) {
        return undef;
    }
    return $self->{suites}->[$#{$self->{suites}}];
}

sub get_parent_node_id {
    my $self = shift;
    my $current_suite = $self->get_current_suite;
    return defined $current_suite ? $current_suite->{nodeId} : 0;
}

sub finish_suite {
    my $self = shift;
    $self->close_pending_test;

    my $parser = $self->parser;
    if (!$self->{failures} && UNIVERSAL::isa($parser, 'TAP::Parser') && $parser->{exit}) {
        my $test_name = 'Initialization error';
        my $test_id = $self->generate_test_id($test_name);
        my $parent_node_id = $self->get_parent_node_id;
        builder->test_started($test_name, $test_id, $parent_node_id);
        builder->test_failed($test_name, "Non-zero exit code: $parser->{exit}", $test_id, $parent_node_id);
        builder->test_finished($test_name, 0, $test_id, $parent_node_id);
    }

    my $current_suite = pop @{$self->{suites}};
    return unless $current_suite;
    builder->test_suite_finished(@$current_suite{qw/name nodeId parentNodeId/});
}

sub start_subtest {
    my $self = shift;
    my $subtest_name = shift;
    $self->close_pending_test;
    push @{$self->{subtests}}, $subtest_name;
    $self->start_suite($subtest_name);
}

sub is_subtest {
    my $self = shift;
    my $test_name = shift;
    my $last_index = $#{$self->{subtests}};
    return $last_index > -1 && $self->{subtests}->[$last_index] eq $test_name;
}

sub in_in_subtest {
    my $self = shift;
    return scalar @{$self->{subtests}};
}

sub finish_subtest {
    my $self = shift;
    my $subtest_name = pop @{$self->{subtests}};
    return unless $subtest_name;
    $self->finish_suite;
}

#@method
#@override
sub _should_show_count {
    0;
}

1;