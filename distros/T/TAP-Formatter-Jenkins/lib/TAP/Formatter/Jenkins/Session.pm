package TAP::Formatter::Jenkins::Session;

use Moose;
use MooseX::NonMoose;
extends qw(
    TAP::Formatter::Console::Session
);

use TAP::Formatter::Jenkins::MyParser;

use TAP::Parser::YAMLish::Writer;
use File::Path qw(mkpath);
use IO::File;

has 'test_cases' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw( Array )],
    handles => {
        add_test_case  => 'push',
    },
);

has 'passing_todo_ok' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has '_queue' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw( Array )],
    handles => {
        _queue_add => 'push',
    },
);

###############################################################################
# Subroutine:   _initialize($arg_for)
###############################################################################
# Custom initializer, so we can accept a new "passing_todo_ok" argument at
# instantiation time.
sub _initialize {
    my ($self, $arg_for) = @_;
    $arg_for ||= {};

    my $passing_todo_ok = delete $arg_for->{passing_todo_ok};
    $self->passing_todo_ok($passing_todo_ok);

    return $self->SUPER::_initialize($arg_for);
}

###############################################################################
# Subroutine:   result($result)
###############################################################################
# Called by the harness for each line of TAP it receives.
#
# Queues up all of the TAP output for later conversion to JUnit.
sub result {
    my ( $self, $result ) = @_;

    # add the test result to the queue.
    $self->_queue_add($result);
}

###############################################################################
# Subroutine:   close_test()
###############################################################################
# Called to close the test session.
#
# Flushes the queue if we've got anything left in it, dumps the JUnit to disk
# (if necessary), and adds the XML for this test suite to our formatter.
sub close_test {
    my $self   = shift;
    my $parser = $self->parser;

    # Process the queued up TAP stream
    my $test_name = $self->name;
    my $queue     = $self->_queue;
    my $test_suite;
    my $has_ended;

    # Collect up all of the captured test output
    my $captured = join '', map { $_->raw . "\n" } @$queue;
    my $result   = TAP::Formatter::Jenkins::MyParser->new($captured);
    while ( ! $has_ended ) {
        # Failed test
        if ( $result->fail ) {
            $self->add_test_case( $self->_parse_failed_test_case($result) );
        }
        # End of tap
        elsif ( $result->has_ended ) {
            $test_suite = join '', @{ $self->test_cases };

            $has_ended = 1;
        }
        # Plan error
        elsif ( $result->is_plan_report ) {
            $self->add_test_case( $self->_test_more_comment_to_yamlish($result) );

            $result->next;
        }
        # Yamlish dump
        elsif ( $result->is_yamlish_start ) {
            $self->add_test_case( $self->_parse_yamlish_dump_from_tap($result) );
        }
        # Subtest plan
        elsif ( $result->is_subtest_plan ) {
            $self->add_test_case( $result->as_string. "\n" );

            $result->next;
        }
        # Other useless
        elsif ( $result->is_time_test ) {
            $result->next;
        }
        # die
        elsif ( $result->like_die ) {
            $self->add_test_case( $self->_parse_unknown_str($result) );
        }
        else {
            $self->add_test_case( $result->as_string. "\n" );

            $result->next;
        }
    }

    $self->formatter->test_suites->{ $test_name } = $test_suite;
    $self->_dump_tap_to_file($test_suite);
}

###############################################################################
# Subroutine:   _dump_tap_to_file($test_suite)
###############################################################################
# Dumps the TAP, to the directory specified by 'PERL_TEST_HARNESS_DUMP_TAP'.
sub _dump_tap_to_file {
    my ( $self, $test_suite ) = @_;

    if ( my $spool_dir = $ENV{PERL_TEST_HARNESS_DUMP_TAP} ) {
        my $tap_name = $self->name;
        $tap_name =~ s/^\///;
        $tap_name =~ s/\//-/g;
        $tap_name =~ s/\.t/.tap/;

        my $spool = File::Spec->catfile( $spool_dir, $tap_name );

        # Create target dir
        my ($vol, $dir, undef) = File::Spec->splitpath($spool);
        my $path = File::Spec->catpath( $vol, $dir, '' );
        mkpath($path);

        # Dump to disk
        my $fout  = IO::File->new( $spool, '>' )
            || die "Can't write $spool ( $! )\n";
        $fout->print($test_suite);
        $fout->close();
    }
}

###############################################################################
# Parses comments after failed test case
sub _parse_failed_test_case {
    my ( $self, $result ) = @_;

    my $yamlish_diag;
    my $comment = '';

    my $test_case = $result->as_string. "\n";
    $result->next;

    if ( $self->passing_todo_ok && $test_case =~ /#\sTODO/ ) {
        while ( $result->as_string !~ /^(not\s)?ok\s/ ) {
            $result->next;
        }

        $test_case =~ s/^not\s//;
        return $test_case;
    }

    # Empty spaces
    while ( ! $result->as_string ) {
        $result->next;
    }

    # Get comments
    while (
        $result->is_comment
        && ! $result->is_yamlish_start
        || ! $result->as_string
    ) {
        $comment .= $result->as_string. "\n";
        $result->next;
    }

    # Get yamlish
    if ( $result->is_yamlish_start ) {
        $yamlish_diag = $self->_parse_yamlish_dump_from_tap($result);
    }

    # Merge coment, yamlish
    $test_case .= $yamlish_diag
          ? $comment. $yamlish_diag
          : $comment && $comment =~ /failed.+test/i
            ? $self->_test_more_comment_to_yamlish( $result, $comment )
            : $comment;

    return $test_case;
}

###############################################################################
# Get Yamlish from Test::More output
sub _parse_yamlish_dump_from_tap {
    my ( $self, $result ) = @_;

    my $yamlish_diag;

    while (
        $result
         &&
        ! $result->is_yamlish_end
    ) {
        next unless $result->as_string;

        $yamlish_diag .= $result->as_string. "\n";
        $result->next;
    }

    $yamlish_diag .= $result->as_string. "\n";
    $result->next;

    $yamlish_diag =~ s/^#\s//gm;

    return $yamlish_diag;
}

###############################################################################
# Converts Test::More comment to Yamlish
sub _test_more_comment_to_yamlish {
    my ( $self, $result, $comment ) = @_;

    $comment //= $result->as_string;

    return $comment if $comment =~ /^\s+---/m;

    my @strs = split /\n/, $comment;

    my ( $got, $expected, $msg ) = ( '', '', '' );
    foreach ( @strs ) {
        s/\s*structures\sbegin\sdiffering\sat:\s*//i;

        if ( /got(?::\s(.*)|(->[\[{].+[\]}])\s=\s(.*))/ ) {
            $got = $1 || { $2 => $3 };
        }
        elsif ( /expected(?::\s(.*)|(->[\[{].+[\]}])\s=\s(.*))/ ) {
            $expected = $1 || { $2 => $3 };
        }
        elsif ( $_ ) {
            $msg .=  $_. ' ';
        }
    }

    $msg =~ s/#\s+//g;

    return $self->_yamlish_diag( $got, $expected, $msg );
}

###############################################################################
# Dumps Yamlish
sub _yamlish_diag {
    my ( $self, $got, $expected, $msg ) = @_;

    my %diagnostic = ( 'message' => $msg );

    if ( $got && $expected ) {
        $diagnostic{'data'} = {
            'got'      => $got,
            'expected' => $expected,
        }
    }

    my $res;
    my $yw = TAP::Parser::YAMLish::Writer->new;
    $yw->write( \%diagnostic, \$res );

    $res =~ s/^/ /gm;

    return $res;
}

###############################################################################
# Gets unlnown strings, and logs
sub _parse_unknown_str {
    my ( $self, $result ) = @_;

    my $msg;
    do {
        $msg .= $result->as_string. "\n";

        $result->next;
    } while ( $result->like_die );

    if ( $result->is_plan_report || $result->is_return_code ) {
        $msg = $self->_yamlish_diag( undef, undef, $msg );
    }
    else {
        $msg =~ s/^([^#])/\# $1/gm;

        my $unknown_strs = "unknown_strs.log";

        open  my $unknown_strs_fh, ">>", $unknown_strs or die "Can not open file $_";
        print $unknown_strs_fh "$msg\n";
        close $unknown_strs_fh;
    }

    return $msg;
}

1;

=head1 NAME

TAP::Formatter::Jenkins::Session - Harness output delegate for Jenkins TAP Plugin
output

=head1 DESCRIPTION

C<TAP::Formatter::Jenkins::Session> provides Jenkins TAP Plugin output formatting
for C<TAP::Harness>.

=head1 METHODS

=over

=item B<_initialize($arg_for)>

Over-ridden private initializer, so we can accept a new "passing_todo_ok"
argument at instantiation time.

=item B<result($result)>

Called by the harness for each line of TAP it receives.

Internally, all of the TAP is added to a queue until we hit the start of
the "next" test (at which point we flush the queue. This allows us to
capture any error output or diagnostic info that comes after a test
failure.

=item B<close_test()>

Called to close the test session.

Flushes the queue if we've got anything left in it, dumps the Jenkins TAP Plugin
formatting output to disk.

=item B<add_test_case($case)>

Adds an test C<$case> to the list of test_cases we've run in this session.

=back

=head1 AUTHOR

Evgeniy Vostrov <vostrov.e@gmail.com>

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::Jenkins>.
L<TAP::Formatter::Jenkins::MyParser>.

=cut
