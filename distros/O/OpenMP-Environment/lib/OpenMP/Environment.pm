package OpenMP::Environment; 
use strict;
use warnings;

use Validate::Tiny qw/filter is_in/;

our $VERSION = q{1.2.1};

our @_OMP_VARS = (
    qw/OMP_CANCELLATION OMP_DISPLAY_ENV OMP_DEFAULT_DEVICE OMP_NUM_TEAMS
      OMP_DYNAMIC OMP_MAX_ACTIVE_LEVELS OMP_MAX_TASK_PRIORITY OMP_NESTED
      OMP_NUM_THREADS OMP_PROC_BIND OMP_PLACES OMP_STACKSIZE OMP_SCHEDULE
      OMP_TARGET_OFFLOAD OMP_THREAD_LIMIT OMP_WAIT_POLICY GOMP_CPU_AFFINITY
      GOMP_DEBUG GOMP_STACKSIZE GOMP_SPINCOUNT GOMP_RTEMS_THREAD_POOLS
      OMP_TEAMS_THREAD_LIMIT/
);

# capture state of %ENV
local %ENV = %ENV;

# constructor
sub new {
    my $pkg = shift;

    my $validate_rules = {
        fields  => \@_OMP_VARS,
        filters => [
            [qw/OMP_CANCELLATION OMP_NESTED OMP_DISPLAY_ENV OMP_TARGET_OFFLOAD OMP_WAIT_POLICY/] => filter('uc'),    # force to upper case for convenience
        ],
        checks => [
            [qw/OMP_DYNAMIC OMP_NESTED/]                                 => is_in( [qw/TRUE true 1 FALSE false 0/],  q{Expected values are: 'true', 1, 'false', or 0} ),
            [qw/OMP_CANCELLATION/]                                       => is_in( [qw/TRUE FALSE/],                 q{Expected values are: 'TRUE' or 'FALSE'} ),
            OMP_DISPLAY_ENV                                              => is_in( [qw/TRUE VERBOSE FALSE/],         q{Expected values are: 'TRUE', 'VERBOSE', or 'FALSE'} ),
            OMP_TARGET_OFFLOAD                                           => is_in( [qw/MANDATORY DISABLED DEFAULT/], q{Expected values are: 'MANDATORY', 'DISABLED', or 'DEFAULT'} ),
            OMP_WAIT_POLICY                                              => is_in( [qw/ACTIVE PASSIVE/],             q{Expected values are: 'ACTIVE' or 'PASSIVE'} ),
            GOMP_DEBUG                                                   => is_in( [qw/0 1/],                        q{Expected values are: 0 or 1} ),
            [qw/OMP_MAX_TASK_PRIORITY OMP_DEFAULT_DEVICE/]               => sub { return _is_ge_if_set( 0, @_ ) },
            [qw/OMP_NUM_THREADS OMP_MAX_ACTIVE_LEVELS OMP_THREAD_LIMIT/] => sub { return _is_ge_if_set( 1, @_ ) },
            [qw/OMP_NUM_TEAMS OMP_TEAMS_THREAD_LIMIT/]                   => sub { return _is_ge_if_set( 1, @_ ) },

            #-- the following are not current validated due to the complexity of the rules associated with their values
            OMP_PROC_BIND           => _no_validate(),
            OMP_PLACES              => _no_validate(),
            OMP_STACKSIZE           => _no_validate(),
            OMP_SCHEDULE            => _no_validate(),
            GOMP_CPU_AFFINITY       => _no_validate(),
            GOMP_STACKSIZE          => _no_validate(),
            GOMP_SPINCOUNT          => _no_validate(),
            GOMP_RTEMS_THREAD_POOLS => _no_validate(),
        ],
    };

    sub _is_ge_if_set {
        my ( $min, $value ) = @_;
        if ( not defined $value ) {
            return;
        }
        elsif ( $value =~ m/\D/ or $value lt $min ) {
            return q{Value must be an integer great than or equal to 1};
        }
        return;
    }

    my $self = { _validation_rules => $validate_rules, };
    return bless $self, $pkg;
}

# returns a list of variables supported (no values)
sub vars {
    my $self = shift;
    return @_OMP_VARS;
}

# returns a list of variables unset (value not set so don't need it)
sub vars_unset {
    my $self  = shift;
    my @unset = ();
    foreach my $ev (@_OMP_VARS) {
        push @unset, $ev if not $ENV{$ev};
    }
    return @unset;
}

# returns a list of all variables that are currently set, and their values
# as an array of hash references of the form, "$VAR_NAME => $value"
sub vars_set {
    my $self = shift;
    my @set  = ();
    foreach my $ev (@_OMP_VARS) {
        push @set, { $ev => $ENV{$ev} } if $ENV{$ev};
    }
    return @set;
}

sub print_omp_summary_unset {
    my $self = shift;
    return print $self->_omp_summary_unset;
}

sub _omp_summary_unset {
    my $self  = shift;
    my @lines = ();
    push @lines, qq{Summary of OpenMP Environmental UNSET variables supported in this module:};
  ENV:
    foreach my $ev ( $self->vars_unset ) {
        push @lines, sprintf( qq{%s}, $ev );
    }
    my $ret = join( qq{\n}, @lines );
    $ret .= print qq{\n};
    $ret .= print qq{- none\n} if ( @lines == 1 );
    return $ret;
}

sub print_omp_summary_set {
    my $self = shift;
    return print $self->_omp_summary_set;
}

