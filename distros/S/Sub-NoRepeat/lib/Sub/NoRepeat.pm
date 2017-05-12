package Sub::NoRepeat;

our $DATE = '2015-11-07'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Fcntl qw(:DEFAULT :flock);
use Time::Local;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(norepeat);

our %SPEC;

$SPEC{norepeat} = {
    v => 1.1,
    summary => 'Call a subroutine or run a command, but not repeatedly',
    description => <<'_',

This routine allows you to avoid repeat execution of the same
subroutine/command. You can customize the key (which command/code are considered
the same, the default is the whole command or ref address of subroutine), the
repeat period, and some other stuffs.

It works simply by recording the keys and timestamps in a data file (defaults to
`~/norepeat.dat`, can be customized) after successful execution of
commands/subroutines. Commands might still repeat if `norepeat` fails to record
to data file (e.g. disk is full, permission problem).

Keywords: repeat interval, not too frequently, not more often than, at most,
once daily, weekly, monthly, yearly, period, limit rate.

_
    args_rels => {
        req_one => [qw/command code/],
        choose_one => [qw/period hourly daily weekly monthly yearly/],
    },
    args => {
        data_file => {
            schema => 'str*',
            description => <<'_',

Set filename to record execution to. Defaults to C<~/norepeat.dat>.

_
        },
        command => {
            schema => ['array*',of=>'str*',min_len=>1],
        },
        code => {
            schema => 'code*',
        },
        num => {
            summary => 'Allow (num-1) repeating during the same period',
            schema => ['int*', min=>1],
            default => 1,
            description => <<'_',

The default (1) allows no repetition during the same period. A value of 2 means
allow repeat once (for a total of 2 executions).

_
        },
        period => {
            schema => 'str*',
            default => 'forever',
            cmdline_aliases => {
                hourly => {
                    is_flag => 1,
                    summary => "Shortcut for --period hourly",
                    code => sub { $_[0]{period} = 'hourly' },
                },
                daily => {
                    is_flag => 1,
                    summary => "Shortcut for --period daily",
                    code => sub { $_[0]{period} = 'daily' },
                },
                weekly => {
                    is_flag => 1,
                    summary => "Shortcut for --period weekly",
                    code => sub { $_[0]{period} = 'weekly' },
                },
                monthly => {
                    is_flag => 1,
                    summary => "Shortcut for --period monthly",
                    code => sub { $_[0]{period} = 'monthly' },
                },
                yearly => {
                    is_flag => 1,
                    summary => "Shortcut for --period yearly",
                    code => sub { $_[0]{period} = 'yearly' },
                },
            },
            description => <<'_',

Set maximum period of repeat detection. The default (when not specified) is
forever, which means to never allow repeat, ever, if the same key (command or
subroutine) has been run.

Can either be set to "<number> (sec|min|hour|day|week|month|year)" to express
elapsed period after the last run, or "(hourly|daily|weekly|monthly|yearly)" to
express no repetition before the named period (hour|day|week|month|year)
changes.

For example, if period is "2 hour" then subsequent invocation won't repeat
commands until 2 hours have elapsed. In other words, command/code won't repeat
until the next 2 hours. Note that a month is defined as 30.5 days and a year is
defined as 365.25 days.

If period is "monthly", command/code won't repeat execution until the month
changes (e.g. from June to July). If you execute the first command on June 3rd,
command won't repeat until July 1st. The same thing would happen if you first
executed the command/code on June 30th.

When comparing, local times will be used.

_
        },
        ignore_failure => {
            schema => 'bool*',
            default => 0,
            description => <<'_',

By default, if command exits with non-zero status (or subroutine dies), it is
assumed to be a failure and won't be recorded in the data file. Another
invocation will be allowed to repeat. This option will disregard exit status or
trap exception and will still log the data file.

_
        },
        key => {
            summary => 'Key to use when recording event in data file',
            schema => 'str*',
            description => <<'_',

Set key for determining which commands/subroutines are considered the same.

If you use `command`, by default it will be the entire command.

If you use `code`, by default it will be the ref address of the code, e.g.
`CODE(0x1655800)`.

_
        },
        now => {
            summary => 'Assume current timestamp is this value',
            schema => 'int*',
            tags => ['category:debugging'],
        },
    },
    result_naked => 1,
};
sub norepeat {
    my %args = @_;

    # XXX schema
    my $command = $args{command};
    my $code    = $args{code};
    unless (defined($command) xor defined($code)) {
        die "norepeat: Please specify either command OR code";
    }
    my $num = $args{num} // 1;
    my $ignore_failure = $args{ignore_failure};

    my $data_file = $args{data_file} // "$ENV{HOME}/norepeat.dat";
    my $key = $args{key} // ($command ? join(" ",@$command) : "$code");

    $key =~ s/[\t\r\n]/ /g;

    my $now = $args{now} // time();
    my @now = localtime($now);

    my $period = $args{period};
    my $calc_seop_times; # routine to calculate start and end of period
    if ($period) {
        if ($period =~ /\A(\d+)\s*
                        (s|secs?|seconds?|mins?|minutes?|h|hours?|
                            d|days?|w|weeks?|mons?|months?|y|years?)\z/x
                        ) {
            my ($n, $unit) = ($1, $2);
            my $mult = $unit =~ /\A(s|secs?|seconds?)\z/ ? 1 :
                $unit =~ /\A(mins?|minutes?)\z/ ? 60 :
                $unit =~ /\A(h|hours?)\z/       ? 3600 :
                $unit =~ /\A(d|days?)\z/        ? 24*3600 :
                $unit =~ /\A(w|weeks?)\z/       ? 7*24*3600 :
                $unit =~ /\A(mons?|months?)\z/  ? 30.5*24*3600 :
                $unit =~ /\A(y|years?)\z/       ? 365.25*24*3600 : 0;
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                ($now, $t + $n * $mult);
            };
        } elsif ($period eq 'hourly') {
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                (
                    timelocal( 0,  0, $e->[2], $e->[3], $e->[4], $e->[5]),
                    timelocal(59, 59, $e->[2], $e->[3], $e->[4], $e->[5]),
                );
            };
        } elsif ($period eq 'daily') {
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                (
                    timelocal( 0,  0,  0, $e->[3], $e->[4], $e->[5]),
                    timelocal(59, 59, 23, $e->[3], $e->[4], $e->[5]),
                );
            };
        } elsif ($period eq 'weekly') {
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                # week starts on sunday (wday=0), so ends on the next sunday
                my $wday = $e->[6];
                my $t2 = $t + (7-$wday)*24*3600;
                my $e2 = [localtime $t2];
                (
                    timelocal( 0,  0,  0, $e->[3] , $e->[4] , $e->[5] ),
                    timelocal( 0,  0,  0, $e2->[3], $e2->[4], $e2->[5])-1,
                );
            };
        } elsif ($period eq 'monthly') {
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                my ($newm, $newy);
                $newm = $e->[4]+1;
                $newy = $e->[5];
                if ($newm == 12) { $newm = 0; $newy++ }
                (
                    timelocal(0, 0, 0, 1, $e->[4], $e->[5]), # 1st of this mon
                    timelocal(0, 0, 0, 1, $newm, $newy)-1,   # 1st of next mon
                );
            };
        } elsif ($period eq 'yearly') {
            $calc_seop_times = sub {
                my ($t, $e) = @_;
                (
                    timelocal(0, 0, 0, 1, 1, $e->[5]),     # 1st jan this year
                    timelocal(0, 0, 0, 1, 1, $e->[5]+1)-1, # 1st jan of next y
                );
            };
        } else {
            die "norepeat: Invalid period '$period'";
        }
    }

    my $should_run;
    my $fh;
  READ_DATA_FILE:
    {
        sysopen($fh, $data_file, O_RDWR | O_CREAT)
            or die "norepeat: Can't open data file '$data_file': $!";
        flock($fh, LOCK_EX)
            or die "norepeat: Can't lock data file '$data_file': $!\n";
        my $n = 0;
        while (<$fh>) {
            chomp;
            my %row = map { split/:/, $_, 2 } split /\t/, $_;

            next unless $key eq $row{key};

            # parse time
            my $time;
            if (!$row{time}) {
                warn "norepeat: No time defined in data file line $., skipped";
                next;
            } elsif ($row{time} =~ /\A\d+\z/) {
                $time = $row{time};
            } elsif ($row{time} =~
                         /\A(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(Z?)\z/) {
                $time = $7 ? timegm($6, $5, $4, $3, $2-1, $1-1900) :
                    timelocal($6, $5, $4, $3, $2-1, $1-1900);
            } else {
                warn "norepeat: Invalid time in data file line $. '$row{time}', ".
                    "ignored";
                next;
            }
            my @time = localtime($time);

            # check whether this is in the same period
            my $eop_time;
            if (!$period) {
                $n++;
            } else {
                my ($t1, $t2) = $calc_seop_times->($time, \@time);
                #$log->debug("period = [".localtime($t1)." to [".localtime($t2)."]");
                $n++ if $t1 <= $now && $t2 >= $now;
            }
        }
        #$log->debug("Have recorded $n execution(s) over the period");
        $should_run = $n < $num;
    }

    unless ($should_run) {
        $log->debug("norepeat: skipped repeated execution");
        return;
    }

  RUN:
    if ($command) {
        require IPC::System::Options;
        IPC::System::Options::system(
            {shell=>0, die=>!$ignore_failure}, @$command);
    } else {
        eval { $code->() };
        die if $@ && !$ignore_failure;
    }

  RECORD_DATA_FILE:
    {
        print $fh "time:$now\tkey:$key\n";
        close $fh
            or die "norepeat: Can't write data file '$data_file': $!";
    }
}

