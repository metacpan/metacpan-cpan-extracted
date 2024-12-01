package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

our $VERSION = q{0.1.4};

# This module is a wrapper around a ".h" file that is injected into Alien::OpenMP
# via Inline:C's AUTO_INCLUDE feature. This header file constains C MACROs for reading
# OpenMP relavent environmental variables via %ENV (set by OpenMP::Environment perhaps)
# and using the standard OpenMP runtime functions to set them.

use File::ShareDir 'dist_dir';

my $share_dir = dist_dir('OpenMP-Simple');

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{INC} = qq{-I$share_dir};
  $config->{AUTO_INCLUDE} .= qq{\n#include "$share_dir/ppport.h"\n#include "$share_dir/openmp-simple.h"\n};
  return $config;
}

1;

__END__

=head1 NAME

OpenMP::Simple - Wrapper around C<Alien::OpenMP> that provides helpful C MACROs and
runtime functions

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  use OpenMP::Simple;
  use OpenMP::Environment;
  
  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );
  
  my $env = OpenMP::Environment->new;
  
  for my $want_num_threads ( 1 .. 8 ) {
      $env->omp_num_threads($want_num_threads);

      $env->assert_omp_environment; # (optional) validates %ENV

      # call parallelized C function
      my $got_num_threads = _check_num_threads();

      printf "%0d threads spawned in ".
              "the OpenMP runtime, expecting %0d\n",
                $got_num_threads, $want_num_threads;
  }
  
  __DATA__
  __C__

  int _check_num_threads() {
    PerlOMP_GETENV_BASIC
    int ret = 0;
    #pragma omp parallel
    {
      #pragma omp single
      ret = omp_get_num_threads();
    }
    return ret;
  }

See the C<./t> directory for many more examples. It should be obvious,
but C<Test::More> is not required; it's just for show and convenience here.

=head1 DESCRIPTION

This module is a wrapper that provides a custom ".h" file, which is injected
into L<Alien::OpenMP> via C<Inline:C>'s C<AUTO_INCLUDE> hook. This header
file constains C MACROs for reading OpenMP relavent environmental variables
via C<%ENV> (set preferably using L<OpenMP::Environment>) and by calling
the standard OpenMP runtime functions to set them (e.g., C<OMP_NUM_THREADS>
/ C<set_omp_num_threads>).

C<OpenMP::Simple> is meant to work directly with C<OpenMP::Environment>
in a way that provides the same runtime control experience that OpenMP's
environmental variables provides.

The most common use case is updating the number of OpenMP threads that are
defined via C<OMP_NUM_THREADS>.

=head2 Experimental Parts

There is some attempt at helping to deal with getting data structures
that are very common in the computational domains into and out of these
C<Inline::C>'d routines that are parallized via OpenMP. We are currently
investigating what is actually needed in this regard. It is possible that a lot
of this is unnecessariy and it is likely that a large number of C<read-only>
scenerios involving Perl internal data structures and OpenMP threads are
actually I<thread-safe>. This does not address the potential knowledge gap
for those who are more experienced with C<C> and OpenMP than they are with
the Perl C API for accessing internal Perl data structures inside of C code.

=head1 PROVIDED MACROS

=head2 Updating Runtime with Environmental Variables

All MACROS have at least 1 test in the suite. Please look at these in the
Github repository to get an idea of how to use C<OpenMP::Simple>'s macros
with C<OpenMP::Environment>.

=over 4

=item C<PerlOMP_GETENV_BASIC>

Equivalent of using,

  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_UPDATE_WITH_ENV__NUM_SCHEDULE

The purpose of this bundled approach is to make it easier to get started
quickly. This list may be updated between versions. This is the recommended
one to use when starting with this module. See the L<SYNOPSIS> example.

=item C<PerlOMP_GETENV_ALL>

Equivalent of using,

    PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE
    PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT
    PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS
    PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
    PerlOMP_UPDATE_WITH_ENV__DYNAMIC
    PerlOMP_UPDATE_WITH_ENV__NESTED
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_THREADS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NUM_THREADS}>, which is managed via
C<< OpenMP::Environment->omp_num_threads[int numThreads]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DEFAULT_DEVICE}>, which is managed
via C<< OpenMP::Environment->omp_default_device([int deviceNo]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_MAX_ACTIVE_LEVELS}>, which is managed
via C<< OpenMP::Environment->omp_max_active_levels([int maxLevel]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DYNAMIC>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DYNAMIC}>, which is managed
via C<< OpenMP::Environment->omp_dynamic(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__NESTED>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NESTED}>, which is managed
via C<< OpenMP::Environment->omp_nested(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__SCHEDULE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_SCHEDULE}>, which is managed
via C<< OpenMP::Environment->omp_schedule(...); >>.

Note: The schedule syntax is of the form I<schedule[;chunkSize]>.

=item C<PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_TEAMS_THREAD_LIMIT}>, which is managed via C<< OpenMP::Environment->omp_([int limit]); >>.

Note: C<OMP_TEAMS_THREAD_LIMIT> is not supported until GCC 12.3.0

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS>

Updates the OpenMP runtime with the value of the environmental variable,
C<$ENV{OMP_NUM_TEAMS}>, which is managed via C<< OpenMP::Environment->omp_([int num]); >>.

Note: C<OMP_NUM_TEAMS> is not supported until GCC 12.3.0

=item C<PerlOMP_RET_ARRAY_REF_ret>

(may not be needed) - creates a new C<AV*> and sets it I<mortal> (doesn't
survive outside of the current scope). Used when wanting to return an array
reference that's been populated via C<av_push>.

=back

=head1 PROVIDED PERL TO C CONVERSION FUNCTIONS

B<Note>: Work is currently focused on finding the true limits of the Perl C
API. It is likely that in a lot of cases, elements in Perl Arrays (AV) and Perl
Hashes (HV) maybe accessed safely without first transferring the entire data
structures into its pure C<C> equivalent.

=over 4

=item C<PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(AoA, num_nodes, dims, nodes)>

Used to extract the contents of a 2D rectangular Perl array reference that
has been used to represent a 2D matrix.

    float nodes[num_nodes][dims];
    PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(AoA, num_nodes, dims, nodes);

=back

=head1 SEE ALSO

This is a module that aims at making it easier to bootstrap Perl+OpenMP
programs. It is designed to work together with L<OpenMP::Environment>.

This module heavily favors the C<GOMP> implementation of the OpenMP
specification within gcc. In fact, it has not been tested with any other
implementations because L<Alien::OpenMP> doesn't support anything other
than GCC at the time of this writing due to lack of anyone asking for it.

L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>

Please also see the C<rperl> project for a glimpse into the potential future
of Perl+OpenMP, particularly in regards to thread-safe data structures.

L<https://www.rperl.org>

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 LICENSE & COPYRIGHT

Same as Perl.