sub _omp_summary_set {
    my $self  = shift;
    my @lines = ();
    push @lines, qq{Summary of OpenMP Environmental SET variables supported in this module:};
  ENV:
    foreach my $ev_ref ( $self->vars_set ) {
        my $ev  = ( keys %$ev_ref )[0];
        my $val = ( values %$ev_ref )[0];
        push @lines, sprintf( qq{%-25s %s}, $ev, $val );
    }
    my $ret = join( qq{\n}, @lines );
    $ret .= print qq{\n};
    $ret .= print qq{- none\n} if ( @lines == 1 );
    return $ret;
}

sub print_omp_summary {
    my $self = shift;
    return print $self->_omp_summary;
}

sub _omp_summary {
    my $self = shift;
    my $ret  = qq{Summary of OpenMP Environmental ALL variables supported in this module:\n};
    $ret .= sprintf( qq{%-25s %s\n}, q{Variable}, q{Value} );
    $ret .= sprintf( qq{%-25s %s\n}, q{~~~~~~~~}, q{~~~~~} );
  ENV:
    foreach my $ev ( $self->vars ) {
        my $val = ( defined $ENV{$ev} ) ? $ENV{$ev} : q{<XXunsetXX>};
        $ret .= sprintf( qq{%-25s %s\n}, $ev, $val );
    }
    return $ret;
}

# OpenMP Environmental Variable setters/getters

sub omp_cancellation {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_CANCELLATION};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_cancellation {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_CANCELLATION};
    return delete $ENV{$ev};
}

sub omp_display_env {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DISPLAY_ENV};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_display_env {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DISPLAY_ENV};
    return delete $ENV{$ev};
}

sub omp_default_device {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DEFAULT_DEVICE};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_default_device {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DEFAULT_DEVICE};
    return delete $ENV{$ev};
}

sub omp_dynamic {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DYNAMIC};
    my $old = $ENV{OMP_DYNAMIC};
    if (not $value or $value eq q{false} or $value eq q{FALSE}) {
     $self->unset_omp_dynamic();
     return $old;
    }
    else {
      return $self->_get_set_assert( $ev, $value );
    }
}

sub unset_omp_dynamic {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_DYNAMIC};
    return delete $ENV{$ev};
}

sub omp_max_active_levels {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_MAX_ACTIVE_LEVELS};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_max_active_levels {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_MAX_ACTIVE_LEVELS};
    return delete $ENV{$ev};
}

sub omp_max_task_priority {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_MAX_TASK_PRIORITY};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_max_task_priority {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_MAX_TASK_PRIORITY};
    return delete $ENV{$ev};
}

sub omp_nested {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NESTED};
    my $old = $ENV{OMP_NESTED};
    if (not $value or $value eq q{false} or $value eq q{FALSE}) {
     $self->unset_omp_nested();
     return $old;
    }
    else {
      return $self->_get_set_assert( $ev, $value );
    }
}

sub unset_omp_nested {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NESTED};
    return delete $ENV{$ev};
}

sub omp_num_threads {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NUM_THREADS};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_num_threads {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NUM_THREADS};
    return delete $ENV{$ev};
}

sub omp_num_teams {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NUM_TEAMS};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_num_teams {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_NUM_TEAMS};
    return delete $ENV{$ev};
}

sub omp_proc_bind {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_PROC_BIND};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_proc_bind {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_PROC_BIND};
    return delete $ENV{$ev};
}

sub omp_places {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_PLACES};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_places {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_PLACES};
    return delete $ENV{$ev};
}

sub omp_stacksize {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_STACKSIZE};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_stacksize {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_STACKSIZE};
    return delete $ENV{$ev};
}

sub omp_schedule {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_SCHEDULE};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_schedule {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_SCHEDULE};
    return delete $ENV{$ev};
}

sub omp_target_offload {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_TARGET_OFFLOAD};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_target_offload {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_TARGET_OFFLOAD};
    return delete $ENV{$ev};
}

sub omp_thread_limit {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_THREAD_LIMIT};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_thread_limit {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_THREAD_LIMIT};
    return delete $ENV{$ev};
}

sub omp_teams_thread_limit {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_TEAMS_THREAD_LIMIT};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_teams_thread_limit {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_TEAMS_THREAD_LIMIT};
    return delete $ENV{$ev};
}

sub omp_wait_policy {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_WAIT_POLICY};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_omp_wait_policy {
    my ( $self, $value ) = @_;
    my $ev = q{OMP_WAIT_POLICY};
    return delete $ENV{$ev};
}

sub gomp_cpu_affinity {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_CPU_AFFINITY};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_gomp_cpu_affinity {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_CPU_AFFINITY};
    return delete $ENV{$ev};
}

sub gomp_debug {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_DEBUG};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_gomp_debug {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_DEBUG};
    return delete $ENV{$ev};
}

sub gomp_stacksize {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_STACKSIZE};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_gomp_stacksize {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_STACKSIZE};
    return delete $ENV{$ev};
}

sub gomp_spincount {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_SPINCOUNT};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_gomp_spincount {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_SPINCOUNT};
    return delete $ENV{$ev};
}

sub gomp_rtems_thread_pools {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_RTEMS_THREAD_POOLS};
    return $self->_get_set_assert( $ev, $value );
}

sub unset_gomp_rtems_thread_pools {
    my ( $self, $value ) = @_;
    my $ev = q{GOMP_RTEMS_THREAD_POOLS};
    return delete $ENV{$ev};
}

# auxilary validation routines for with Validate::Tiny

# used to assert valid environment, useful if variables are already set externally
sub assert_omp_environment {
    my $self  = shift;
    my @lines = ();
  ENV:
    foreach my $ev_ref ( $self->vars_set ) {
        my $ev  = ( keys %$ev_ref )[0];
        my $val = ( values %$ev_ref )[0];
        $self->_get_set_assert( $ev, $ENV{$ev} ) if exists $ENV{$ev};
    }
    return 1;
}

