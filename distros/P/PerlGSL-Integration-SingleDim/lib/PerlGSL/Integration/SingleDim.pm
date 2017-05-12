package PerlGSL::Integration::SingleDim;

use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('PerlGSL::Integration::SingleDim', $VERSION);

use base 'Exporter';
our @EXPORT_OK = ( qw/
  int_1d
/ );

my %engine = (
  qng   => 0,
  fast  => 0, # alias for qng
  qag   => 1,
  qagi  => 2,
  qagiu => 3,
  qagil => 4,
);

sub int_1d {
  croak "int_1d requires 3 arguments, aside from an options hashref" 
    unless @_ >= 3;

  my ($sub, $xl, $xu) = (shift, shift, shift);

  my %opts;
  if (@_) {
    %opts = ref $_[0] ? %{shift()} : @_;
  }

  $opts{epsabs} ||= 0;
  $opts{epsrel} ||= 1e-7;
  $opts{calls}  ||= 1000;

  # handle infinite limits
  my $xu_is_inf = $xu =~ /inf/i;
  my $xl_is_inf = $xl =~ /\-inf/i;

  if ($xu_is_inf) {
    $xu = 0;
    $opts{engine} = 'qagiu';
  }

  if ($xl_is_inf) {
    $xl = 0;
    $opts{engine} = 'qagil';
  }

  if ($xl_is_inf and $xu_is_inf) {
    $opts{engine} = 'qagi';
  }
  # end inf limits

  unless (looks_like_number $xl) {
    croak "Lower limit is not a number: $xl";
  }

  unless (looks_like_number $xu) {
    croak "Upper limit is not a number: $xu";
  }

  unless (defined $opts{engine}) {
    $opts{engine} = 'qag';
  }

  my $ret = c_int_1d($sub, $xl, $xu, $engine{$opts{engine}}, @opts{ qw/epsabs epsrel calls/ });
  return wantarray ? @$ret : $ret->[0];
}

1;

__END__
__POD__

=head1 NAME

PerlGSL::Integration::SingleDim - A Perlish Interface to the GSL 1D Integration Library

=head1 SYNOPSIS

 use PerlGSL::Integration::SingleDim qw/int_1d/;
 my $result = int_1d(sub{ exp( -($_[0]**2) ) }, 0, 'Inf');

=head1 DESCRIPTION

This module is an interface to the GSL's Single Dimensional numerical integration routines.

=head1 FUNCTIONS

No functions are exported by default.

=over

=item int_1d

This is the main interface provided by the module. It takes three required arguments and an (optional) options hash. The first argument is a subroutine reference defining the integrand. The next two are numbers defining the lower and upper bound of integration. The strings C<-Inf> for a lower limit, and C<Inf> for an upper limit are allowed as well (triggering the C<qagi>-type engines).

The options hash reference accepts the following keys:

=over

=item *

epsabs - The maximum allowable absolute error. The default is C<0> (ignored).

=item *

epsrel - The maximum allowable relative error. The default is C<1e-7>.

=item *

calls - The number of points sampled in the function space. The default is 1000.

=item *

engine - This key is mostly for internal use, however if the value C<fast> is given, the C<qng> engine will be used if possible. Other values (the C<qag> type engines) are determined internally as needed. The default is C<qag> with a 21 point sample (this sampling setting is not configurable yet, but this is a reasonable choice).

=back

In scalar context the result is returned, in list context the result and the standard deviation (error) are returned.

=back

=head1 INSTALLATION REQUIREMENTS

This module needs the GSL library installed and available. The C<PERLGSL_LIBS> environment variable may be used to pass the C<--libs> linker flags; if this is not specified, the command C<gsl-config --libs> is executed to find them. Future plans include using an L<Alien> module to provide the GSL in a more CPAN-friendly manner.

=head1 SEE ALSO

=over

=item *

L<PerlGSL>

=item *

L<PerlGSL::Integration::MultiDim>

=item *

L<http://www.gnu.org/software/gsl/manual/html_node/Numerical-Integration.html>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/PerlGSL-Integration-SingleDim>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The GSL is licensed under the terms of the GNU General Public License (GPL)

