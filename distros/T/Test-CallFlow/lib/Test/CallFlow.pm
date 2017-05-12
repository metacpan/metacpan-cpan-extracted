package Test::CallFlow;

use warnings;
use strict;
use UNIVERSAL qw(can isa);
use Carp;
use Exporter;
use File::Spec;
use Test::CallFlow::Plan;
use Test::CallFlow::Call;
use Test::CallFlow::ArgCheck::Any;
use vars
    qw(@ISA @EXPORT_OK %EXPORT_TAGS $recording $planning $running @instances %state @state);

=head1 NAME

Test::CallFlow - trivial planning of sub call flows for fast unit test writing.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Mock packages for planning expected interactions in tests:

    use Test::CallFlow qw(:all);

    my $mocked = mock_object( 'My::Mocked::Package::Name' );
    $mocked->my_method( arg_any(0,9) )->result( 'return value' );

    mock_run();

    die "test did not return right value"
      if $mocked->my_method( 'any', 'arguments' ) ne 'return value';

    mock_end();
    
=head1 USAGE

C<Test::CallFlow> functions are used here in a procedural manner
because straightforward test scripts are seen as primary use case.
As well you may create objects with C<new()> and use the provided
functions as object methods.

=head2 DECLARING

    use Test::More plan_tests => 1;
    use Test::CallFlow qw(:all);

    # just mock a package
    mock_package( 'Just::Mocked' );

    # mock a package and make an object of it
    my $mocked = mock_object(
        'My::Mocked::Package::Name',          # must specify package name
        { 'optional' => 'content' } );        # may specify what to bless

=head2 PLANNING

    Just::Mocked->new()                       # no arguments
                ->result( $mocked );          # return the mock object

    my $get_call =                            # refer to this Test::CallFlow::Call object
        $mocked->get( "FieldX" )              # one equal string argument
             ->result( 1, 2, 3 )              # return array ( 1, 2, 3 ) on first call
             ->result( 4, 5, 6 )              # return array ( 4, 5, 6 ) on second call
             ->result( 7, 8, 9 )              # return array ( 7, 8, 9 ) on any subsequent calls
             ->min(0)                         # this call is optional
             ->max(9)                         # this call can be made at most 9 times
             ->anytime;                       # may be called at this step or any time later

    $mocked->set( arg_check( qr/^Field/ ),    # first argument matching regular expression
                  arg_any( 1, 99 ) );         # 1-99 arguments with any values
                                              # return nothing (undef or empty array)

    $mocked->save( arg_check( \&ok_file ) )   # use own code to check argument
             ->end( $get_call );              # end scope: $get_call can be made no more

    # if you wish to use parts of the real package unmocked as is,
    # load it after planning but before running:
    use My::Mocked::Package::Name;
    
    # remember that nothing keeps you from still just adding your own:
    
    package My::Mocked::Package::Name;
    
    sub really_customized {} # skipping mock system

    package main; # remember to end your own package definition

=head2 RUNNING

    mock_run();  # flow of calls from test planned, now prepare to run the test(s)

    eval {

      # package was already declared as loaded at mock_run()
      # so code under test may freely try to 'use' it
      use My::Mocked::Package::Name;

      code_under_test();  # dies on any unplanned call to a mocked package or sub

      mock_end(); # dies if any expected calls were not made and reports them
    };

    is( $@, '', "code_under_test() executed according to prepared plan" );
    
    mock_clear(); # flush state, plan and mocks so you may plan another test call flow

=head2 RECORDING

To make it easier to start refactoring existing complicated legacy code,
C<Test::CallFlow> also provides preliminary sub call recording functionality:

    # load the packages used by code under test first
    use My::Mocked::Package::Name;
    use Other::Mocked::Package;

    # then declare them for mocking; this saves the original subs aside
    mock_package( 'My::Mocked::Package::Name', 'Other::Mocked::Package' );

    # start recording
    record_calls_from( 'Package::Under::Test' );
    
    # now calls to mocked packages will be made and recorded with their args and results
    use Package::Under::Test;
    Package::Under::Test->code_under_test();
    
    # generate code to serve as basis for your test run
    print join ";\n", map { $_->name() } mock_plan()->list_calls();

