package Test::Aggregate;

use warnings;
use strict;
use Carp 'croak';

use Test::More;
use Test::Aggregate::Base;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA    = qw(Test::Aggregate::Base);
@EXPORT = (@Test::More::EXPORT, 'run_this_test_program');
# controls whether or not we show individual test program pass/fail
my %VERBOSE = (
    none     => 0,
    failures => 1,
    all      => 2,
);
my $BUILDER = Test::Builder->new;

=encoding utf-8

=head1 NAME

Test::Aggregate - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.375

=cut

our $VERSION = '0.375';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    use Test::Aggregate;

    my $tests = Test::Aggregate->new( {
        dirs => $aggregate_test_dir,
    } );
    $tests->run;

    ok $some_data, 'Test::Aggregate also re-exports Test::More functions';

=head1 DESCRIPTION

B<WARNING>:  this is ALPHA code.  The interface is not guaranteed to be
stable.  Further, check out L<Test::Aggregate::Nested> (included with this
distribution).  It's a more robust implementation which does not have the same
limitations as C<Test::Aggregate>.

A common problem with many test suites is that they can take a long time to
run.  The longer they run, the less likely you are to run the tests.  This
module borrows a trick from C<Apache::Registry> to load up your tests at once,
create a separate package for each test and wraps each package in a method
named C<run_the_tests>.  This allows us to load perl only once and related
modules only once.  If you have modules which are expensive to load, this can
dramatically speed up a test suite.

=head1 DEPRECATION

For a whole variety of reasons, tests run in BEGIN/CHECK/INIT/INIT blocks are
now deprecated.  They cause all sorts of test sequence headaches.  Plus, they
break the up-coming nested TAP work.  You will have a problem if you use this
common idiom:

 BEGIN {
     use_ok 'My::Module' or die;
 }

Instead, just C<use> the module and put the C<use_ok> tests in a t/load.t file
or something similar and B<don't> aggregate it.  See the following for more
information: L<http://use.perl.org/~Ovid/journal/38974>.

=head1 USAGE

Create a separate directory for your tests.  This should not be a subdirectory
of your regular test directory.  Write a small driver program and put it in
your regular test directory (C<t/> is the standard):

 use Test::Aggregate;
 my $other_test_dir = 'aggregate_tests';
 my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
 });
 $tests->run;

 ok $some_data, 'Test::Aggregate also re-exports Test::More functions';

Take your simplest tests and move them, one by one, into the new test
directory and keep running the C<Test::Aggregate> program.  You'll find some
tests will not run in a shared environment like this.  You can either fix the
tests or simply leave them in your regular test directory.  See how this
distribution's tests are organized for an example.

Note that C<Test::Aggregate> also exports all exported functions from
C<Test::More>, allowing you to run other tests after the aggregated tests have
run.

 use Test::Aggregate;
 my $other_test_dir = 'aggregate_tests';
 my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
 });
 $tests->run;
 ok !(-f 't/data/tmp.txt'), '... and our temp file should be deleted';

Some tests cannot run in an aggregate environment.  These may include
test for this with the C<< $ENV{TEST_AGGREGATE} >> variable:

 package Some::Package;

 BEGIN {
     die __PACKAGE__ ." cannot run in aggregated tests"
       if $ENV{TEST_AGGREGATE};
 }

=head1 METHODS

=head2 C<new>
 
 my $tests = Test::Aggregate->new(
     {
         dirs            => 'aggtests',
         verbose         => 1,            # optional, but recommended
         dump            => 'dump.t',     # optional
         shuffle         => 1,            # optional
         matching        => qr/customer/, # optional
         set_filenames   => 0,            # optional and not recommended
         tidy            => 1,            # optional and experimental
         test_nowarnings => 0,            # optional and experimental
     }
 );
 
Creates a new C<Test::Aggregate> instance.  Accepts a hashref with the
following keys:

=over 4

=item * C<dirs> (either this or C<tests> is mandatory)

The directories to look in for the aggregated tests.  This may be a scalar
value of a single directory or an array reference of multiple directories.

=item * C<tests> (either this or C<dirs> is mandatory)

Instead of providing directories for the aggregated tests, you may supply an
array reference with a list of tests to aggregate.  If both are supplied,
these tests will be appended to the list of tests found in C<dirs>.

The C<matching> parameter does not apply to test files identified with this
key.

=item * C<verbose> (optional, but strongly recommended)