1;
# ABSTRACT: Call a subroutine or run a command, but not repeatedly

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::NoRepeat - Call a subroutine or run a command, but not repeatedly

=head1 VERSION

This document describes version 0.03 of Sub::NoRepeat (from Perl distribution Sub-NoRepeat), released on 2015-11-07.

=head1 SYNOPSIS

 use Sub::NoRepeat qw(norepeat);

 # run coderef
 norepeat(code => \&sub1);

 # won't run the same coderef again, noop
 norepeat(code => \&sub1);

 # run coderef because this one is different
 norepeat(code => sub { ... });

 # won't repeat because we use sub1 as key
 norepeat(code => sub { ... }, key => \&sub1);

 # run external command instead of coderef, die on non-zero exit code
 norepeat(command => ['somecmd', '--cmdopt', ...]);

 # will repeat after 24 hours
 norepeat(period => '24h', ...);

 # will repeat after change of day (equals to once daily):
 norepeat(period => 'daily', ...);

 # allows twice daily
 norepeat(period => 'daily', num=>2, ...);

=head1 DESCRIPTION

This module is a generalization of the concept of L<App::norepeat> and possibly
will supersede it in the future.

=head1 FUNCTIONS


=head2 norepeat(%args) -> any

Call a subroutine or run a command, but not repeatedly.

