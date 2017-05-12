package Test::AnyEvent::Time;

use warnings;
use strict;

use base ('Exporter');

use AnyEvent;
use Scalar::Util qw(looks_like_number);
use Test::Builder;

our @EXPORT = qw(time_within_ok time_cmp_ok time_between_ok elapsed_time);

my $Tester = Test::Builder->new();


## ** borrowed from Test::Exception
sub import {
    my $self = shift;
    if( @_ ) {
        my $package = caller;
        $Tester->exported_to($package);
        $Tester->plan( @_ );
    }
    $self->export_to_level( 1, $self, $_ ) foreach @EXPORT;
}



=head1 NAME

Test::AnyEvent::Time - Time-related tests for asynchronous routines using AnyEvent

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';




sub elapsed_time {
    my ($cb, $timeout) = @_;
    if(!defined($cb)) {
        return undef;
    }
    if(ref($cb) ne 'CODE') {
        return undef;
    }
    my $cv = AE::cv;
    my $w;
    my $timed_out = 0;
    if(defined($timeout)) {
        $w = AE::timer $timeout, 0, sub {
            undef $w;
            $timed_out = 1;
            $cv->send();
        };
    }
    my $before = AE::now;
    $cb->($cv);
    $cv->recv();
    if($timed_out) {
        return -1;
    }
    return (AE::now - $before);
}

sub time_cmp_ok {
    my ($cb, $op, $cmp_time, $timeout, $desc) = @_;
    if(!defined($desc) && defined($timeout) && !looks_like_number($timeout)) {
        $desc = $timeout;
        $timeout = undef;
    }
    if(!defined($op) || !defined($cb) || !defined($cmp_time) || ref($cb) ne "CODE") {
        $Tester->ok(0, $desc);
        $Tester->diag("Invalid arguments.");
        return 0;
    }
    my $time = elapsed_time($cb, $timeout);
    if(!defined($time)) {
        $Tester->ok(0, $desc);
        $Tester->diag("Invalid arguments.");
        return 0;
    }elsif($time < 0) {
        $Tester->ok(0, $desc);
        $Tester->diag("Timeout ($timeout sec)");
        return 0;
    }else {
        return $Tester->cmp_ok($time, $op, $cmp_time, $desc);
    }
}