If set with a true value, each test programs success or failure will be
indicated with a diagnostic output.  The output below means that
C<aggtests/slow_load.t> was an aggregated test which failed.  This means it's
much easier to determine which aggregated tests are causing problems.

 t/aggregate.........2/? 
 #     ok - aggtests/boilerplate.t
 #     ok - aggtests/00-load.t
 # not ok - aggtests/subs.t
 #     ok - aggtests/slow_load.t
 t/aggregate.........ok
 t/pod-coverage......ok
 t/pod...............ok

Note that three possible values are allowed for C<verbose>:

=over 4

=item * C<0> (default)

No individual test program success or failure will be displayed.

=item * C<1>

Only failing test programs will have their failure status shown.

=item * C<2>

All test programs will have their success/failure shown.

=back

=item * C<dump> (optional)

You may list the name of a file to dump the aggregated tests to.  This is
useful if you have test failures and need to debug why the tests failed.

=item * C<shuffle> (optional)

Ordinarily, the tests are sorted by name and run in that order. This allows
you to run them in any order.

=item * C<matching> (optional)

If supplied with a regular expression (requires the C<qr> operator), will only
run tests whose filename matches the regular expression.

=item * C<set_filenames> (optional)

If supplied with a true value, this will cause the following to be added for
each test:

  local $0 = $test_filename;

This is the default behavior.

=item * C<findbin> (optional)

If supplied with a true value, this will cause FindBin::again() to be called
before each test file.

This is turned off by default.

Note that older versions of FindBin (pre 1.47) sometimes get confused about
where the bin directory is when I set C<$0>.  I don't know why, but this is a
rarely used option and only happens pre 5.8 perl, so I'm not too worried about
it.  Just keep it in mind.

=item * C<dry> (optional)

Just print the tests which will be run and the order they will be run in
(obviously the order will be random if C<shuffle> is true).


=item * C<tidy>

If supplied a true value, attempts to run C<Perl::Tidy> on the source code.
This is a no-op if C<Perl::Tidy> cannot be loaded.  This option is
C<experimental>.  Plus, if your tests are terribly convoluted, this could be
slow and possibly buggy.

If the value of this argument is the name of a file, assumes that this file is
a C<.perltidyrc> file.

=item * C<test_nowarnings>

Disables C<Test::NoWarnings> (fails if the module cannot be loaded).

This is experimental and somewhat problematic.  Let me know if there are any
problems.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if ($self->{no_generate_plan}) {
        croak "no_generate_plan is not supported in Test::Aggregate";
    }
    return $self;
}

=head2 C<run>

 $tests->run;

Attempts to aggregate and run all tests listed in the directories specified in
the constructor.

=cut

sub _do_dry_run {
}

sub run {
    my $self  = shift;

    local $Test::Aggregate::Base::_pid = $$;

    my $verbose = $self->_verbose;

    my @tests = $self->_get_tests;
    if ( $self->_dry ) {
        my $current = 1;
        my $total   = @tests;
        foreach my $test (@tests) {
            print "$test (File $current out of $total)\n";
            $current++;
        }
        return;
    }
    my $code = $self->_build_aggregate_code(@tests);

    my $dump = $self->_dump;
    if ( $dump ne '' ) {
        local *FH;
        open FH, "> $dump" or die "Could not open ($dump) for writing: $!";
        print FH $code;
        close FH;
    }

    # XXX Theoretically the 'eval $code' could run the tests directly and
    # remove a lot of annoying duplication, but unfortunately, we can't
    # properly capture the startup/shutdown/setup/teardown behavior there
    # without mandating that Data::Dump::Streamer be installed.  As a result,
    # this eval'ed code has a check to not actually run the tests if we are
    # not in the dump file.
    eval $code;

    if ( my $error = $@ ) {
        croak("Could not run tests: $@");
    }

    $self->_startup->() if $self->_startup;

    # some tests may have been run in BEGIN blocks.  This is deprecated and
    # now warns
    my $tab = 'Test::Aggregate::Builder';
    $BUILDER->{$tab}{last_test} = @{ $BUILDER->{Test_Results} } || 0;
    $BUILDER->{$tab}{aggregate_program} = $self->{aggregate_program};

    my $current_test = 0;
    my @packages     = $self->_packages;
    my $total_tests  = @packages;
    foreach my $data (@packages) {
        $current_test++;
        my ( $test, $package ) = @$data;
        $self->_setup->($test) if $self->_setup;
        run_this_test_program( $package => $test, $current_test, $total_tests, $verbose );
        if ( my $error = $@ ) {
            Test::More::ok( 0, "Error running ($test):  $error" );
        }

        # XXX this should be fine since these keys are not actually used
        # internally.
        $BUILDER->{XXX_test_failed}       = 0;
        $BUILDER->{TEST_MOST_test_failed} = 0;
        $self->_teardown->($test) if $self->_teardown;
    }
    $self->_shutdown->() if $self->_shutdown;
}