This routine allows you to avoid repeat execution of the same
subroutine/command. You can customize the key (which command/code are considered
the same, the default is the whole command or ref address of subroutine), the
repeat period, and some other stuffs.

It works simply by recording the keys and timestamps in a data file (defaults to
C<~/norepeat.dat>, can be customized) after successful execution of
commands/subroutines. Commands might still repeat if C<norepeat> fails to record
to data file (e.g. disk is full, permission problem).

Keywords: repeat interval, not too frequently, not more often than, at most,
once daily, weekly, monthly, yearly, period, limit rate.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<code>

=item * B<command> => I<array[str]>

=item * B<data_file> => I<str>

Set filename to record execution to. Defaults to C<~/norepeat.dat>.

=item * B<ignore_failure> => I<bool> (default: 0)

By default, if command exits with non-zero status (or subroutine dies), it is
assumed to be a failure and won't be recorded in the data file. Another
invocation will be allowed to repeat. This option will disregard exit status or
trap exception and will still log the data file.

=item * B<key> => I<str>

Key to use when recording event in data file.

Set key for determining which commands/subroutines are considered the same.

If you use C<command>, by default it will be the entire command.

If you use C<code>, by default it will be the ref address of the code, e.g.
C<CODE(0x1655800)>.

=item * B<now> => I<int>

Assume current timestamp is this value.

=item * B<num> => I<int> (default: 1)

Allow (num-1) repeating during the same period.

The default (1) allows no repetition during the same period. A value of 2 means
allow repeat once (for a total of 2 executions).

=item * B<period> => I<str> (default: "forever")

Set maximum period of repeat detection. The default (when not specified) is
forever, which means to never allow repeat, ever, if the same key (command or
subroutine) has been run.

Can either be set to "<number> (sec|min|hour|day|week|month|year)" to express
elapsed period after the last run, or "(hourly|daily|weekly|monthly|yearly)" to
express no repetition before the named period (hour|day|week|month|year)
changes.

For example, if period is "2 hour" then subsequent invocation won't repeat
commands until 2 hours have elapsed. In other words, command/code won't repeat
until the next 2 hours. Note that a month is defined as 30.5 days and a year is
defined as 365.25 days.

If period is "monthly", command/code won't repeat execution until the month
changes (e.g. from June to July). If you execute the first command on June 3rd,
command won't repeat until July 1st. The same thing would happen if you first
executed the command/code on June 30th.

When comparing, local times will be used.

=back

Return value:  (any)

=head1 DATA FILE

Data file is a line-oriented text file, using labeled tab-separated value format
(L<http://ltsv.org/>). Each row contains these labels: C<time> (a timestamp
either in the format of UTC ISO8601C<YYYY-MM-DDTHH:MM:SSZ>, local ISO8601
C<YYYY-MM-DDTHH:MM:SS>, or Unix timestamp), C<key> (tabs and newlines will be
converted to spaces).

The rows are assumed to be sorted chronologically (increasing time).

=head1 SEE ALSO

L<App::norepeat>, the CLI version.

Unix cron facility for periodic/scheduling of execution.

Related: modules to limit the number of program instances that can run at a
single time: L<Proc::Govern>, L<Sys::RunAlone>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sub-NoRepeat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sub-NoRepeat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-NoRepeat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
