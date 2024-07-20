package OpenMP;

use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;

my $VERSION = q{1.0.1};

sub new {
  my ($pkg) = shift;
  return bless {
    env => OpenMP::Environment->new,
  }, $pkg; 
}

sub env {
  return shift->{env};
}

777

__END__

=head1 NAME

OpenMP - Metapackage for using OpenMP in Perl 

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  use OpenMP;
  
  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );
  
  my $omp = OpenMP->new;
  
  for my $want_num_threads ( 1 .. 8 ) {
      $omp->env->omp_num_threads($want_num_threads);

      $omp->env->assert_omp_environment; # (optional) validates %ENV

      # call parallelized C function
      my $got_num_threads = _check_num_threads();

      printf "%0d threads spawned in ".
              "the OpenMP runtime, expecting %0d\n",
                $got_num_threads, $want_num_threads;
  }

  __DATA__
  __C__

  /* C function parallelized with OpenMP */
  int _check_num_threads() {
    int ret = 0;
   
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS /* <~ MACRO x OpenMP::Simple */
  
    #pragma omp parallel
    {
      #pragma omp single
      ret = omp_get_num_threads();
    }

    return ret;
  }

=head1 DESCRIPTION

Currently all this module does is eliminates a little boiler plate, but this
also makes documentation and tutorials much more clear. It also makes it easier
to install everything needed since this module will pull in L<OpenMP::Simple>
and L<OpenMP::Environment>.

=head1 METHODS

There are just 2 methods,

=over 4

=item B<new>

constructor, only needed if you're going to use the next method, which means
you're updating OpenMP variables in the environment.

=item B<env>

chainable accessor to the L<OpenMP::Environment> reference that is created when
the constructor B<new> used.

=back

=head1 SEE ALSO

This is a module that aims at making it easier to bootstrap Perl+OpenMP
programs. It is designed to work together with L<OpenMP::Environment> and
L<OpenMP::Simple>.

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
