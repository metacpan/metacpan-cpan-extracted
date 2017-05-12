package Test::Aggregate::Nested;

use strict;
use warnings;

use Test::More;
use Test::Aggregate::Base;
use Carp;
use FindBin;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = 'Test::Aggregate::Base';

=encoding utf-8

=head1 NAME

Test::Aggregate::Nested - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.375

=cut

our $VERSION = '0.375';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    use Test::Aggregate::Nested;

    my $tests = Test::Aggregate::Nested->new( {
        dirs    => $aggregate_test_dir,
        verbose => 1,
    } );
    $tests->run;

=head1 DESCRIPTION

B<ALPHA WARNING>:  this is alpha code.  Conceptually it is superior to
C<Test::Aggregate>, but in reality, it might not be.  We'll see.

This module is almost identical to C<Test::Aggregate> and will in the future
be the preferred way of aggregating tests (until someone comes up with
something better :)

C<Test::Aggregate::Nested> requires a 0.8901 or better of C<Test::More>.  This
is because we use its C<subtest> function.  Currently we C<croak> if this
function is not available.

Because the TAP output is nested, you'll find it much easier to see which
tests result in which output.  For example, consider the following snippet of
TAP.  

    1..2
        1..5
        ok 1 - aggtests/check_plan.t ***** 1
        ok 2 - aggtests/check_plan.t ***** 2
        ok 3 # skip checking plan (aggtests/check_plan.t ***** 3)
        ok 4 - env variables should not hang around
        ok 5 - aggtests/check_plan.t ***** 4
    ok 1 - Tests for aggtests/check_plan.t
        1..1
        ok 1 - subs work!
    ok 2 - Tests for aggtests/subs.t

At the end of each nested test is a summary test line explaining which program
we ran tests for.

C<Test::Aggregate::Nested> asserts a plan equal to the number of test files
aggregated, something which C<Test::Aggregate> could not do.  Because of this,
we no longer export C<Test::More> functions.  If you need additional tests
before or after aggregation, you can run the aggregated tests in a subtest:

    use Test::More tests => 2;
    use Test::Aggregate::Nested;

    subtest 'Nested tests' => sub {
        Test::Aggregate::Nested->new({ dirs => 'aggtests/' })->run;
    };
    ok $some_other_test;

or disable the generation of the plan with the parameter C<no_generate_plan>:

    use Test::More;
    use Test::Aggregate::Nested;

    Test::Aggregate::Nested->new({ dirs => 'aggtests/', no_generate_plan => 1 })->run;
    ok $some_other_test;
    done_testing();

=head1 CAVEATS

C<Test::Aggregate::Nested> is much cleaner than C<Test::Aggregate>, so I don't
support the C<dump> argument.  If this is needed, let me know and I'll see
about fixing this.

The "variable will not stay shared" warnings from C<Test::Aggregate> (see its
CAVEATS section) are no longer applicable.

=cut

my $REINIT_FINDBIN = FindBin->can(q/again/) || sub {};

sub new {
    my ( $class, $arg_for ) = @_;
    if ( $arg_for->{dump} ) {
        require Carp;
        carp("Dump files are not supported under Test::Aggregate::Nested.");
    }
    unless ( Test::More->can('subtest') ) {
        my $tm_version = Test::More->VERSION;
        croak(<<"        END");
Test::More version $tm_version does not support nested TAP.
Please upgrade to version 0.8901 or newer to use Test::Aggregate::Nested.
        END
    }
    $class->SUPER::new($arg_for);
}

sub run {
    my $self = shift;

    local $Test::Aggregate::Base::_pid = $$;

    my %test_phase;
    foreach my $attr ( $self->_code_attributes ) {
        my $method = "_$attr";
        $test_phase{$attr} = $self->$method || sub { };
    }

    my @tests = $self->_get_tests;

    my ( $current, $total ) = ( 0, scalar @tests );
    if (! $self->{no_generate_plan}) {
        plan tests => $total;
    }
    $test_phase{startup}->();
    for my $test (@tests) {
        $current++;
        no warnings 'uninitialized';
        local %ENV = %ENV;
        local $/   = $/;
        local @INC = @INC;
        local $_   = $_;
        local $|   = $|;
        local %SIG = %SIG;
        local $@;
        use warnings 'uninitialized';

        # restrict this scope as much as possible
        local $0 = $test;
        $test_phase{setup}->($test);
        $REINIT_FINDBIN->() if $self->_findbin;
        my $package = $self->_get_package($test);
        if ( $self->_verbose ) {
            Test::More::diag("Running tests for $test ($current out of $total)");
        }
        eval <<"        END";
        package $package;
        Test::Aggregate::Nested::_do_file_as_subtest(\$test);
        END
        diag $@ if $@;
        $test_phase{teardown}->($test);
    }
    $test_phase{shutdown}->();
}

sub run_this_test_program { }

sub _do_file_as_subtest {
    my ($test) = @_;
    subtest("Tests for $test", sub {
        my $error;
        my $diag;

        {
            local ($@, $!);
            # if do("file") fails it will return undef (and set $@ or $!)
            unless(defined( my $return = do $test )){
                # If there was an error be sure to propogate it.
                # This isn't quite the same as what's described by `perldoc -f do`
                # because there are no rules about what a .t file should return.
                # If the file doesn't return a defined value there's no way to
                # tell the difference between a test that errored and one that
                # returned undef but did something that happened to set `$!`
                # (for example, a file that skips when it looks for a file that
                # isn't found), so we shouldn't treat it as an error.
                # If the file fails to read then subtest() will complain
                # that no tests were run (and consider it a failure).
                # That should be sufficient.

                my $ex_class = 'Test::Builder::Exception';
                if( my $e = $@ ){
                    $error = "Couldn't parse '$test': $e"
                        unless (
                            # a skip in a subtest will be an object
                            ref($e) ? eval { $e->isa($ex_class) } :
                                # a skip in a BEGIN ("use Test::More skip_all => $message") gets stringified
                                $e =~ /^\Q${ex_class}=HASH(0x\E[[:xdigit:]]+\Q)BEGIN failed--compilation aborted\E/
                        );
                }
                # If tests have been run we can assume the file was read.
                # If not, print a warning message.
                # Either way Test::Builder will handle marking it as pass/fail.
                elsif( scalar(Test::Builder->new->details) == 0 ){
                    # It might have been an error, or might not, so try to get
                    # the author to help us out.
                    $diag = <<TEST_DIAG;
#
# WARNING:
# It is unknown if '$test' actually finished.
# To remove this warning have the test script end with a defined value.
#
TEST_DIAG
                    # This *may* indicate a failure to read the file.
                    $diag .= <<TEST_DIAG if $!;
# The following error was set (\$!):
# $!
#
TEST_DIAG
                }
            }
        }
        # show the error but don't halt everything
        Test::More::diag($diag) if $diag;
        Test::More::ok(0, "Error running ($test):  $error") if $error;
    });
}

1;

__END__

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

    perldoc Test::Aggregate::Nested

You can also find information oneline:

L<http://metacpan.org/release/Test-Aggregate>

=head1 ACKNOWLEDGEMENTS

Many thanks to mauzo (L<http://use.perl.org/~mauzo/> for helping me find the
'skip_all' bug.

Thanks to Johan Lindström for pointing me to Apache::Registry.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