sub _get_set_assert {
    my ( $self, $ev, $value ) = @_;
    if ( defined $value ) {
        my $filtered_value = $self->_assert_valid( $ev, $value );
        $ENV{$ev} = $filtered_value;
    }
    return ( exists $ENV{$ev} ) ? $ENV{$ev} : undef;
}

sub _assert_valid {
    my ( $self, $ev, $value ) = @_;
    my $result = Validate::Tiny::validate( { $ev => $value }, $self->{_validation_rules} );

    # process errors, then die
    my $err;
    foreach my $e ( keys %{ $result->{error} } ) {
        my $msg = $result->{error}->{$e};
        my $val = $result->{data}->{$e};
        $err = qq{(fatal) $e="$val": $msg\n};
    }
    die qq{$err\n} if not $result->{success};

    # if all is okay, return the filtered value (since we're testing what's been passed through 'filters' for some envars
    return $result->{data}->{$ev};
}

# provides validator that does nothing, a null validator useful as a place holder
sub _no_validate {
    return sub {
        return undef;
    };
}

1;

__END__

=head1 NAME

OpenMP::Environment - Perl extension managing OpenMP variables in
C<%ENV> within a script.

=head1 SYNOPSIS

  use OpenMP::Environment ();
  my $env = OpenMP::Environment->new;
  $env->assert_omp_environment;

=head1 DESCRIPTION

Provides accessors for affecting the OpenMP/GOMP environmental
variables that affect some aspects of OpenMP programs and shared
libraries at libary load and run times.

The author of this module is also the author of L<OpenMP::Simple>,
and it is recommended that these two modules be used together for
maximum ease of creating Perl programs that contains C code that has
been parallelized using OpenMP. L<Example 4> illustrates how to use
L<Alien::OpenMP> and directly query C<%ENV> in a way that mimicks
the OpenMP runtime's expected behavior of querying the environment
for some important information like C<OMP_NUM_THREADS> explicitly.

However, the recommended approach is illustrated in L<Example 5>,
which uses both L<OpenMP::Simple> and L<OpenMP::Environment> to
incorporate an C<%ENV> aware OpenMP into a Perl programs as seamlessly
as possible.

There are setters, getters, and unsetters for all published OpenMP
(and GOMP) environmental variables, in additional to some utility
methods.

C<The environment variables which beginning with OMP_ are defined
by section 4 of the OpenMP specification in version 4.5, while
those beginning with GOMP_ are GNU extensions.>

=head1 ABOUT THIS DOCUMENT

Most provided methods are meant to manipulate a particular OpenMP
environmental variable. Each has a setter, getter, and unsetter
(i.e., deletes the variable from C<%ENV> directly.

Each method is documented, and it is noted if the setter will
validate the provided value. Validation occurs whenever the set of
values is a simple numerical value or is a limited set of specific
strings. It is clearly noted below when a setter does not validate.
This is extended to C<assert_omp_environment>, which will validate
the variables it is able if they are already set in C<%ENV>.

L<https://gcc.gnu.org/onlinedocs/libgomp/Environment-Variables.html>

=head1 USES AND USE CASES

=head2 BENCHMARKS

This module is ideal to support benchmarks and test suites that
are implemented using OpenMP. As a small example, there is an
example of such a script, in C<benchmarks/demo-dc-NASA.pl> that
shows the building and execution of the C<DC> benchmark. Distributed
with this source is are the C and Fortran protions of NASA's NPB
(version 3.4.1) benchmarking suite for OpenMP. It's okay, technically
I in addition to all US Citizens own this code since we paid for
it :). The link to the benchmark suite is
L<https://www.nas.nasa.gov/publications/npb.html>, but it is one
of many such OpenMP benchmarks and validation suites.

=head2 SUPPORTING XS MODULES USING OPENMP

The caveats for linking shared libraries that contain OpenMP are
explained in C<Example 4> above. The C<OpenMP::Environment> module
is not as effect as it is with stand alone executables that use
OpenMP; but the can be made so with some minor modifications to
the code that provide additional support for passing number of
threads, etc and using the OpenMP API (e.g., C<omp_set_num_threads>)
to affect the number of threads.

=head1 EXAMPLES

There is a growing set of example scripts in the distribution's,
C<examples/> directory.

The number and breadth of testing is also growing, so for more
examples on using it and this module's flexibility; please see
those.

Lastly, the Section L<SUPPORTED C<OpenMP> ENVIRONMENTAL VARIABLES>
provides the full description of each environmental variable
available in the OpenMP and GOMP documentation. It also describes
the range of values that are deemed C<valid> for each variable.

=head2 Example 1

Ensure an OpenMP environment is set up properly already (externally)

  use OpenMP::Environment;
  my $env = OpenMP::Environment->new;
  $env->assert_omp_environment;

=head2 Example 2

Managing a range of thread scales (useful for benchmarking, testing, etc)

    use OpenMP::Environment;
    my $env = OpenMP::Environment->new;
  
    foreach my $i (1 2 4 8 16 32 64 128 256) {
      $env->set_omp_num_threads($i); # Note: validated
      my $exit_code = system(qw{/path/to/my_prog_r --opt1 x --opt2 y});
       
      if ($exit_code == 0) {
        # ... do some post processing
      }
      else {
        # ... handle failed execution
      }
    }

=head2 Example 3

Extended benchmarking, affecting C<OMP_SCHEDULE> in addition toC<OMP_NUM_THREADS>.

    use OpenMP::Environment;
    my $env = OpenMP::Environment->new;
  
    foreach my $i (1 2 4 8 16 32 64 128 256) {
      $env->set_omp_num_threads($i); # Note: validated
      foreach my $sched (qw/static dynamic auto/) {
        # compute chunk size
        my $chunk = get_baby_ruth($i);
        
        # set schedule using prescribed format
        $env->set_omp_schedule(qq{$sched,$chunk});
        # Note: format is OMP_SCHED_T[,CHUNK] where OMP_SCHED_T is: 'static', 'dynamic', 'guided', or 'auto'; CHUNK is an integer >0 
        
        my $exit_code = system(qw{/path/to/my_prog_r --opt1 x --opt2 y});
         
        if ($exit_code == 0) {
          # ... do some post processing
        }
        else {
          # ... handle failed execution
        }
      }
    }

Note: While it has not been tested, theoretically any Perl module
that utilizes compiled libraries (via C::Inline, XS, FFIs, etc)
that are C<OpenMP> aware should also be at home within the context
of this module.

=head2 Example 4

Use with an XS module that itself is C<OpenMP> aware:

Note: OpenMP::Environment has no effect on Perl interfaces that
utilize compiled code as shared objects, that also contain OpenMP
constructs.

The reason for this is that OpenMP implemented by compilers, gcc
(gomp), anyway, only read in the environment once. In our use of
Inline::C, this corresponds to the actual loading of the .so that
is linked to the XS-based Perl interface it presents.  As a result,
a developer must use the OpenMP API that is exposed. In the example
below, we're using the C<omp_set_num_threads> rather than setting
C<OMP_NUM_THREADS> via %ENV or using OpenMP::Environment's
C<omp_num_threads> method.

This example uses OpenMP::Environment, but shows that it works with
two caveats:

=over 4

=item It must be called in a C<BEGIN> block that contains the
invocation of C<Inline::C>

=item It as only this single opportunity to effect the variables
that it sets

=back

    use OpenMP::Environment ();
    use constant USE_DEFAULT => 0;
    
    BEGIN {
        my $oenv = OpenMP::Environment->new;
        $oenv->omp_num_threads(16);     # serve as "default" (actual standard default is 4)
        $oenv->omp_thread_limit(32);    # demonstrate setting of the max number of threads

        use Alien::OpenMP;
        use Inline (
            C    => 'DATA',
            with => qw/Alien::OpenMP/,
        );
    
        # Note: Alien::OpenMP replaces:
        #  use Inline (
        #    C           => 'DATA',
        #    name        => q{Test},
        #    ccflagsex   => q{-fopenmp},
        #    lddlflags   => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
        #    BUILD_NOISY => 1,
        #  );
    }
    
    # use default
    test(USE_DEFAULT);
    
    for my $num_threads (qw/1 2 4 8 16 32 64 128 256/) {
        test($num_threads);
    }
    
    exit;
    
    __DATA__
    
    __C__
    #include <omp.h>
    #include <stdio.h>
    void test(int num_threads) {
    
      // invoke default set at library load time if a number less than 1 is provided
      if (num_threads > 0)
        omp_set_num_threads(num_threads);
    
      #pragma omp parallel
      {
        if (0 == omp_get_thread_num())
          printf("wanted '%d', got '%d' (max number is %d)\n", num_threads, omp_get_num_threads(), omp_get_thread_limit()); 
      }
    }

L<Example 5> in the following section demostrates how get around this
restriction somewhat. The caveat is that the respective environmental
variable must also come with a corresponding I<setter> function in the
OpenMP run time. L<OpenMP::Simple> was written to do exactly that as
seemlessly as possible and is currently the recommended approach.

=head2 Example 5

Writing C functions that are aware of the OpenMP run time methods
that are able to be affected by the set of C<omp_set_*> functions:

The following is an example of emulating the familiar behavior of
compiled OpenMP programs that respect a number of environmental
variables at run time. The key difference between running a compiled
OpenMP program at the commandline and a compiled subroutine in Perl
that utilizes OpenMP, is that subsequent calls to the subroutine
in the Perl script do not have an opportunity to relead the binary
or shared library.

The "user experience" of one running an OpenMP program from the
shell is that it the number of threads used in the program may be
set implicitly using the OMP_NUM_THREADS environmental variable.
Therefore, one may run the binary in a shell loop and update
C<OMP_NUM_THREADS> environmentally. Using L<OpenMP::Simple> (itself
a wrapper around L<Alien::OpenMP>) makes it extremely clean and
easy to begin adding OpenMP parallelized C code into Perl programs
which contain the kind of environmental runtime controls one familiar
with OpenMP has come to expect.

  use strict;
  use warnings;
  
  use OpenMP::Simple;
  use OpenMP::Environment;
  use Test::More tests => 8;
  
  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );
  
  my $env = OpenMP::Environment->new;
  
  note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__NUM_THREADS'};
  for my $num_threads ( 1 .. 8 ) {
      my $current_value = $env->omp_num_threads($num_threads);
      is _get_num_threads(), $num_threads, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_NUM_THREADS, as expected}, $num_threads;
  }
  
  __DATA__
  __C__
  int _get_num_threads() {
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS // <~ MACRO provided by OpenMP::Simple reads and updates based on OMP_NUM_THREADS in %ENV
    int ret = 0;
    #pragma omp parallel
    {
      #pragma omp single
      ret = omp_get_num_threads();
    }
    return ret;
  }
  
  __END__

=head2 Additional Discussion

OpenMP benchmarks are often written in this fashion. It is possible
to affect the number of threads in the binary, but only through
the use of run time methods. In the case of C<OMP_NUM_THREADS>,
this function is C<omp_set_num_threads>. The issue here is that
using run time setters breaks the veil that is so attractive about
OpenMP; the pragmas offer a way to implicitly define OpenMP threads
*if* the compiler can recognize them; if it can't, the pragmas are
designed to appear as normal comments.

Using run time functions is an explicit act, and therefore can't
be hidden in the same manner. This requires the compiler to link
against OpenMP run time libraries, even if there is no intention
to run in parallel. There are 2 options here - hide the run time
call from the compiler using C<ifdef> or the like; or link the
OpenMP library and just ensure C<OMP_NUM_THREADS> is set to C<1>
(as in a single thread).

Using C<OpenMP::Environment> introduces the consideration that the
compiled subroutine is loaded only once when the Perl script is
executed. It is true that in this situation, the environment is
read in as expected - but, it is only considered I<once> and at
library I<load> time.

To get away from this restriction and emulate more closely the
C<user experience> of the commandline with respect to OpenMP
environmental variable controls, we present the following example
to show how to C<re-read> certain environmental variables.

Interestingly, there are only 6 run time I<setters> that correspond
to OpenMP environmental variables to work with:

=over 4

=item C<omp_set_num_threads>

Corresponds to C<omp_set_num_threads>.

=item C<omp_set_default_device>

Corresponds to C<OMP_DEFAULT_DEVICE>

=item C<omp_set_dynamic>

Corresponds to C<OMP_DYNAMIC>.

=item C<omp_set_max_active_levels>

Corresponds to C<OMP_MAX_ACTIVE_LEVELS>

=item C<omp_set_nested>

Corresponds to C<OMP_NESTED>

=item C<omp_set_schedule>

Corresponds to C<OMP_SCHEDULE>.

=back

=head1 METHODS

B<Note:> Due to the libary load time of functions compiled and
exported (e.g., using L<Inline::C>), only environmental variables
that are provided with a standard I<set> function for affecting at
run time can be made to emulate the effective behavior that those
familiar with executing OpenMP binaries my find familiar. See
examples 4 and 5 above for more information about what this means.

=over 3

=item C<new>

Constructor

=item C<assert_omp_environment>

Validates OpenMP related environmental variables that might happen
to be set in %ENV directly. Useful as a guard in launcher scripts
to ensure the variables that are validated in this module are valid.

As is the case for all variables, an Environment completely devoid
of any related variables being set is considered C<valid>. In other
words, only variables that are already set in the Environment are
validated.

=item C<vars>

Returns a list of all supported C<OMP_*> and C<GOMP_*> environmental
variables.

=item C<vars_unset>

Returns a list of all unset supported variables.

=item C<vars_set>

Returns a list of hash references of all set variables, of the form,

    (
       VARIABLE1 => value1,
       VARIABLE2 => value2,
       ...
    )

=item C<print_omp_summary_unset>

Prints summary of all unset variable.

Uses internal method, C<_omp_summary_unset> to get string to print.

=item C<print_omp_summary_set>

Prints summary of all set variables, including values.

Uses internal method, C<_omp_summary_set> to get string to print.

=item C<print_omp_summary>

Prints summary of all set and unset variables; including values where
applicable.

Uses internal method, C<_omp_summary> to get string to print.

=item C<omp_cancellation>

Setter/getter for C<OMP_CANCELLATION>.

Validated.

B<Note:> it appears that the OpenMP Specification (any version) does not define a runtime
method to set this. When used with L<OpenMP::Simple>, which makes it a little easier
to deal with C<Inline::C>'d OpenMP routines, this must be set before the shared libraries
are loaded from C<Inline::C>. The only real opportunity to do this is in the C<BEGIN>
block. However, if dealing with a standalone binary executable; this environmental variable
will do what you mean when updated between calls to the external executable.

=item C<unset_omp_cancellation>

Unsets C<OMP_CANCELLATION>, deletes it from localized C<%ENV>.

=item C<omp_display_env>

Setter/getter for C<OMP_DISPLAY_ENV>.

Validated.

=item C<unset_omp_display_env>

Unsets C<OMP_DISPLAY_ENV>, deletes it from localized C<%ENV>.

=item C<omp_default_device>

Setter/getter for C<OMP_DEFAULT_DEVICE>.

Validated.

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=item C<unset_omp_default_device>

Unsets C<OMP_DEFAULT_DEVICE>, deletes it from localized C<%ENV>.

=item C<omp_dynamic>

Setter/getter for C<OMP_DYNAMIC>.

Validated. If set to a I<falsy> value, the key C<$ENV{OMP_DYNAMIC}> is deleted
entirely, because this seems to be how GCC's GOMP needs it to be presented.
Simply setting it to C<0> or C<false> will not work. It has to be I<unset>.
So setting it to a I<falsy> value is the same as calling C<unset_omp_dynamic>.

=over 4

=item B<'true'> | 1

=item B<'false'> | 0 | I<unset>

=back

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=item C<unset_omp_dynamic>

Unsets C<OMP_DYNAMIC>, deletes it from localized C<%ENV>.

=item C<omp_max_active_levels>

Setter/getter for C<OMP_MAX_ACTIVE_LEVELS>.

Validated.

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=item C<unset_omp_max_active_levels>

Unsets C<OMP_MAX_ACTIVE_LEVELS>, deletes it from localized C<%ENV>.

=item C<omp_max_task_priority>

Setter/getter for C<OMP_MAX_TASK_PRIORITY>.

Validated.

=item C<unset_omp_max_task_priority>

Unsets C<OMP_MAX_TASK_PRIORITY>, deletes it from localized C<%ENV>.

Validated.

=item C<omp_nested>

Setter/getter for C<OMP_NESTED>.

Validated.

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=item C<unset_omp_nested>

Unsets C<OMP_NESTED>, deletes it from localized C<%ENV>.

=item C<omp_num_threads>

Setter/getter for C<OMP_NUM_THREADS>.

Validated.

B<Note:> This environmental variable has a I<Standards> defined run time
function associated with it. Therefore, the approach of I<rereading> the
environment demostrated in L<Example 5> may be used to use this module
for affecting this setting at run time.

For more information on this environmental variable, please see:

L<https://gcc.gnu.org/onlinedocs/libgomp/openmp-environment-variables/ompnumthreads.html>

=item C<unset_omp_num_threads>

Unsets C<OMP_NUM_THREADS>, deletes it from localized C<%ENV>.

=item C<omp_num_teams>

Setter/getter for C<OMP_NUM_TEAMS>.

Validated.

B<Note:> This environmental variable has a I<Standards> defined run time
function associated with it. Therefore, the approach of I<rereading> the
environment demostrated in L<Example 5> may be used to use this module
for affecting this setting at run time.

For more information on this environmental variable, please see:

L<https://gcc.gnu.org/onlinedocs/libgomp/openmp-environment-variables/ompnumteams.html>

=item C<unset_omp_num_teams>

Unsets C<OMP_NUM_TEAMS>, deletes it from localized C<%ENV>.

=item C<omp_proc_bind>

Setter/getter for C<OMP_PROC_BIND>.

Not validated.

=item C<unset_omp_proc_bind>

Unsets C<OMP_PROC_BIND>, deletes it from localized C<%ENV>.

=item C<omp_places>

Setter/getter for C<OMP_PLACES>.

Not validated.

=item C<unset_omp_places>

Unsets C<OMP_PLACES>, deletes it from localized C<%ENV>.

=item C<omp_stacksize>

Setter/getter for C<OMP_STACKSIZE>.

Not validated.

=item C<unset_omp_stacksize>

Unsets C<OMP_STACKSIZE>, deletes it from localized C<%ENV>.

=item C<omp_schedule>

Setter/getter for C<OMP_SCHEDULE>.

Not validated.

B<Note:> The format for the environmental variable is C<omp_sched_t[,chunk]> where
B<omp_sched_t> is: 'static', 'dynamic', 'guided', or 'auto'; B<chunk> is an integer >0

For contrast to the value of C<OMP_SCHEDULE>, the runtime function used to set this in an
OpenMP program, C<set_omp_schedule> that expects constant values not exposed via the environmental
variable C<OMP_SCHEDULE>.

E.g.,

  #include<omp.h>
  ...
  set_omp_schedule(omp_sched_static, 10); // Note: this is the C runtime function call

For more information on this particular environmental variable please see:

L<https://gcc.gnu.org/onlinedocs/libgomp/openmp-environment-variables/ompschedule.html>

Also, see the tests in L<OpenMP::Simple>.

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=item C<unset_omp_schedule>

Unsets C<OMP_SCHEDULE>, deletes it from localized C<%ENV>.

=item C<omp_target_offload>

Setter/getter for C<OMP_TARGET_OFFLOADS>.

Validated.

=item C<unset_omp_target_offload>

Unsets C<OMP_TARGET_OFFLOADS>, deletes it from localized C<%ENV>.

=item C<omp_thread_limit>

Setter/getter for C<OMP_THREAD_LIMIT>.

Validated.

=item C<unset_omp_thread_limit>

Unsets C<OMP_THREAD_LIMIT>, deletes it from localized C<%ENV>.

=item C<omp_teams_thread_limit>

Setter/getter for C<OMP_TEAMS_THREAD_LIMIT>.

Validated.

=item C<unset_omp_teams_thread_limit>

Unsets C<OMP_TEAMS_THREAD_LIMIT>, deletes it from localized C<%ENV>.

=item C<omp_wait_policy>

Setter/getter for C<OMP_WAIT_POLICY>.

Validated.

=item C<unset_omp_wait_policy>

Unsets C<OMP_WAIT_POLICY>, deletes it from localized C<%ENV>.

=item C<gomp_cpu_affinity>

Setter/getter for C<GOMP_CPU_AFFINITY>.

Not validated.

=item C<unset_gomp_cpu_affinity>

Unsets C<GOMP_CPU_AFFINITY>, deletes it from localized C<%ENV>.

=item C<gomp_debug>

Setter/getter for C<GOMP_DEBUG>.

Validated.

=item C<unset_gomp_debug>

Unsets C<GOMP_DEBUG>, deletes it from localized C<%ENV>.

=item C<gomp_stacksize>

Setter/getter for C<GOMP_STACKSIZE>.

Not validated.

=item C<unset_gomp_stacksize>

Unsets C<GOMP_STACKSIZE>, deletes it from localized C<%ENV>.

=item C<gomp_spincount>

Setter/getter for C<GOMP_SPINCOUNT>.

Not validated.

=item C<unset_gomp_spincount>

Unsets C<GOMP_SPINCOUNT>, deletes it from localized C<%ENV>.

=item C<gomp_rtems_thread_pools>

Setter/getter for C<GOMP_RTEMS_THREAD_POOLS>.

Not validated.

=item C<unset_gomp_rtems_thread_pools>

Unsets C<GOMP_RTEMS_THREAD_POOLS>, deletes it from localized C<%ENV>.

=back

=head1 SUPPORTED C<OpenMP> ENVIRONMENTAL VARIABLES

The following is essentially direct copy from the URL in DESCRIPTION:

=over 3

=item C<OMP_CANCELLATION>

If set to TRUE, the cancellation is activated. If set to FALSE or
if unset, cancellation is disabled and the cancel construct is
ignored.

This variable is validated via setter.

=item C<OMP_DISPLAY_ENV>

If set to TRUE, the OpenMP version number and the values associated
with the OpenMP environment variables are printed to stderr. If
set to VERBOSE, it additionally shows the value of the environment
variables which are GNU extensions. If undefined or set to FALSE,
this information will not be shown.

This variable is validated via setter.

=item C<OMP_DEFAULT_DEVICE>

Set to choose the device which is used in a target region, unless
the value is overridden by omp_get_set_assert_default_device or by
a device clause. The value shall be the nonnegative device number.
If no device with the given device number exists, the code is
executed on the host. If unset, device number 0 will be used.

This variable is validated via setter.

=item C<OMP_DYNAMIC>

Enable or disable the dynamic adjustment of the number of threads
within a team. The value of this environment variable shall be TRUE
or FALSE. If undefined, dynamic adjustment is disabled by default.

This variable is validated via setter.

=item C<OMP_MAX_ACTIVE_LEVELS>

Specifies the initial value for the maximum number of nested parallel
regions. The value of this variable shall be a positive integer.
If undefined, then if OMP_NESTED is defined and set to true, or if
OMP_NUM_THREADS or OMP_PROC_BIND are defined and set to a list with
more than one item, the maximum number of nested parallel regions
will be initialized to the largest number supported, otherwise it
will be set to one.

This variable is validated via setter.

=item C<OMP_MAX_TASK_PRIORITY>

Specifies the initial value for the maximum priority value that
can be set for a task. The value of this variable shall be a
non-negative integer, and zero is allowed. If undefined, the default
priority is 0.

This variable is validated via setter.

=item C<OMP_NESTED>

Enable or disable nested parallel regions, i.e., whether team
members are allowed to create new teams. The value of this environment
variable shall be TRUE or FALSE. If set to TRUE, the number of
maximum active nested regions supported will by default be set to
the maximum supported, otherwise it will be set to one. If
OMP_MAX_ACTIVE_LEVELS is defined, its setting will override this
setting. If both are undefined, nested parallel regions are enabled
if OMP_NUM_THREADS or OMP_PROC_BINDS are defined to a list with
more than one item, otherwise they are disabled by default.

This variable is validated via setter.

=item C<OMP_NUM_THREADS>

Specifies the default number of threads to use in parallel regions.
The value of this variable shall be a comma-separated list of
positive integers; the value specifies the number of threads to
use for the corresponding nested level. Specifying more than one
item in the list will automatically enable nesting by default. If
undefined one thread per CPU is used.

This variable is validated via setter.

=item C<OMP_PROC_BIND>

Specifies whether threads may be moved between processors. If set
to TRUE, OpenMP theads should not be moved; if set to FALSE they
may be moved. Alternatively, a comma separated list with the values
MASTER, CLOSE and SPREAD can be used to specify the thread affinity
policy for the corresponding nesting level. With MASTER the worker
threads are in the same place partition as the master thread. With
CLOSE those are kept close to the master thread in contiguous place
partitions. And with SPREAD a sparse distribution across the place
partitions is used. Specifying more than one item in the list will
automatically enable nesting by default.

When undefined, OMP_PROC_BIND defaults to TRUE when OMP_PLACES or
GOMP_CPU_AFFINITY is set and FALSE otherwise.

This module provides access to, but does NOT validate this variable.

=item C<OMP_PLACES>

The thread placement can be either specified using an abstract name
or by an explicit list of the places. The abstract names threads,
cores and sockets can be optionally followed by a positive number
in parentheses, which denotes the how many places shall be created.
With threads each place corresponds to a single hardware thread;
cores to a single core with the corresponding number of hardware
threads; and with sockets the place corresponds to a single socket.
The resulting placement can be shown by setting the OMP_DISPLAY_ENV
environment variable.

Alternatively, the placement can be specified explicitly as comma
separated list of places. A place is specified by set of nonnegative
numbers in curly braces, denoting the denoting the hardware threads.
The hardware threads belonging to a place can either be specified
as comma separated list of nonnegative thread numbers or using an
interval. Multiple places can also be either specified by a comma
separated list of places or by an interval. To specify an interval,
a colon followed by the count is placed after after the hardware
thread number or the place. Optionally, the length can be followed
by a colon and the stride number - otherwise a unit stride is
assumed. For instance, the following specifies the same places
list: "{0,1,2}, {3,4,6}, {7,8,9}, {10,11,12}"; "{0:3}, {3:3}, {7:3},
{10:3}"; and "{0:2}:4:3".

If OMP_PLACES and GOMP_CPU_AFFINITY are unset and OMP_PROC_BIND is
either unset or false, threads may be moved between CPUs following
no placement policy.

This module provides access to, but does NOT validate this variable.

=item C<OMP_STACKSIZE>

Set the default thread stack size in kilobytes, unless the number
is suffixed by B, K, M or G, in which case the size is, respectively,
in bytes, kilobytes, megabytes or gigabytes. This is different from
pthread_attr_get_set_assertstacksize which gets the number of bytes
as an argument. If the stack size cannot be set due to system
constraints, an error is reported and the initial stack size is
left unchanged. If undefined, the stack size is system dependent.

This module provides access to, but does NOT validate this variable.

=item C<OMP_SCHEDULE>

Allows to specify schedule type and chunk size. The value of the
variable shall have the form: type[,chunk] where type is one of
static, dynamic, guided or auto The optional chunk size shall be
a positive integer. If undefined, dynamic scheduling and a chunk
size of 1 is used.

This module provides access to, but does NOT validate this variable.

=item C<OMP_TARGET_OFFLOAD>

Specifies the behaviour with regard to offloading code to a device.
This variable can be set to one of three values - MANDATORY, DISABLED
or DEFAULT.

If set to MANDATORY, the program will terminate with an error if
the offload device is not present or is not supported. If set to
DISABLED, then offloading is disabled and all code will run on the
host. If set to DEFAULT, the program will try offloading to the
device first, then fall back to running code on the host if it
cannot.

If undefined, then the program will behave as if DEFAULT was set.

This variable is validated via setter.

=item C<OMP_THREAD_LIMIT>

