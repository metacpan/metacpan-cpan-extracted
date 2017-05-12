package Test::Aggregate::Builder;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Test::Aggregate::Builder - Internal overrides for Test::Builder.

=head1 VERSION

Version 0.375

=cut

our $VERSION = '0.375';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    use Test::Aggregate::Builder;

=head1 DESCRIPTION

B<WARNING>:  This module is for internal use only.  DO NOT USE DIRECTLY.

=cut 

BEGIN { $ENV{TEST_AGGREGATE} = 1 }

END {    # for VMS
    delete $ENV{TEST_AGGREGATE};
}
use Test::Builder;

{
    my $DONE_TESTING;
    BEGIN {
        no warnings 'redefine';
        if ( Test::Builder->can('done_testing') ) {
            $DONE_TESTING = \&Test::Builder::done_testing;
            *Test::Builder::done_testing = sub {
                my ( $self, $num_tests ) = @_;

                $self->expected_tests( defined $num_tests
                    ? $num_tests
                    : $self->current_test
                );
                return;
            };
            my $output_plan = \&Test::Builder::_output_plan;
            *Test::Builder::_output_plan = sub {
                return unless $_[0]->{Done_Testing};
                goto $output_plan;
            };
        }
        else {
            *Test::Builder::_plan_check = sub {
                my $self = shift;

                # Will this break under threads?
                $self->{Expected_Tests} = $self->{Curr_Test} + 1;
            };
        }
    }
    END {
        my $tb = Test::Builder->new;
        $tb->{'Test::Aggregate::Builder'}{ignore_timing_blocks} = 1;
        my $tests = $tb->current_test;
        $tb->expected_tests($tests);
        if ( $DONE_TESTING ) {
            $tb->$DONE_TESTING($tests);
        }
        else {
            $tb->_print("1..$tests\n") unless $tb->{Have_Output_Plan};
        }
    }
}

no warnings 'redefine';

# The following is done to get around the fact that deferred plans are not
# supported.  Unfortunately, there's no clean way to override this, but this
# allows us to minimize the monkey patching.

# XXX We fully-qualify the sub names because PAUSE won't index what it thinks
# is an attempt to hijack the Test::Builder namespace.

sub Test::Builder::no_header { 1 }

{

    # prevent the 'you tried to plan twice' errors
    my $plan;
    BEGIN { $plan = \&Test::Builder::plan }

    our $skip = \1;

    sub Test::Builder::plan {
        delete $_[0]->{Have_Plan};
        $_[0]->{'Test::Aggregate::Builder'} ||= {};
        my $tab_builder = $_[0]->{'Test::Aggregate::Builder'};
        if ( 'skip_all' eq ( $_[1] || '' ) ) {
            my $callpack = caller(1);
            $tab_builder->{skip_all}{$callpack} = $_[2];
            my $running_test = $tab_builder->{running};
            die $skip if defined $running_test && $running_test eq $callpack;
            return;
        }

        my $callpack = caller(1);
        if ( 'tests' eq ( $_[1] || '' ) ) {
            $tab_builder->{plan_for}{$callpack} = $_[2];
            if ( $tab_builder->{test_nowarnings_loaded}{$callpack} )
            {

                # Test::NoWarnings was loaded before plan() was called, so it
                # didn't have a change to decrement it
                $tab_builder->{plan_for}{$callpack}--;
            }
        }
        $plan->(@_);
    }
}

{
    my $ok;
    BEGIN { $ok = \&Test::Builder::ok }

    my %FORBIDDEN = map { $_ => 1 } qw/BEGIN CHECK INIT END/;

    sub Test::Builder::ok {
        __check_test_count(@_);
        my $level  = 1;
        while (1) {
            my ($caller) = ( ( ( caller($level) )[3] || '' ) =~ /::([[:word:]]+)\z/ );
            last unless $caller;
            if ( $FORBIDDEN{$caller}
                && not $_[0]
                ->{'Test::Aggregate::Builder'}{ignore_timing_blocks} )
            {
                my ( $self, $test, $name ) = @_;
                $test = $test ? "Yes" : "No";
                my ( $filename, $line ) = ( caller($level) )[ 1, 2 ];
                $self->diag(<<"                END");
>>>>             DEPRECATION WARNING             <<<<
>>>> See http://use.perl.org/~Ovid/journal/38974 <<<<
Aggregated tests should not be run in BEGIN, CHECK, INIT or END blocks.
File:  $filename
Line:  $line
Name:  $name
Pass:  $test
                END
            }
            $level++;
        }
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $ok->(@_);
    }
}

{
    my $reset;
    BEGIN { $reset = \&Test::Builder::reset }

    sub Test::Builder::reset {
        my $self = shift;
        $reset->($self);
        $self->{'Test::Aggregate::Builder'} = {
            plan_for               => {},
            tests_run              => {},
            file_for               => {},
            test_nowarnings_loaded => {},
            skip_all               => {},
            check_plan             => undef,
            last_test              => undef,
        };
    }
}

{

    # Called in _ending and prevents the 'you tried to run a test without a
    # plan' error.
    my $_sanity_check;
    BEGIN { $_sanity_check = \&Test::Builder::_sanity_check }

    sub Test::Builder::_sanity_check {
        $_[0]->{Have_Plan} = 1;
        $_sanity_check->(@_);
    }
}

{
    my $skip;
    BEGIN { $skip = \&Test::Builder::skip }

    sub Test::Builder::skip {
        __check_test_count(@_);
        $skip->(@_);
    }
}

# two purposes:  we check the test cout for a package, but we also return the
# package name
sub __check_test_count {
    my $self = shift;
    my $callpack;
    return unless $self->{'Test::Aggregate::Builder'}{check_plan};
    my $stack_level = 1;
    while ( my ( $package, undef, undef, $subroutine ) = caller($stack_level) ) {
        last if 'Test::Aggregate' eq $package;

        # XXX Because these blocks aren't really subroutines, caller()
        # doesn't report what you expect.
        last
          if $callpack && $subroutine =~ /::(?:BEGIN|END)\z/;
        $callpack = $package;
        $stack_level++;
    }
    {
        no warnings 'uninitialized';
        $self->{'Test::Aggregate::Builder'}{tests_run}{$callpack} += 1;
    }
    return $callpack;
}

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-aggregate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Aggregate::Builder

You can also find information oneline:

L<http://metacpan.org/release/Test-Aggregate>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
