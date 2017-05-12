package Test::Deep::DateTime::RFC3339;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.04';

use Test::Deep::Cmp;    # isa

use Exporter 'import';
our @EXPORT = qw(datetime_rfc3339);

use Carp 'confess';

use DateTime;
use DateTime::Duration;
use DateTime::Format::RFC3339;
use DateTime::Format::Duration::DurationString;
use DateTime::Format::Human::Duration;
use Safe::Isa '$_isa';

sub datetime_rfc3339 {
    __PACKAGE__->new(@_);
}

sub init {
    my $self = shift;

    $self->{parser} = DateTime::Format::RFC3339->new;
    return unless @_;

    my $expected  = shift or confess "Expected datetime required for datetime_rfc3339() with arguments";
    my $tolerance = shift || DateTime::Duration->new; # default to an ->is_zero duration

    unless ($expected->$_isa("DateTime")) {
        my $parsed = eval { $self->{parser}->parse_datetime($expected) }
            or confess "Expected datetime isn't a DateTime and can't be parsed as RFC3339: '$expected', $@";
        $expected = $parsed;
    }
    unless ($tolerance->$_isa("DateTime::Duration")) {
        my $parser = DateTime::Format::Duration::DurationString->new;
        my $parsed = eval { $parser->parse($tolerance)->to_duration }
            or confess "Expected tolerance isn't a DateTime::Duration and can't be parsed: '$tolerance', $@";
        $tolerance = $parsed;
    }

    # Do all comparisons and math in UTC
    $expected->set_time_zone('UTC');

    $self->{expected}  = $expected;
    $self->{tolerance} = $tolerance;

    return;
}

sub descend {
    my ($self, $got) = @_;
    my ($expected, $tolerance) = @$self{'expected', 'tolerance'};

    $got = eval { $self->{parser}->parse_datetime($got) };

    if ($@ or not $got) {
        $self->{diag_message} = sprintf "Can't parse %s as an RFC3339 timestamp: %s",
            (defined $_[1] ? "'$_[1]'" : "an undefined value"), $@;
        return 0;
    }

    $got->set_time_zone('UTC')
        if $expected;

    # This lets us receive the DateTime object in renderGot
    $self->data->{got_string} = $self->data->{got};
    $self->data->{got} = $got;

    return $expected
        ? ($got >= $expected - $tolerance and $got <= $expected + $tolerance)
        : 1;    # we parsed!
}

# reported at top of diagnostic output on failure
sub diag_message {
    my ($self, $where) = @_;
    my $msg = "Compared $where";
    $msg .= "\n" . $self->{diag_message}
        if $self->{diag_message};
    return $msg;
}

# used in diagnostic output on failure to render the expected value
sub renderExp {
    my $self = shift;
    return "any RFC3339 timestamp" unless $self->{expected};

    my $expected = $self->_format( $self->{expected} );
    return $self->{tolerance}->is_zero
        ? $expected
        : $expected . " +/- " . DateTime::Format::Human::Duration->new->format_duration($self->{tolerance});
}

sub renderGot {
    my ($self, $got) = @_;
    return $got->$_isa("DateTime") ? $self->_format($got) : $got;
}

sub _format {
    my $self = shift;
    return $self->{parser}->format_datetime(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Deep::DateTime::RFC3339 - Test RFC3339 timestamps are within a certain tolerance

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::DateTime::RFC3339;

    my $now    = DateTime->now;
    my $record = create_record(...);
    cmp_deeply $record, { created => datetime_rfc3339($now, '5s') },
        'Created is within 5 seconds of current time';

=head1 DESCRIPTION

Test::Deep::DateTime::RFC3339 provides a single function,
L<< C<datetime_rfc3339>|/datetime_rfc3339 >>, which is used with L<Test::Deep> to
check that the B<string> value gotten is an RFC3339-compliant timestamp.  It
can also check if the timestamp is equal to, or within optional tolerances of,
an expected timestamp.

L<RFC3339|https://tools.ietf.org/html/rfc3339> was chosen because it is a sane
subset of L<ISO8601's kitchen-sink|DateTime::Format::ISO8601/"Supported via parse_datetime">.

=head1 FUNCTIONS

=head2 datetime_rfc3339

Without arguments, the value is only checked to be a parseable RFC3339
timestamp.

Otherwise, this function takes a L<DateTime> object or an
L<RFC3339 timestamp|https://tools.ietf.org/html/rfc3339> string parseable by
L<DateTime::Format::RFC3339> as the required first argument and a
L<DateTime::Duration> object or a L<DateTime::Format::Duration::DurationString>-style
string (e.g. C<5s>, C<1h 5m>, C<2d>) representing a duration as an optional
second argument.  The second argument is used as a ± tolerance centered on the
expected datetime.  If a tolerance is provided, the timestamp being tested must
fall within the closed interval for the test to pass.  Otherwise, the timestamp
being tested must match the expected datetime.

All comparisons and date math are done in UTC, as advised by
L<DateTime/"How-DateTime-Math-Works">.  If this causes problems for you, please
tell me about it via bug-Test-Deep-DateTime-RFC3339 I<at> rt.cpan.org.

Returns a Test::Deep::DateTime::RFC3339 object, which is a L<Test::Deep::Cmp>,
but you shouldn't need to care about those internals.  You can, however, reuse
the returned object if desired.

Exported by default.

=head1 BUGS

Please report bugs via email to C<bug-Test-Deep-DateTime-RFC3339@rt.cpan.org> or
L<via the web on rt.cpan.org|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deep-DateTime-RFC3339>.

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2014- by the Mullins Lab, Department of
Microbiology, University of Washington.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Deep>

L<DateTime>

L<DateTime::Duration>

L<DateTime::Format::RFC3339>

L<RFC3339|https://tools.ietf.org/html/rfc3339>

=cut