Specifies the number of threads to use for the whole program. The
value of this variable shall be a positive integer. If undefined,
the number of threads is not limited.

This variable is validated via setter.

=item C<OMP_TEAMS_THREAD_LIMIT>

Specifies the number of threads to use for the whole program. The
value of this variable shall be a positive integer. If undefined,
the number of threads is not limited.

This variable is validated via setter.

=item C<OMP_WAIT_POLICY>

Specifies whether waiting threads should be active or passive. If
the value is PASSIVE, waiting threads should not consume CPU power
while waiting; while the value is ACTIVE specifies that they should.
If undefined, threads wait actively for a short time before waiting
passively.

This variable is validated via setter.

=item C<GOMP_CPU_AFFINITY>

Binds threads to specific CPUs. The variable should contain a
space-separated or comma-separated list of CPUs. This list may
contain different kinds of entries: either single CPU numbers in
any order, a range of CPUs (M-N) or a range with some stride (M-N:S).
CPU numbers are zero based. For example, GOMP_CPU_AFFINITY="0 3
1-2 4-15:2" will bind the initial thread to CPU 0, the second to
CPU 3, the third to CPU 1, the fourth to CPU 2, the fifth to CPU
4, the sixth through tenth to CPUs 6, 8, 10, 12, and 14 respectively
and then start assigning back from the beginning of the list.
GOMP_CPU_AFFINITY=0 binds all threads to CPU 0.

There is no libgomp library routine to determine whether a CPU
affinity specification is in effect. As a workaround,
language-specific library functions, e.g., getenv in C or
GET_ENVIRONMENT_VARIABLE in Fortran, may be used to query the
setting of the GOMP_CPU_AFFINITY environment variable. A defined
CPU affinity on startup cannot be changed or disabled during the
run time of the application.

If both GOMP_CPU_AFFINITY and OMP_PROC_BIND are set, OMP_PROC_BIND
has a higher precedence. If neither has been set and OMP_PROC_BIND
is unset, or when OMP_PROC_BIND is set to FALSE, the host system
will handle the assignment of threads to CPUs.

This module provides access to, but does NOT validate this variable.

=item C<GOMP_DEBUG>

Enable debugging output. The variable should be set to 0 (disabled,
also the default if not set), or 1 (enabled).

If enabled, some debugging output will be printed during execution.
This is currently not specified in more detail, and subject to
change.

This variable is validated via setter.

=item C<GOMP_STACKSIZE>

Determines how long a threads waits actively with consuming CPU
power before waiting passively without consuming CPU power. The
value may be either INFINITE, INFINITY to always wait actively or
an integer which gives the number of spins of the busy-wait loop.
The integer may optionally be followed by the following suffixes
acting as multiplication factors: k (kilo, thousand), M (mega,
million), G (giga, billion), or T (tera, trillion). If undefined,
0 is used when OMP_WAIT_POLICY is PASSIVE, 300,000 is used when
OMP_WAIT_POLICY is undefined and 30 billion is used when
OMP_WAIT_POLICY is ACTIVE. If there are more OpenMP threads than
available CPUs, 1000 and 100 spins are used for OMP_WAIT_POLICY
being ACTIVE or undefined, respectively; unless the GOMP_SPINCOUNT
is lower or OMP_WAIT_POLICY is PASSIVE.

This module provides access to, but does NOT validate this variable.

=item C<GOMP_SPINCOUNT>

Set the default thread stack size in kilobytes. This is different
from pthread_attr_get_set_assertstacksize which gets the number of
bytes as an argument. If the stack size cannot be set due to system
constraints, an error is reported and the initial stack size is
left unchanged. If undefined, the stack size is system dependent.

This module provides access to, but does NOT validate this variable.

=item C<GOMP_RTEMS_THREAD_POOLS>

This environment variable is only used on the RTEMS real-time
operating system. It determines the scheduler instance specific
thread pools. The format for GOMP_RTEMS_THREAD_POOLS is a list of
optional <thread-pool-count>[$<priority>]@<scheduler-name>
configurations separated by : where:

1. C<thread-pool-count> is the thread pool count for this scheduler
instance.

2. $<priority> is an optional priority for the worker threads of
a thread pool according to pthread_get_set_assertschedparam. In
case a priority value is omitted, then a worker thread will inherit
the priority of the OpenMP master thread that created it. The
priority of the worker thread is not changed after creation, even
if a new OpenMP master thread using the worker has a different
priority.

3. @<scheduler-name> is the scheduler instance name according to
the RTEMS application configuration.

In case no thread pool configuration is specified for a scheduler
instance, then each OpenMP master thread of this scheduler instance
will use its own dynamically allocated thread pool. To limit the
worker thread count of the thread pools, each OpenMP master thread
must call C<set_num_threads>.

This module provides access to, but does NOT validate this variable.

=back

=head1 SEE ALSO

L<OpenMP::Simple> is a module that aims at making it easier to bootstrap
Perl+OpenMP programs. It is designed to work together with this module.

This module heavily favors the C<GOMP> implementation of the OpenMP
specification within gcc. In fact, it has not been tested with any
other implementations.

L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>

Please also see the C<rperl> project for a glimpse into the potential
future of Perl+OpenMP, particularly in regards to thread-safe data structures.

L<https://www.rperl.org>

=head1 AUTHOR

oodler577

=head1 ACKNOWLEDGEMENTS

So far I've received great help on irc.perl.org channels, C<#pdl>
and C<#native>. Specificially, C<sivoais>, C<mohawk_pts>, and
C<plicease>; and specifically in regards to the use of C<Inline::C>
above and investigating the issues related to shared library load
time versus run time; and when the environment is initialized.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2023 by oodler577

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0
or, at your option, any later version of Perl 5 you may have
available.