sub _any_tests_failed {
    my $failed  = 0; 
    my $builder = Test::Builder->new;
    my @summary = $builder->summary;
    foreach my $passed (
        @summary[ $builder->{'Test::Aggregate::Builder'}{last_test} 
            ..
        $builder->current_test - 1 ]
    ) {
        if (not $passed) {
            $failed = 1;
            last;
        }
    }
    return $failed;
}

sub run_this_test_program {
    my $builder = Test::Builder->new;
    my ( $package, $test, $current_test, $num_tests, $verbose ) = @_;
    Test::More::diag("******** running tests for $test ********") if $ENV{TEST_VERBOSE};
    my $error = eval { 
        if ( my $reason = $builder->{'Test::Aggregate::Builder'}{skip_all}{$package} ) {
            $builder->skip($reason);
            return;
        }
        else {
            local $@;
            # localize some popular globals
            no warnings 'uninitialized';
            local %ENV = %ENV;
            local $/   = $/;
            local @INC = @INC;
            local $_   = $_;
            local $|   = $|;
            local %SIG = %SIG;
            use warnings 'uninitialized';
            $builder->{'Test::Aggregate::Builder'}{file_for}{$package} = $test;
            local $builder->{'Test::Aggregate::Builder'}{running} = $package;
            eval { $package->run_the_tests };
            if ($@ && ref($@) && $@ == $Test::Aggregate::Builder::skip) {
                $builder->skip( $builder->{'Test::Aggregate::Builder'}{skip_all}{$package} );
                return;
            }
            $@;
        }
    };

    {
        my $test_name = "$test ($current_test out of $num_tests)";
        my $failed    = _any_tests_failed();
        chomp $error if defined $error;
        $error &&= "($error)";
        my $ok = $failed || $error
                ? "not ok - $test_name $error"
                : "    ok - $test_name";
      # don't diag if verbose is zero
      if( $verbose ){
        Test::More::diag($ok) if $error or $failed or $verbose == $VERBOSE{all};
      }
        # but do register as a failure
        if ($error or $failed) {
            Test::More::ok(0, "Error running ($test):  $error");
            # XXX this should be fine since these keys are not actually used
            # internally.
            $builder->{XXX_test_failed}       = 0;
            $builder->{TEST_MOST_test_failed} = 0;
        }
    }
    $builder->{'Test::Aggregate::Builder'}{last_test} = $builder->current_test;

    return unless $error;
}

sub _build_aggregate_code {
    my ( $self, @tests ) = @_;
    my $code = "\n# Built from $0\n";
    $code .= $self->_test_builder_override;

    my ( $startup,  $startup_code )  = $self->_as_code('startup');
    my ( $shutdown, $shutdown_code ) = $self->_as_code('shutdown');
    my ( $setup,    $setup_code )    = $self->_as_code('setup');
    my ( $teardown, $teardown_code ) = $self->_as_code('teardown');
    
    my $verbose = $self->_verbose;
    my $findbin;
    if ( $self->_findbin ) {
        $findbin = <<'        END_CODE';
use FindBin;
my $REINIT_FINDBIN = FindBin->can(q/again/) || sub {};
        END_CODE
    }
    else {
        $findbin = 'my $REINIT_FINDBIN = sub {};';
    }
    $code .= <<"    END_CODE";
$startup_code
$shutdown_code
$setup_code
$teardown_code
$findbin
    END_CODE
    
    my @packages;
    my $separator = '#' x 20;
    
    my $test_packages = '';

    my $dump = $self->_dump;

    $code .= "if ( __FILE__ eq '$dump' ) {\n";

    if ( $startup ) {
        $code .= "    $startup->() if __FILE__ eq '$dump';\n";
    }

    my $current_test = 0;
    my $total_tests  = @tests;
    foreach my $test (@tests) {
        $current_test++;
        my $test_code = $self->_slurp($test);

        # get rid of hashbangs as Perl::Tidy gets all huffy-like and we
        # disregard them anyway.
        $test_code =~ s/\A#![^\n]+//gm;

        # Strip __END__ and __DATA__ if there's nothing after it.
        # XXX leaving this out for now as I'm unsure if it's worth it.
        #$test_code =~ s/\n__(?:DATA|END)__\n$//s;

        if ( $test_code =~ /^(__(?:DATA|END)__)/m ) {
            Test::More::BAIL_OUT("Test $test not allowed to have $1 token (Test::Aggregate::Nested supports them)");
        }

        my $package   = $self->_get_package($test);
        push @{ $self->{_packages} } => [ $test, $package ];
        if ( $setup ) {
            $code .= "    $setup->('$test');\n";
        }
        $code .= qq{    run_this_test_program( $package => '$test', $current_test, $total_tests, $verbose );};

        if ( $teardown ) {
            $code .= "    $teardown->('$test');\n";
        }
        $code .= "\n";

        my $set_filenames = $self->_set_filenames
            ? "local \$0 = '$test';"
            : '';

        $test_packages .= <<"        END_CODE";
{
$separator beginning of $test $separator
    package $package;
    sub run_the_tests {
        $set_filenames
        \$REINIT_FINDBIN->();
# line 1 "$test"
$test_code
    }
$separator end of $test $separator
}
        END_CODE
    }
    if ( $shutdown ) {
        $code .= "    $shutdown->() if __FILE__ eq '$dump';\n";
    }
    
    $code .= "}\n";
    $code .= $test_packages;
    if ( my $tidy = $self->_tidy ) {
        eval "use Perl::Tidy";
        my $error = $@;
        my $dump = $self->_dump;
        if ( $error && $dump ) {
            warn "Cannot tidy dumped code:  $error";
        } 
        elsif ( !$error ) {
            my @output;
            my @tidyrc = -f $tidy
                ? ( perltidyrc => $tidy )
                : ();
            Perl::Tidy::perltidy(
                source      => \$code,
                destination => \@output,
                @tidyrc,
            );
            $code = join '' => @output;
        }
    }
    return $code;
}

sub _as_code {
    my ( $self, $name ) = @_;
    my $method   = "_$name";
    return ( '', '' ) if $self->_no_streamer;
    my $code     = $self->$method || return ( '', '' );
    $code = Data::Dump::Streamer::Dump($code)->Indent(0)->Out;
    my $sub_name = "\$TEST_AGGREGATE_\U$name";
    $code =~ s/\$CODE1/$sub_name/;
    return ( $sub_name, <<"    END_CODE" );
my $sub_name;
{
$code
}
    END_CODE
}

sub _slurp {
    my ( $class, $file ) = @_;
    local *FH;
    open FH, "< $file" or die "Cannot read ($file): $!";
    return do { local $/; <FH> };
}

sub _test_builder_override {
    my $self = shift;

    my $disable_test_nowarnings = '';
    if ( !$self->_test_nowarnings ) {
        $disable_test_nowarnings = <<'        END_CODE';
# Look ma, no import!
BEGIN {
    require Test::NoWarnings;
    no warnings 'redefine';
    *Test::NoWarnings::had_no_warnings = sub { };
    *Test::NoWarnings::import = sub {
        my $callpack = caller();
        my $ta_builder = $BUILDER->{'Test::Aggregate::Builder'};
        if ( $ta_builder->{plan_for}{$callpack} ) {
            $ta_builder->{plan_for}{$callpack}--;
        }
        $ta_builder->{test_nowarnings_loaded}{$callpack} = 1;
    };
}
        END_CODE
    }

    return <<"    END_CODE";
use Test::Aggregate;
use Test::Aggregate::Builder;
my \$BUILDER;
BEGIN { 
    \$BUILDER = Test::Builder->new;
};
$disable_test_nowarnings;
    END_CODE
}

=head1 SETUP/TEARDOWN

Since C<BEGIN> and C<END> blocks are for the entire aggregated tests and not
for each test program (see C<CAVEATS>), you might find that you need to have
setup/teardown functions for tests.  These are useful if you need to setup
connections to test databases, clear out temp files, or any of a variety of
tasks that your test suite might require.  Here's a somewhat useless example,
pulled from our tests:

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 
 use lib 'lib', 't/lib';
 use Test::Aggregate;
 use Test::More;
 
 my $dump = 'dump.t';
 
 my ( $startup, $shutdown ) = ( 0, 0 );
 my ( $setup,   $teardown ) = ( 0, 0 );
 my $tests = Test::Aggregate->new(
     {
         dirs     => 'aggtests',
         dump     => $dump,
         startup  => sub { $startup++ },
         shutdown => sub { $shutdown++ },
         setup    => sub { $setup++ },
         teardown => sub { $teardown++ },
     }
 );
 $tests->run;
 is $startup,  1, 'Startup should be called once';
 is $shutdown, 1, '... as should shutdown';
 is $setup,    4, 'Setup should be called once for each test program';
 is $teardown, 4, '... as should teardown';