=head2 OBJECT ORIENTED USAGE

C<Test::CallFlow> is actually object-oriented; default instance creation is hidden.
Usability of multiple simultaneous mock objects is hindered by Perl global package namespace.
Only one object may be used for recording, planning or running at a time.
A separate object can be used for each of those tasks simultaneously as long as they don't mock same packages.
Just do one thing at a time and C<mock_clear()> straight after to steer clear of any problems.

  use Test::CallFlow;
  
  my $flow = Test::CallFlow->new(
        autoload_template => '' # do not declare AUTOLOAD, use explicit mock_call()s only
  );

  $flow->mock_package( 'Just::Mocked' );
  $flow->mock_call( 'Just::Mocked::new', 'Just::Mocked' )->result( bless( {}, 'Just::Mocked' ) );
  $flow->mock_run;
  print Just::Mocked->new;
  $flow->mock_end;

=cut

BEGIN {
    @ISA = qw(Exporter);
    @EXPORT_OK =
        qw(mock_package mock_object mock_run mock_end mock_reset mock_clear mock_call mock_plan arg_check arg_any record_calls_from);
    %EXPORT_TAGS = ( all => [@EXPORT_OK], );

}

=head1 PACKAGE PROPERTIES

=over 4

=item %Test::CallFlow::state

Map of state names to state IDs. Used to refer to flow object states:

  unknown, record, plan, execute, failed, succeeded.

=item @Test::CallFlow::state

List of state names. Used to get printable name for state IDs.

=item %Test::CallFlow::prototype

Contains default values for instance properties.

=item @Test::CallFlow::instance

Array of created instances. Used by mocked methods to locate the related instance responsible of building and following the plan, ie. checking the call and providing right result to return.

=back

=cut

my $i = 0;
%state = map { $_ => $i++ } @state =
    qw(unknown record plan execute failed succeeded);

=head1 INSTANCE PROPERTIES

Default properties are defined in C<%Test::CallFlow::prototype>.
They may be specified as parameters for C<new>
or environment variables with prefix C<mock_>, such as C<mock_save>.

Template texts below may contain C<#{variablename}> placeholders that will be
replaced by context-specific or C<Test::CallFlow> object property values.

=head2 TEMPLATE PROPERTIES

These may be useful for heavier customizations, although it'll probably be easier to just
define more hairy mock package parts straight in the test script.

=over 4

=item package_template

Template text for mock package definitions. See code for contents.

=over 8

=item C<#{packagename}> placeholders will be replaced by name of package to mock.

=item C<#{subs}> placeholders will be replaced by sub definitions.

=back

=item sub_template

Template for code to put into mocked subs.

=over 8

=item C<#{packagename}> placeholders will be replaced by name of package to mock.

=item C<#{subname}> placeholders will be replaced by name of sub to mock.

=back

=item autoload_template

Template for code to put into mocked AUTOLOAD subs.

=item package_definition_template

Template for package definition at C<mock_run>.

Default value contains redefinition warning suppression
and expects C<#{packagebody}> variable to contain actual mock package definition.

=back

=head2 INTERNAL PROPERTIES

These are set and used at planning and runtime.

=over 4

=item state

One of C<%Test::CallFlow::state> values.

Default is C<plan>.
C<mock_run()> sets state to C<execute>.
C<mock_end> sets it to C<succeeded> - or C<failed> if more calls were expected.
Failure in a mock call sets it to C<failed>.
C<mock_clear> and C<mock_reset> unconditionally set it back to C<plan>.

=item id

Index of this object in C<@Test::CallFlow::instances>.

=item packages

Contains data about packages and subs to mock gathered from calls in planning mode.

=item plan

Call execution plan as a C<Test::CallFlow::Plan> object containing C<Test::CallFlow::Call> objects.

=item record_calls_from

Hash of package names created by C<record_calls_from()> for checking which calls to record during recording.

=back

=head2 DEBUGGING PROPERTIES

=over 4

=item debug

Controls debug information printing.
Class names in this string cause debugging info to be printed from them.
Options are: C<Mock>, C<Plan>, C<Call>, C<ArgCheck>. Derived from C<$ENV{DEBUG}>.

=item debug_mock