sub time_between_ok {
    my ($cb, $min_time, $max_time, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return time_cmp_ok($cb, '>', $min_time, $max_time, $desc);
}

sub time_within_ok {
    my ($cb, $time, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return time_cmp_ok($cb, '<', $time, $time, $desc);
}

1;

__END__


=pod


=head1 SYNOPSIS

    use Test::AnyEvent::Time tests => 4;
    use Test::More;
    
    
    time_within_ok sub {
        my $cv = shift;
        your_asynchronous_func(
            data => 0.5,
            cb => sub {
                my ($result) = @_;
                note "This is the result: $result";
    
                ## Notify that this function is done.
                $cv->send();
            }
        );
    }, 10, "your_asynchronous_func() should return its result within 10 seconds.";
    
    
    time_within_ok sub {
        my $cv = shift;
        your_asynchronous_func(
            data => 1,
            cb => sub {
                ## Oops! I forgot to signal the CV!
            }
        );
    }, 4, "Timeout in 4 seconds and the test fails";
    
    
    time_between_ok sub {
        my $cv = shift;
        your_asynchronous_func(
            data => 1,
            cb => sub { $cv->send() }
        );
    }, 0.3, 1.5, "your_asynchronous_func() should return in between 0.3 seconds and 1.5 seconds";
    
    
    time_cmp_ok sub {
        my $cv = shift;
        your_asynchronous_func(
            data => 1,
            cb => sub { $cv->send() }
        );
    }, ">", 0.3, "your_asynchronous_func() should take more than 0.3 seconds. No timeout set.";
    
    
    ## You can just measure the time your asynchronous function takes.
    my $time = elapsed_time sub {
        my $cv = shift;
        your_asynchronous_func(
            data => 5,
            cb => sub { $cv->send }
        );
    };
    note("It takes $time seconds.");

=head1 DESCRIPTION

This module provides some functions that test an asynchronous routine in terms
of its execution time.
To measure their execution time,
asynchronous routines to be tested have to notify the test functions of their
finish by calling C<send()> (or C<end()>) method on a conditional variable in L<AnyEvent> framework.

This module is built with L<Test::Builder> module, so you can use this together with
L<Test::More> and other L<Test::Builder>-based test modules.


=head1 EXPORTED FUNCTIONS

=head2 $ok = time_within_ok $cb->($cv), $max_time[, $description];

Tests whether the asynchronous subroutine C<$cb> finishes within C<$max_time> seconds.
C<$description> is the test description, which can be omitted.

The argument C<$cb> is a subroutine reference. It gets a conditional variable C<$cv> as its first argument.
When the routine is done, you must call C<< $cv->send() >> to signal that it's finished.
So the typical usage of C<time_within_ok()> would be:

    time_within_ok sub {
        my $cv = shift;
        your_testee_func($some_data, sub {
            ## callback function of your_testee_func
            ...           ## some processing on the result
            $cv->send();  ## "I'm done!"
        });
    }, 10, "your_testee_func should finish within 10 sec.";


You can also use C<< $cv->begin() >> and C<< $cv->end() >> in the routine C<$cb>:

    time_within_ok sub {
        my $cv = shift;
        foreach my $single_data (@bunch_of_data) {
            $cv->begin();
            your_testee_func($single_data, sub { $cv->end() });
        }
    }, 10, "It should process all the bunch_of_data in parallel within 10 sec.";


C<time_within_ok()> will block until either the C<$cv> is signaled by the testee C<$cb> or
C<$max_time> has passed.
In the latter case, though, C<time_within_ok()> does not stop the execution of C<$cb>,
because it does not know how to do it.



=head2 $ok = time_between_ok $cb->($cv), $min_time, $max_time[, $description];

Tests whether the asynchronous subroutine C<$cb> finishes in between C<$min_time> seconds and C<$max_time> seconds.
You have to signal C<$cv> when C<$cb> finishes, just as in C<time_within_ok()> above.


=head2 $ok = time_cmp_ok $cb->($cv), $op, $expected_time[, $timeout, $description];

Generic form of the above two test functions.
This function measures the time that the asynchronous routine C<$cb> takes to finish,
and compares it with C<$expected_time> by the operator C<$op> like C<cmp_ok()> of L<Test::More> module.
I think C<time_within_ok()> and C<time_between_ok()> meet your need in most cases, though.

If C<$timeout> is specified, C<time_cmp_ok()> reports the result of "not ok" in C<$timeout> seconds if C<$cb> is not finished yet.
Note that expiration of C<$timeout> is always treated as error. For example:

    time_cmp_ok sub {
        my $cv = shift;
        my $w; $w = AE::timer 5, undef, sub {
            undef $w;
            $cv->send();
        };
    }, ">", 1, 2;

This times out in 2 seconds before the AE::timer fires.
Because the test condition is "elapsed time > 1 second",
it already meets the condition when it times out.
However, the test result is "not ok". The testee routine must finish before the timeout.

If C<$timeout> is not specified, there is no timeout.
C<time_cmp_ok()> will wait indefinitely for C<$cb> to signal the C<$cv>.
It is possible that your C<$cb> is somewhat broken and C<time_cmp_ok()> never returns, so be careful!


=head2 $time = elapsed_time $cb->($cv)[, $timeout];

This function is not a test function, but measures the time that the asynchronous routine C<$cb> takes to finish.
If C<$timeout> is specified, the function returns the result in C<$timeout> seconds even if C<$cb> is not finished yet.

C<elapsed_time()> returns the time in seconds that C<$cb> takes to signal C<$cv>.
It returns C<-1> if C<$timeout> is specified and it expires.
It returns C<undef> in other erroneous situations, such as not providing C<$cb>.


=head1 SEE ALSO

L<AnyEvent>


=head1 AUTHOR

Toshio Ito, C<< <debug.ito at gmail.com> >>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut


