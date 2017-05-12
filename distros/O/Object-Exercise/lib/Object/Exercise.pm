#######################################################################
# housekeeping
#######################################################################

package Object::Exercise;
use v5.20;

use Symbol qw( qualify qualify_to_ref );

use Object::Exercise::Execute;

########################################################################
# package variables
########################################################################

our $VERSION    = '3.00';
$VERSION        = eval "$VERSION";

########################################################################
# subroutines
########################################################################

sub import
{
    state $init     = \&Object::Exercise::Execute::import_flags;
    state $handler  = \&Object::Exercise::Execute::exercise;

    my $caller  = caller;

    # ignore the current package

    shift;

    my $export  = &$init;

    # install the handler as scalar ref not a sub ref so that
    # they get $exercise as a subref.

    *{ qualify_to_ref $export => $caller } = \$handler;

    return
}

# keep require happy
1
__END__

=head1 NAME

Object::Exercise - Generic execution & benchmark harness
for method calls.

=head1 SYNOPSIS

    use Object::Exercise;

    # at this point $exercise is defined as a 
    # coderef to execute the tests.

    my @test_opz =
    (
        [
            # no arrayref: call $obj->$method( @argz )
            # check for $@ with message of method and args.

            qw( method arg arg arg )
        ],

        [
            # two arrayrefs:
            # [ method and args ], 
            # [ compare values ]

            [ method arg arg arg ... ]
            [ 1 ],
        ],

        [
            # if a method is expected to fail, store
            # a literal 'undef' as the second element.
            
            [ qw( method expected to fail ) ]
            undef,
        ],

        [
            # use a pre-defined message rather than
            # join the method and args.

            [ method => @argz ],
            [ ( 1 .. 10 )     ],
            'Coderef returns list'
        ],

        [
            # use a coderef to dispatch the call rather
            # than a method name.
            #
            # storing a literal undef as an array value
            # checks for an undef -- vs. ignoring the 
            # return value in the example above.

            [ $subref, @argz ],
            [ undef ],
            'Coderef returns list'
        ],

        [
            # compare the method return via regex
            # effectively:
            # $obj->Foobar( @argz ) =~ qr/Foo.*Bar/

            [ method => @argz ],
            qr/Foo.*Bar/,
            'method returns text of Foo ... Bar'
        ],

        [
            # compare the return via user-supplied 
            # filter (instead of cmp_deeply).

            [ method => @argz ],
            $subref
        ],

        # turn on verbosity

        q{verbose}, 

        # subref is called to validate the result when static
        # values get messy (e.g., database testing or when the
        # return contains a timestamp or using a closure 
        # computed when the arguments are constructed).

        [
            [ blah_blah => ( 'a' .. 'z' ) ],
            \&validate_blah_blah,
            'Validate blah_blah'
        ],


        # turn off verbosity

        q{noverbose}

        # turn on/off a breakpoint prior to execution or if the
        # next step returns an error.

        ...

        # set a breakpoint via $DB::single = 1 prior to calling
        # $object->$method for all following tests.

        q{break},

        [
            # for this one test: 
            # set a breakpoint after calling $object->$method 
            # iff $@ is true via $DB::single = 1 if $error;
            # also make this one test verbose.

            debug   =>
            verbose =>

            [ frobnicate => @frob_argz          ],
            [ 'eeny', 'meene', 'minie', 'moe'   ],
            [ "Frobnicate returns gibberish"    ]
        ],
        [
            # YAML::XS has problems (a.k.a. segfaults) 
            # handling stored regexen. simplest workaround
            # is setting a flag to treat non-ref expect values
            # as bare regexen and feed them through qr{}x.

            [
                regex =>
                [
                    'get_title'
                ],
                YAPC =>
                "Title includes 'YAPC'"
            ],
        ],
    );

    # stack tests: 
    # "noplan" skips calling "plan" with number of tests.
    # "nofinish" skips calling "done_testing" after current plan.
    #
    # this leaves it up to the caller to call "done_testing"
    # or call exercise with "finish" set to true.

    $obj->$exercise ( qw( nofinish ) );

    $obj->$exercise( @plan1 );
    $obj->$exercise( @plan2 );
    $obj->$exercise( @plan3 );

    $obj->$exercise ( 'finish' );   # call's done testing.

    # You can push the operations through as
    # class or object methods.

    YourClass->$exercise( @test_opz );

    my $object = YourClass->new( @whatever );

    $object->$exercise( @test_opz );

    # or just

    YourClass->new( @blah )->$exercise( @test_opz );

    # sometimes it is simpler to pass the tests in as an arrayref
    # or as flat YAML text. A single arrayref on the stack will be
    # expanded in-place to get the tests, a single non-ref scalar
    # will be treated as YAML.
    #
    # this makes it easy to store an arrayref as text or YAML in
    # the test body:

    my $plan    = do { local $/; eval <DATA> };
    $obj->$exercise( $plan );

    __DATA__
    # or this could be a perly arrayref in Dumper format.

    ---
    - noplan
    - - verbose
      - - prepare_test
        - - get
          - http://www.google.com
        - - set_implicit_wait_timeout
          - 50000
    ...
 

=head1 DESCRIPTION

This package exports a single subroutine , C<$exercise>, which
functions as an OO execution loop (see 'export' for changing the
installed name).

C<$execute> is a subroutine reference that takes an object
and set of operations. The first element in that list
is an object of the class being tested. The remaining
elements are a list of operations, each of which is an
array reference.

Each operation consists of a method call and the method's arguments. Each
method call is dispatched using the object, optionally comparing the return
value to some pre-defined result.

Exceptions are trapped and logged. The last operation can be re-executed if
it fails.

All operations are passed in as arrayrefs. They can be nested either to store
a return value and test to run, or to hold a list consisting of a method name
and its arguments.

=head2 Arguments for "use Object::Exercise"

=over 4

=item install=<yourname> (default "execute")

Default is to install '$execute', any alternate variable
name can be selected.

=item benchmark (default 0)

This writes out the wallclock time to four decimal places
(from Time::Hires) for each entry executed.

This can be set inline via [no]benchmark:

    [ ... ],

    # showing elapsed time for only one test:

    'benchmark',

    [ ... ],

    'nobenchmark',

=item verbose (default 0)

Turn on additinal progress messages, printing them
to stderr so that they show up even if prove is not
running in verbose mode. 

This can be switched innline via "verbose" or "noverbose".

=item continue (default 1)

Continue execution after failures. Turning this off
aborts after the first execption, which may interfere
with test counts (see also "plan", next).

The main use of this is setting "nocontinue" in cases
where some initial setup steps failing will force the
remaining steps to fail. 

=item plan (default 1)

Normally an initial count of the tests is used generate
a test plan. If this is specified then no plan is used.
This can be helpful when used with "nocontinue".

=item debug (default 0)

This sets a breakpoint if an execption is raised calling
the method. The line following this breakpoint is:

    $obj->$method( @$argz );

which can be used to immediately check why a call failed.

=back

=head1 Exercising Objects

The setup code for a typical test file is frequently repetitive.  We have to
code for the object and each of a collection of method calls. We frequently
have to check return values and exception statuses.

This leads to blocks of code like this:

  my $obj = Package::New->( ... );

  if( defined ( my $return = eval { $obj->method_1( @args_1 ) } ) )
  {
    @$return == 3 or die "...";

    cmp_deeply $return, [ ... ], "Failed comparing @argz_1: ...";

  }
  elsif( $@ )
  {
    die "Failed execution of method_1 ...";
  }
  else
  {
    die "Undef returned from method_1 ..."
  }

  eval { $obj->method_2( @args_2 ) };

  if( $@ )
  {
    die "Failed execution of method_2 ...";
  }
  ...

The only thing that really varies about any of these
are the return values, method name, and arguments.

Object::Exercise reduces all of this to a list of
methods and arguments, with optional data validation:


  [ method => @args ],      # single flat list in arrayref

or

  [
    [ method => @args ]     # same method + arguments
    [ 3 ],                  # with added return value check
  ],


In both cases $@ is checked on return; in the second
case Test::Deep::cmp_deeply is used to validate the
returned data.

=head2 Test vs. Run-Only Operations

There are two types of operations: tests and run-only.
Tests have a hard-coded value that is compared with the
method call's return value; the return value of a run-only
operation is ignored.

=over 4

=item Tests

These are nested arrayrefs:

  [
    [ $method => @args  ],
    [ expected return   ],
    'optional message'
  ],

The return value can be any sort of structure but must
be enclosed in an arrayref. The test is run via:

  my $result = [ $object->$method( @argz ) ];

  cmp_deeply $result, $expected, $message;

This leaves any method called in a list context with
the result put into an arryref. This means that the
expected value for a call that returns arrayrefs will
look like:

  [
    [ $method => @argz ],
    [ # outer arrayref stored return value

      [ # return value is itself an arrayref ]
    ],
  ],

If the method returns hashrefs in list context then
use something like:

  [
    [ $method => @argz ],
    [
        # outer arrayref stored return value
        # inner value is the hashref expected value.

      { ...  }
    ],
  ],

The default C<ok> message is formed by joining the
method and arguments on whitespace. This can lead to
prove issuing lines like:

  ok save foobar HASH(0x123456) (999)

but usually gives at least recognizable results.

To override this, simply supply a message of your own:

  [
    [ $method => @argz ],
    [ { # return value is itself an hashref } ],
    'Remember: This should return a hashref!'       # your message
  ],

=item Testing Known Failures

Sometimes it is useful to test how the code handles
invalid requests. In these cases the test will fail.
Normally, executing a method that returns with C<$@> set
will be logged as a failed test. If the expected value
is an empty array ref (i.e., nothing was expected back)
then the C<$@> will be logged as passed.

These tests look like:

  [
    [ qw( method designed to fail ) ]
    '',
  ],

  [
    [ qw( method designed to fail ) ]
    undef,
  ],

This will give a message like:

  ok save foobar HASH(0x123456) expected failure (999)


=item Run-Only Items

These consist simply of a method and its arguments:

  [ method => arg, arg, ...  ],

A method with no arguments is a one-liner:

  [ method ]

which leads to:

  $object->$method()

These are called in a void context, so if the method
checks C<wantarray> it will get undef. This may affect
the execution of some methods, but usually will not
(normal tests are C<wantarray ? a : b> without the
separate test for C<defined>).

=back

=item Coderefs

Coderef's are dispatched as standard method calls:

    my $coderef = sub { ... };  # or \&somesub

    [
        [ $coderef, @argz ],
        [ ... ]
    ]

is executed as:

    $obj->$coderef( @argz )

this allows dispatching the object outside of its class,
say to a utility function that does some extra data checking,
logging, or updates the module. These are especially useful
for updating the object state during execution.

=head2 Re-Running Failed Operations

Operations are deemed to fail if they raise an
exception (I<i.e.>, C<$@> is set at their completion) or if
the return value does not compare deeply to expected
data (if provided).

In either case, it is often helpful to examine the
failed operation. This is accomplished here by
wrapping each exectution in a closure:

  my $cmd
  = sub
  {
    $DB::single = 1 if $debug;

    $obj->$method( @argz )
  };

These closures are C<eval>-ed one at a time and then compared
to expected values as necessary. If the operation raises
an exception or the test fails then C<$debug> is set to true
and a breakpoint is set in the main loop. This allows code
run in the perl debugger to re-execute the failed
operation in single-step mode and see exactly what failed
without having to single-step through all of the
successful operations.

For example:

  perl -d harness_code.t;

will stop execution at the first failed operation, allowing
a single C<s> to step into the C<< $obj->$method( @argz ) >> call.

=head2 Harness Directives

There are times when you want to control the execution
or harness arguments as it is running. The directives
are processed by the harness itself. These can set a
breakpoint prior to calling one of the methods, adjust
the verbosity, set the continue switch, or set an object
value.

=head3 Messages

Sometimes it's reassuring to know progress is being
make (or it's helpful to keep a log of what happend).

Non-referent entries in the test list that aren't
recognized are simply printed:

    ...

    "Updating based on $computed value...",

    [
        [ foobar  => $computed_value ],
        ...
    ]

    "... Finished Computed value update.",

will sandwich a method call between two messages.

=head3 Breakpoints

It is sometimes helpful to stop the execution of code
before it fails in order to examine its execution before
the failure. The "break" directive will set the breakpoint
before the first method call. This will leave you at
$obj->$method( @argz ) (see below under DEBUGGING).

For example, this will run up to the point where
"frobnicate" is about to be called and then stop:

  [
    ...

    'break',

    [
      [ qw( frobnicate foo ) ],
      [ 3 ],
    ]

    'nobreak',
  ],

This leaves the perl debugger at the line:

    my $result = [ $obj->$method( @$argz ) ];

Until "nobreak" is used all calls will hit the 
breakpoint.

=head3 Turning off comparison breakpoints.

Normal behavior for Object::Exercise is to abort the
execution plan when the first $@ or cmp_deeply failure
is encountered. The behavior can be changed to continue
execution via the "continue" directive (or set via the
"-k" switch when the module is used). Inserting "nocontinue"
will turn back on the normal behavior.

This can be helpful when initial operations need to clean
up before starting: failures can be ignored until some
set of sanity checks.

    ...
    'continue',

    [ cleanup that may fail.  ],
    [ cleanup that may fail.  ],

    'nocontinue',

    [ sanity check ]

Execution will log any failures through the "nocontinue"
line as expected failures, something like:

  ok 1 - modify label field_x xyz => xyz
  ok 2 - lookup label field_x => xyz
* ok 3 - modify label field_x => expected exception
  ok 4 - lookup label field_x => xyz

=head1 DEBUGGING FAILED OPERATIONS

Re-run a failed operation:

  $ perl -d ./t/some-test.t;

  ok ...
  ok ...
  ok ...

  ...

  Failed execution:
  <failure message>

  47:       0
    DB<1> &$cmd

  Metadata::t::Harness::CODE(0x8ada248):
  184:              $obj->$method( @argz )
    DB<<2>> s

At this point you will be at the first line of $method
(given sub or coderef location). The failure message
will show up for $@ set after calling the method or
if cmp_deeply finds a discrepency in the result.


=head1 EXAMPLES

Aside: Yes I know we need more of these...

    my $field2 = 'field_x';


    my @opz =
    (
        # evaluate expected failures

        # modify is expected to fail, but the empty
        # arrayref is a signal that nothing is expected
        # back from the test.

        [
            [ drop =>   ( $field_2 ) ],                 # pre-cleanup
            ''                                          # ignore failre
        ],

        [
            [ write =>  ( label => $field2, 'xyz' ) ],
            [ 'xyz'                                 ],  # expect 'xyz'
        ],

        [
            [ read =>   ( label => $field2 )        ],
            [ qw( xyz )                             ],  # expect 'xyz'
        ],

        [
            [ write =>  ( label => $field2, '' )    ],  # invalid argument:
            '',                                         # expect failure
        ],

        [
            [ read =>   ( label => $field2 )        ],
            [ qw( xyz )                             ],  # expect 'xyz'
        ],

    );

    $execute->( $object, @opz );


=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2007-2015 Steven Lembark.
This code is released under the same terms as Perl-5.22 or any
later version of Perl.