Note that you can still dump these to a dump file.  This will only work if
C<Data::Dump::Streamer> 1.11 or later is installed.

There are four attributes which can be passed to the constructor, each of
which expects a code reference:

=over 4

=item * C<startup>

 startup => \&connect_to_database,

This function will be called before any of the tests are run.  It is not run
in a BEGIN block.

=item * C<shutdown>

 shutdown => \&clean_up_temp_files,

This function will be called after all of the tests are run.  It will not be
called in an END block.

=item * C<setup>

 setup => sub { 
    my $filename = shift;
    # this gets run before each test program.
 },

The setup function will be run before every test program.  The name of the
test file will be passed as the first argument.

=item * C<teardown>

 teardown => sub {
    my $filename = shift;
    # this gets run after every test program.
 }

The teardown function gets run after every test program.  The name of the test
file will be passed as the first argument.

=back

=head1 GLOBAL VARIABLES

You shouldn't be using global variables and a dependence on them can break
your code.  However, Perl provides quite a few handy global variables which,
unfortunately, can easily break your tests if you change them in one test and
another assumes an unchanged value.  As a result, we localize many of Perl's
most common global variables for you, using the following syntax:

    local %ENV = %ENV; 
    
The following global variables are localized for you.  Any others must be
localized manually per test.

=over 4

=item * C<@INC>

=item * C<%ENV>

=item * C<%SIG>

=item * C<$/>

=item * C<$_>

=item * C<$|>

=back

=head1 CAVEATS

Not all tests can be included with this technique.  If you have C<Test::Class>
tests, there is no need to run them with this.  Otherwise:

=over 4

=item * C<exit>

Don't call exit() in your aggregated tests.  We now warn very verbosely if
this is done, but we still exit on the assumption that further tests cannot
run.

=item * C<__END__> and C<__DATA__> tokens.

These won't work and the tests will call BAIL_OUT() if these tokens are seen.
However, this limitation does not apply to L<Test::Aggregate::Nested>.

=item * C<BEGIN> and C<END> blocks.

Since all of the tests are aggregated together, C<BEGIN> and C<END> blocks
will be for the scope of the entire set of aggregated tests.  If you need
setup/teardown facilities, see L<SETUP/TEARDOWN>.

=item * Syntax errors

Any syntax errors encountered will cause this program to BAIL_OUT().  This is
why it's recommended that you move your tests into your new directory one at a
time:  it makes it easier to figure out which one has caused the problem.

=item * C<no_plan>

Unfortunately, due to how this works, the plan is always C<no_plan>.
L<http://groups.google.com/group/perl.qa/browse_thread/thread/d58c49db734844f4/cd18996391acc601?#cd18996391acc601>
for more information.

=item * C<Test::NoWarnings>

Great module.  It loves to break aggregated tests since some might have
warnings when others will not.  You can disable it like this:

 my $tests = Test::Aggregate->new(
     dirs    => 'aggtests/',
     startup => sub { $INC{'Test/NoWarnings.pm'} = 1 },
 );

As an alternative, you can also disable it with:

 my $tests = Test::Aggregate->new({
    dirs            => 'aggtests',
    test_nowarnings => 0,
 });

We do work internally to subtract the extra test added by C<Test::NoWarnings>.
It's painful and experimental.  Good luck.
    
