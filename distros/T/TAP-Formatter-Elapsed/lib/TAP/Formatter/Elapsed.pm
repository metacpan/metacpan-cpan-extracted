package TAP::Formatter::Elapsed;
use base 'TAP::Formatter::Console';

use strict;
use Time::HiRes qw( gettimeofday tv_interval );
use POSIX qw( strftime );

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{'_t0'} = [ gettimeofday() ];
    $self->{'_t1'} = $self->{'_t0'};

    return $self;
}

sub _output {
    my ( $self, $line ) = @_;

    return unless defined $line;

    if ( $line =~ /^(?:not )?ok \d/ ) {
        my $format = defined $ENV{'TAP_ELAPSED_FORMAT'}
            ? $ENV{'TAP_ELAPSED_FORMAT'}
            : '[%Y-%m-%dT%H:%M:%S, %t0, %t1 elapsed]';

        $format =~ s{%t0}{ sprintf '%.2f', tv_interval($self->{'_t0'}) }eg;
        $format =~ s{%t1}{ sprintf '%.2f', tv_interval($self->{'_t1'}) }eg;

        $line .= ' ' . strftime( $format, localtime );

        $self->{'_t1'} = [ gettimeofday() ];
    }

    print { $self->stdout } $line;
}

1;

__END__

=head1 NAME

TAP::Formatter::Elapsed - Display time taken for each test

=head1 VERSION

This document describes version 0.02 of C<TAP::Formatter::Elapsed>

=head1 SYNOPSIS

B<prove> --formatter I<TAP::Formatter::Elapsed> -v ...

=head1 DESCRIPTION

The C<TAP::Formatter::Elapsed> module will, when used as the formatter for the
C<prove> command, add a time stamp to each test result line.  While C<prove>'s
C<--timer> option is useful for displaying the time taken for an individual
test file, this module can be useful to determine how long an individual test
takes to run.

Given the test file C<example.t>:

    #!perl -Tw
    
    use strict;
    use Test::More 0.88;
    
    ok sleep 2;
    ok sleep 2;
    ok sleep 2, 'last one';
    done_testing;

In the default case, each test line will have appended to it the current time,
the cumulative time taken so far, and the time since the last test result.

    $ prove --formatter TAP::Formatter::Elapsed -v example.t
    example.t ..
    ok 1 [2012-08-17T05:41:00, 2.04, 2.04 elapsed]
    ok 2 [2012-08-17T05:41:02, 4.04, 2.00 elapsed]
    ok 3 - last one [2012-08-17T05:41:04, 6.04, 2.00 elapsed]
    1..3
    ok
    All tests successful.
    Files=1, Tests=3,  6 wallclock secs ( 0.02 usr  0.01 sys +  0.01 cusr  0.00 csys =  0.04 CPU)
    Result: PASS

The time stamp format can be customized by setting the C<TAP_ELAPSED_FORMAT>
environment variable.  In addition to all of the formats provided by the
L<strftime()> function, C<%t0> will be replaced with the cumulative time since
the beginning of the test file, and C<%t1> will be replaced with the time
since the last test result.

    $ TAP_ELAPSED_FORMAT='%t1 %t0' prove --formatter TAP::Formatter::Elapsed -v example.t
    example.t ..
    ok 1 2.04 2.04
    ok 2 2.00 4.04
    ok 3 - last one 2.00 6.04
    1..3
    ok
    All tests successful.
    Files=1, Tests=3,  6 wallclock secs ( 0.02 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.03 CPU)
    Result: PASS

=head1 CONFIGURATION AND ENVIRONMENT

=head2 C<TAP_ELAPSED_FORMAT>

Setting this environment variable controls the format used by
C<TAP::Formatter::Elapsed> when appending a time stamp to a test result.  The
default value is C<[%Y-%m-%dT%H:%M:%S, %t0, %t1 elapsed]>.  The formats C<%t0>
and C<%t1> are replaced with the cumulative time and the time since the last
test result, respectively.  A single space is always prefixed to the time
stamp, to separate it from the test result.

=head1 AUTHOR

Chris Grau L<mailto:cgrau@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Chris Grau.

=cut