Controls whether to print debug info in this class.

=back

=head2 PACKAGE SAVING PROPERTIES

Sometimes it might be nice to put the files into a temporary directory included in @INC,
or to keep them around for debugging or faster loading later.

=over 4

=item save

Whether to save package definitions into files. Default is not to save.

If set at construction, the temporary directory will be prepended to @INC so that
the mocks will load with C<use> hiding any real implementations.

=item basedir

Base directory for saving packages. Default is system temporary directory.

=item savedir

Template for name of subdirectory inside basedir to contain saved package file hierarchy.
Default is 'perl-mock-<process-id>-<mock-instance-number>'.

=back

=cut

my %prototype = (

    'state' => $state{plan},

    # package instantiation stuff:

    'package_template' => '
package #{packagename};

#{subs}

1;
',

    'autoload_template' => '
sub #{subname} {
    @_ = ($Test::CallFlow::instances[#{id}], $#{packagename}::#{subname}, @_);
    goto \&Test::CallFlow::mock_call
        unless $#{packagename}::#{subname} eq \'#{packagename}::DESTROY\'
}
',

    'sub_template' => '
sub #{subname} {
    @_ = ($Test::CallFlow::instances[#{id}], \'#{packagename}::#{subname}\', @_);
    goto \&Test::CallFlow::mock_call
}
',

    # runtime package definition string
    'package_definition_template' =>
        "no warnings \'redefine\';\n#{packagebody}",

    # future Test::CallFlow::Package stuff:

    'save'    => 0,
    'basedir' => File::Spec->tmpdir,
    'savedir' => "perl-test-callflow-$$-\#{id}",
);

=head1 FUNCTIONS

=head2 instance

  $mocker = Test::CallFlow::instance;

Returns the first instance of this class created with given properties. Creates one if there isn't.

This is called from each of the C<mock_> subs exported with C<:all> tag so that
the library can easily be used procedurally.

=cut

sub instance {
    my %properties = @_;

    for my $instance (@instances) {
        return $instance
            unless grep {
            defined $properties{$_}
                ? $instance->{$_} ne $properties{$_}
                : defined $instance->{$_}
            } keys %properties;
    }

    Test::CallFlow->new(%properties);
}

=head2 new

	my $mocker = Test::CallFlow->new( %properties );

Returns a new C<Test::CallFlow> object with given properties.
Properties not given are taken from %Test::CallFlow::prototype.

=cut

sub new {
    my ( $class, %self ) = @_;
    $class = ref $class if ref $class;
    $self{id} = @instances;

    for ( keys %prototype ) {
        $self{$_} = exists $ENV{"mock_$_"} ? $ENV{"mock_$_"} : $prototype{$_}
            unless exists $self{$_};
    }

    $self{packages} ||= {};
    $self{debug} = $ENV{DEBUG}
        if not exists $self{debug} and exists $ENV{DEBUG};
    $self{debug_mock} = $self{debug} =~ /\bMock\b/ if $self{debug};

    if ( $self{save} ) {
        $self{savedir} =~ s/\#{(\w+)}/$self{$1}/g;
        my $dir = File::Spec->catdir( $self{basedir}, $self{savedir} );
        unshift @INC, $dir unless grep { $_ eq $dir } @INC;
    }

    my $self = bless \%self, $class;
    push @instances, $self;

    $recording = $self if $self{state} == $state{record};
    $planning  = $self if $self{state} == $state{plan};
    $running   = $self if $self{state} == $state{execute};

    return $self;
}

=head2 record_calls_from

   record_calls_from( 'Package::Under::Test', 'Supplementary::Package::Under::Same::Test', );

Starts recording calls from specified packages.

Returns self.

=cut

sub record_calls_from {
    my $self =
           isa( $_[0], 'Test::CallFlow' ) ? shift : $recording
        || $planning
        || instance;
    croak( "record_calls_from called in wrong state: ",
           $state[ $self->{state} || 0 ] )
        unless $self->{state} == $state{plan}
            or $self->{state} == $state{record};

    $self->{record_calls_from}{$_} = 1 for @_;

    $self->{state} = $state{record};
    $running  = undef if ( $running  || 0 ) == $self;
    $planning = undef if ( $planning || 0 ) == $self;
    $recording = $self;
}

=head2 mock_run

  mock_run;

End planning mocked calls and start executing tests.

If compilation of a package fails, confesses its whole source.

Returns self.

=cut

sub mock_run {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    $self->save_mock_package($_)
        for grep { !$self->{packages}{$_}{saved} }
        sort keys %{ $self->{packages} };
    for ( sort keys %{ $self->{packages} } ) {
        $INC{ mock_package_filename($_) } = "mocked by $self";
        my $plan = $self->embed( $self->{package_definition_template},
                                 packagebody => $self->plan_mock_package($_) );
        eval $plan;
        confess
"### FAILED MOCK PACKAGE DEFINITION ($@):\n$plan\n### END FAILED MOCK PACKAGE DEFINITION ($@)\n"
            if $@;
    }
    $self->{state} = $state{execute};
    $planning = undef if ( $planning || 0 ) == $self;
    $running = $self;
}

=head2 mock_end

  mock_end;

End test execution.

If any expected calls have not been made, dies with a list of unsatisfied calls.

Returns self.

=cut

sub mock_end {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $running
        || instance;
    $planning  = undef if ( $planning  || 0 ) == $self;
    $running   = undef if ( $running   || 0 ) == $self;
    $recording = undef if ( $recording || 0 ) == $self;

    if (     $self->{state} != $state{execute}
         and $self->{state} != $state{failed} )
    {
        $self->{state} = $state{failed};
        confess "End mock in a bad state: ", $state[ $self->{state} ];
    }

    my @unsatisfied = $self->{plan}->unsatisfied;
    if (@unsatisfied) {
        $self->{state} = $state{failed};
        confess "End mock with ", scalar(@unsatisfied),
            " calls remaining:\n" . join("\n"),
            map { "\t" . $_->name } @unsatisfied;
    }

    $self->{state} = $state{succeeded};

    $self;
}

=head2 mock_clear

  mock_clear;

Clears plan.
Restores any original subs covered by mocks.
Resets state unconditionally back to planning.

Does not touch any other properties of mocked packages than subs mocked with C<mock_sub()>
(that's used implicitly during normal planning or recording).

Does not currenctly remove any files created by requesting packages to be saved.
Maybe that should some day be a configurable option.

Returns self.

=cut

sub mock_clear {
    my $self =
           isa( $_[0], 'Test::CallFlow' ) ? shift : $running
        || $planning
        || $recording
        || instance;

    # unmock mocked subs
    no strict 'refs';
    for my $package_name ( keys %{ $self->{packages} || {} } ) {
        my $package       = $self->{packages}{$package_name};
        my $mocked_subs   = $package->{subs} || {};
        my $original_subs = $package->{original_subs} || {};
        my $namespace     = $package_name . '::';
        for my $mocked_sub_name ( keys %{$mocked_subs} ) {
            my $full_sub_name = $namespace . $mocked_sub_name;
            my $original_sub  = $original_subs->{$mocked_sub_name};
            if ($original_sub) {
                no warnings 'redefine';
                *{$full_sub_name} = $original_sub;
            } else {
                undef *{$full_sub_name};
            }
        }
    }
    use strict 'refs';

    delete $self->{record_calls_from};
    delete $self->{packages};
    delete $self->{plan};
    $self->{state} = $state{plan};

    $running   = undef if ( $running   || 0 ) == $self;
    $recording = undef if ( $recording || 0 ) == $self;

    $planning = $self;
}

=head2 mock_reset

  mock_reset;

Reset mock plan for re-run.

=cut

sub mock_reset {
    my $self = shift || instance;
    $self->{plan}->reset;
    delete $self->{record_calls_from};
    $self->{state} = $state{plan};
}

=head2 mock_package

  mock_package( 'Package::Name' );

Declares package of given name to be mocked. Returns nothing.
Dies if the package declaration fails - ie. when invalid templates were specified for this mock object.

C<AUTOLOAD> method gets declared to enable building plan by mock calls.

=cut

sub mock_package {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my $name = shift or confess "Can't mock a package without a name";
    return if exists $self->{packages}{$name};

    $self->{packages}{$name} = {@_};
    unless ( exists $self->{packages}{$name}{subs}{AUTOLOAD} ) {
        $self->mock_sub( $name, 'AUTOLOAD', $self->{autoload_template} );
    }

    no strict 'refs';
    my $namespace_name = $name . '::';
    my %namespace      = %{$namespace_name};
    for my $sub_name ( keys %namespace ) {
        my $sub = *{ $namespace{$sub_name} }{CODE} or next;
        $self->{packages}{$name}{original_subs}{$sub_name} ||= $sub;
        $self->mock_sub( $name, $sub_name );
    }
    use strict 'refs';

    my $plan = $self->embed( $self->{package_definition_template},
                             packagebody => $self->plan_mock_package($name) );

    warn $plan if $self->{debug_mock};
    eval $plan;
    die $@ if $@;
}

=head2 mock_object

  my $mocked = mock_object( 'Package::Name' );
  my $mocked_scalar = mock_object( 'Scalar::Blessed', "bless this scalar" );

Returns an object of given mocked package. Declares that package for mocking if necessary.

=cut

sub mock_object {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my $name = shift;
    my $object = @_ ? shift : {};
    mock_package($name);

    bless $object, $name;
}

=head2 mock_sub

  my $props_ref = mock_sub( 'Package::Name', 'sub_name', 'sub #{subname} { warn "#{subname}(@_) called" }' );

Declares given package to contain given sub such that it will actually execute Test::CallFlow::mock_call -
or alternatively given template text.

Template may contain placeholders marked as #{name} to be substituted with values
of any property of the C<Test::CallFlow> object or

=over 4

=item subname

Name of sub being defined

=item packagename

Name of package being defined

=back

=cut

sub mock_sub {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my ( $package, $sub, $code ) = @_;
    $self->mock_package($package)
        unless exists $self->{packages}{$package};
    delete $self->{packages}{$package}{saved};
    $self->{packages}{$package}{subs}{$sub} =
        $code;    # undef ok, default sub_template will be used
}

=head2 mock_call

   mock_call( 'Mocked::Package::sub_name', @args );

Called from mocked packages.

During plan buildup, adds calls to mock call plan list.

During test execution, tries to find a planned mock call matching given call.
Returns planned value. Dies on mismatch.

During recording calls the original method. If caller is a record candidate, records the call and result.

=cut

sub mock_call {
    my $self =
           isa( $_[0], 'Test::CallFlow' ) ? $_[0] : $planning
        || $running
        || instance;

    my $target = {
                   $state{plan}    => \&plan_mock_call,
                   $state{execute} => \&execute_mock_call,
                   $state{record}  => \&record_mock_call
        }->{ $self->{state} || 0 }
        or croak "Mock call in a bad state: ", $state[ $self->{state} || 0 ];
    warn "mock_call in $state[$self->{state}] state" if $self->{debug_mock};

    goto $target;
}

=head2 mock_plan

Returns reference to the Test::CallFlow::Plan object.

=cut

sub mock_plan {
    my $self =
           isa( $_[0], 'Test::CallFlow' ) ? $_[0] : $recording
        || $planning
        || $running
        || instance;

    $self->{plan};
}

=head2 arg_check

  $mocked->method( arg_check(qr/../), arg_check( sub { $_[2]->[$_[1]] < 5 }, 0, 99 ) );

Instantiates an object of correct subclass of Test::CallFlow::ArgCheck for given test; either Regexp or Code reference.

Arguments are

=over 4

=item 1. The test: a regular expression, code reference or scalar

=item 2. minimum number of arguments to match: 0 for optional

=item 3. maximum number of arguments to match.

=back

=cut

sub arg_check {
    my @args = qw(test min max);
    my %checker = map { shift(@args), $_ } @_;
    $checker{min} ||= 1 unless defined $checker{min};
    $checker{max} ||= $checker{min} || 1;
    my $class = "Test::CallFlow::ArgCheck::"
        . ucfirst( lc( ref( $checker{test} ) || 'equals' ) );
    my $checker;
    eval "use $class; \$checker = $class->new(\%checker)";
    confess $@ if $@;
    $checker;
}

=head2 arg_any

  $mocked->method( arg_any, 'X', arg_any( 0, -1 ) );

Returns an argument checker that passes any arguments.
Optional arguments specify minimum (default 1) and maximum (default same as minimum)
possible number of arguments to pass.

=cut

sub arg_any {
    my %args;
    $args{min} = shift if @_ and $_[0] =~ /^\d+$/;
    $args{max} = shift if @_ and $_[0] =~ /^\d+$/;
    Test::CallFlow::ArgCheck::Any->new( %args, @_ );
}

=head1 INTERNAL METHODS

These are not exported with C<:all>.

=head2 save_mock_package

Saves given package if saving is not disabled for it and enabled for it or by default.
Location is basedir/savedir/containingpackage/packagename.pm.

Dies on I/O failures.

=cut

sub save_mock_package {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my ($package_name) = shift;

    # package must exist and be set to be saved, not be set to not save
    return
        unless exists $self->{packages}{$package_name}
            and exists $self->{packages}{$package_name}{save}
        ? $self->{packages}{$package_name}{save}
        : $self->{save};

    my $plan = $self->plan_mock_package( $package_name, @_ );

    my $dir      = $self->{basedir};
    my @dir      = ( $self->{savedir}, split /::/, $package_name );
    my $filename = pop(@dir) . ".pm";
    for (@dir) {
        $dir = File::Spec->catdir( $dir, $_ );
        mkdir $dir unless -d $dir;
    }
    my $fullfile = File::Spec->catdir( $dir, $filename );
    warn "Save '$fullfile'" if $self->{debug_mock};
    my $fh = IO::File->open( $fullfile, 'w' ) or die $!;
    $fh->print($plan);
    $fh->close or die $!;
    $self->{packages}{$package_name}{saved} = 1;
}

=head2 plan_mock_package

  my $package_definition = plan_mock_package( 'My::Mocked::Package::Name' );

Returns a string containing the perl code for a package with mock versions of all methods called so far.

=cut

sub plan_mock_package {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : instance;
    my ($package_name) = @_;
    return unless defined $self->{packages}{$package_name};
    my $subs = $self->{packages}{$package_name}{subs} || {};

    $self->embed(
        $self->{package_template} || $self->{sub_template},
        packagename => $package_name,
        subs        => join '',
        map {
            $self->embed(
                          $subs->{$_} || $self->{sub_template},
                          packagename => $package_name,
                          subname     => $_,
                )
            } sort grep /^\w+$/,
        keys %$subs
    );
}

=head2 embed

  my $text = $mocker->embed( 'sub #{subname} { "mocked sub of #{packagename}" }', subname => 'my_mock' );

Embeds given values and object properties as referred by placeholders in given text.

Does not recurse indefinitely, but gives silently up after 15 recursions.

=cut

sub embed {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my $text = shift;
    my (%embeddable) = ( %$self, @_ );
    my $embeddable_keys = join '|', keys %embeddable;
    my $depth = 16;
    1 while --$depth and $text =~ s/#{($embeddable_keys)}/$embeddable{$1}/g;
    $text;
}

=head2 mock_package_filename

  my $filename = mock_package_filename( 'My::Mocked::Package::Name' );

Returns relative path and filename combination string for given package name.

=cut

sub mock_package_filename {
    my $self = isa( $_[0], 'Test::CallFlow' ) ? shift : $planning
        || instance;
    my ($package_name) = shift;

    File::Spec->catdir( split /::/, $package_name ) . '.pm';
}

=head2 plan_mock_call

  $mocker->plan_mock_call( 'Mocked::Package::sub_name', @args );

Adds a call with given package::sub name and arguments to call plan.

=cut

sub plan_mock_call {
    my $self = shift;
    my $sub = shift or confess "No sub";
    unless ( ref $sub ) {
        my ( $package, $method ) = $sub =~ /(.+)::([^:]+)$/;
        $self->mock_sub( $package, $method )
            unless $self->{packages}{$package}
                and $self->{packages}{$package}{subs}{$sub};
    }
    my $call_plan =
        Test::CallFlow::Call->new(
                                   args => [ $sub, @_ ],
                                   ( $self->{debug} || '' ) =~ /\bCall\b/
                                   ? ( debug => $self->{debug} )
                                   : ()
        );
    $self->{plan} ||=
        Test::CallFlow::Plan->new(
                                     ( $self->{debug} || '' ) =~ /\bPlan\b/
                                   ? ( debug => $self->{debug} )
                                   : ()
        );
    $self->{plan}->add_call($call_plan);
    warn "Planned call $sub(@_)" if $self->{debug_mock};

    $call_plan;
}

=head2 execute_mock_call

Called from C<mock_call> when running tests against plan.

Returns result from planned mock call matching given executed call if one exists.

=cut

sub execute_mock_call {
    my $self = shift;
    my @result;
    eval { @result = $self->{plan}->call(@_); };
    if ($@) {
        $self->{state} = $state{failed};
        die $@;
    }
    wantarray ? @result : $result[0];
}

=head2 record_mock_call

Called from C<mock_call> when recording calls.

Returns result of call to original method.

=cut

sub record_mock_call {
    my $self = shift;
    my $sub = shift or confess "No sub";
    my ( $package_name, $sub_name ) = $sub =~ /(.+)::([^:]+)$/;

    my $package = $self->{packages}{$package_name}
        or confess "No package '$package_name' for $sub(@_)";

    my $orig = $package->{original_subs}{$sub_name}
        or confess "No such original sub $sub(@_)";

    my @result = wantarray ? ( $orig->(@_) ) : ( scalar $orig->(@_) );

    my ( $caller_package, $caller_file, $caller_line ) = caller(0);
    if ( $self->{record_calls_from}{$caller_package} ) {
        my $caller_sub = ( caller 1 )[3];
        my $called     = "$caller_sub at $caller_file line $caller_line";
        $self->plan_mock_call( $sub, @_ )->result(@result)
            ->called_from($called);
    }

    wantarray ? @result : $result[0];
}

=head1 TODO

=over 4

=item * MockCommand 

Integration to cover external command calls.

=item * Tied Variables

Provide easy methods for recording, restricting and testing data access.

=item * Test::CallFlow::Package

Would allow for neat stuff like

  mock_package( 'Bar' )->vars( ISA => [ 'Foo' ], VERSION => 0.01 );

=item * ArgCheck::Hash

ArgChecker for deep structure comparison. Add also C<arg_deep>.

=item * ArgCheck::Array

ArgChecker for a match in a list; used as C<arg_check( \@in )>.

=item * Ref Checking

Document the fact that Regexp /^Type::Name=/ may be used for reference type checks.

=back

=head1 AUTHOR

Kalle Hallivuori, C<< <kato at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-callflow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-CallFlow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::CallFlow


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-CallFlow>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-CallFlow>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-CallFlow>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-CallFlow/>

=back

=head1 SEE ALSO

=head2 ALTERNATIVES

Test::CallFlow provides a very simple way to plan mocks.
Other solutions are available, each with their strong points.

=over 4

=item * Test::MockClass

Very clearly named methods are used to create and control mocks.
Supports explicit call order. Does not provide unified flexible argument checking.
Call tracking can be disabled.

=item * Test::MockObject

Collects calls made so that you can check them in your own code afterwards.

=item * Test::MockModule

You provide the code for each mocked method separately. No flow checks.
Original methods are remembered and can be restored later.

=item * Test::MockCommand

Mock external commands that your program calls.

=back

=head2 SUPPLEMENTARY MODULES

=over 4

=item * Test::CallFlow::Plan

A structure of calls the code under test should make.

=item * Test::CallFlow::Call

A single call that the code under test might make.

=item * Test::CallFlow::ArgCheck

Checkers for arguments to mocked function calls.

=item * Test::CallFlow::ArgCheck::Equals

Pass arguments that match given string or undef.

=item * Test::CallFlow::ArgCheck::Code

Pass arguments that given method returns true for.

=item * Test::CallFlow::ArgCheck::Regexp

Pass arguments that are defined and match given regexp.

=item * Test::CallFlow::ArgCheck::Any

Pass any arguments.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * chromatic, author of Test::MockObject

Perl namespace management details I got from his code.

=item * Simon Flack, author of Test::MockModule

Perl namespace management details I got from his code.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Kalle Hallivuori, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Test::CallFlow