=item * C<Variable "$x" will not stay shared at (eval ...>

Because each test is wrapped in a method call, any of your subs which access a
variable in an outer scope will likely throw the above warning.  Pass in
arguments explicitly to suppress this.

Instead of:

 my $x = 17;
 sub foo {
     my $y = shift;
     return $y + $x;
 }

Write this:

 my $x = 17;
 sub foo {
     my ( $y, $x ) = @_;
     return $y + $x;
 }

However, consider L<Test::Aggregate::Nested>.  This warning does not apply
with that module.

=item * Singletons

Be very careful of code which loads singletons.  Oftimes those singletons in
test suites may be altered for testing purposes, but later attempts to use
those singletons can fail dramatically as they're not expecting the
alterations.  (Your author has painfully learned this lesson with database
connections).

=back

=head1 DEBUGGING AGGREGATE TESTS

Before aggregating tests, make sure that you add tests B<one at a time> to the
aggregated test directory.  Attempting to add many tests to the directory at
once and then experiencing a failure means it will be much harder to track
down which tests caused the failure.

Debugging aggregated tests which fail is a multi-step process.  Let's say the
following fails:

 my $tests = Test::Aggregate->new(
     {
         dump    => 'dump.t',
         shuffle => 1,
         dirs    => 'aggtests',
     }
 );
 $tests->run;

=head2 Manually run the tests

The first step is to manually run all of the tests in the C<aggtests> dir.

 prove -r aggtests/

If the failures appear the same, fix them just like you would fix any other
test failure and then rerun the C<Test::Aggregate> code.

Sometimes this means that a different number of tests run from what the
aggregted tests run.  Look for code which ends the program prematurely, such
as an exception or an C<exit> statement.

=head2 Run a dump file

If this does not fix your problem, create a dump file by passing 
C<< dump => $dumpfile >> to the constructor (as in the above example).  Then
try running this dumpfile directly to attempt to replicate the error:

 prove -r $dumpfile

=head2 Tweaking the dump file

Assuming the error has been replicated, open up the dump file.  The beginning
of the dump file will have some code which overrides some C<Test::Builder>
internals.  After that, you'll see the code which runs the tests.  It will
look similar to this:

 if ( __FILE__ eq 'dump.t' ) {
     Test::More::diag("******** running tests for aggtests/boilerplate.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestsboilerplatet->run_the_tests;

     Test::More::diag("******** running tests for aggtests/subs.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestssubst->run_the_tests;

     Test::More::diag("******** running tests for aggtests/00-load.t ********")
        if $ENV{TEST_VERBOSE};
     aggtests00loadt->run_the_tests;

     Test::More::diag("******** running tests for aggtests/slow_load.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestsslow_loadt->run_the_tests;
 }

You can try to narrow down the problem by commenting out all of the
C<run_the_tests> lines and gradually reintroducing them until you can figure
out which one is actually causing the failure.

=head1 COMMON PITFALLS

=head2 My Tests Threw an Exception But Passed Anyway!

This really isn't a C<Test::Aggregate> problem so much as a general Perl
problem.  For each test file, C<Test::Aggregate> wraps the tests in an eval
and checks C<< my $error = $@ >>.  Unfortunately, we sometimes get code like
this:

  $server->ip_address('apple');

And internally, the 'Server' class throws an exception but uses its own evals
in a C<DESTROY> block (or something similar) to trap it.  If the code you call
uses an eval but fails to localize it, it wipes out I<your> eval.  Neat, eh?
Thus, you never get a chance to see the error.  For various reasons, this
tends to impact C<Test::Aggregate> when a C<DESTROY> block is triggered and
calls code which internally uses eval (e.g., C<DBIx::Class>).  You can often
fix this with:

 DESTROY {
    local $@ = $@;  # localize but preserve the value
    my $self = shift;
    # do whatever you want
 }

=head2 C<BEGIN> and C<END> blocks

Remember that since the tests are now being run at once, these blocks will no
longer run on a per-test basis, but will run for the entire aggregated set of
tests.  You may need to examine these individually to determine the problem.
  
=head2 C<CHECK> and C<INIT> blocks.

Sorry, but you can't use these (just as in modperl).  See L<perlmod> for more
information about them and why they won't work.

=head2 C<Test::NoWarnings>

This is a great test module.  When aggregating tests together, however, it can
cause pain as you'll often discover warnings that you never new existed.  For
a quick fix, add this before you attempt to run your tests:

 $INC{'Test/NoWarnings.pm'} = 1;

That will disable C<Test::NoWarnings>, but you'll want to go in later to fix
them.

=head2 Paths

Many tests make assumptions about the paths to files and moving them into a
new test directory can break this.

=head2 C<$0>

Tests which use C<$0> can be problematic as the code is run in an C<eval>
through C<Test::Aggregate> and C<$0> may not match expectations.  This also
means that it can behave differently if run directly from a dump file.

As it turns out, you can assign to C<$0>!  We do this by default and set the
C<$0> to the correct filename.  If you don't want this behavior, pass 
C<< set_filenames => 0 >> to the constructor.

=head2 Minimal test case

If you cannot solve the problem, feel free to try and create a minimal test
case and send it to me (assuming it's something I can run).

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

    perldoc Test::Aggregate

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

1;
