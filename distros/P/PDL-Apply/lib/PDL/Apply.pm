package PDL::Apply;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK   = qw(apply_rolling apply_over apply_slice);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.002';

sub import {
  my $package = shift;
  {
    no strict 'refs';
    *{'PDL::apply_rolling'} = \&apply_rolling if grep { /^(:all|apply_rolling)$/ } @_;
    *{'PDL::apply_over'}    = \&apply_over    if grep { /^(:all|apply_over)$/ }    @_;
    *{'PDL::apply_slice'}   = \&apply_slice   if grep { /^(:all|apply_slice)$/ }   @_;
  }
  __PACKAGE__->export_to_level(1, $package, @_) if @_;
}

use PDL;

thread_define '_apply_over(data(n);[o]output()),NOtherPars=>2', over {
  # args: $data, $output, $func_name, \@func_args
  my $func = $_[2];
  my $args = $_[3];
  if (ref $func) {
    $_[1] .= PDL::Core::topdl($func->($_[0], @$args));
  }
  else {
    $_[1] .= PDL::Core::topdl($_[0]->$func(@$args));
  }
};

thread_define '_apply_slice_ND(data(n);sl(2,m);[o]output(m)),NOtherPars=>2', over {
  # args: $data, $slices, $output, $func_name, \@func_args
  _apply_slice_1D($_[1], ones($_[0]->type), my $output = null, $_[0], $_[3], $_[4]);
  $_[2] .= $output;
};

thread_define '_apply_slice_1D(slices(n);dummy();[o]output()),NOtherPars=>3', over {
  # args: $slices, $dummy, $output, $data, $func_name, \@func_args
  # XXX-HACK: $dummy is workaround to avoid the output piddle to be of type 'indx'
  # XXX-HACK: in fact this whole function is one big hack
  my $func = $_[4];
  my $args = $_[5];
  my $data = slice($_[3], $_[0]->unpdl);
  if ($data->ngood == 0) {
    $_[2] .= PDL->new('BAD');
  }
  else {
    if (ref $func) {
      $_[2] .= PDL::Core::topdl($func->($data, @$args));
    }
    else {
      $_[2] .= PDL::Core::topdl($data->$func(@$args));
    }
  }
};

sub apply_rolling {
  my ($pdl, $width, $func, @fargs) = @_;
  my @d = $pdl->dims;
  my $n = shift @d;
  my $start = sequence(indx, $n - $width + 1);
  my $end = $start + $width - 1;
  my $ind = cat($start, $end)->transpose;
  my $result = apply_slice($pdl, $ind, $func, @fargs);
  my $bad_start = zeroes($pdl->type, $width - 1, @d);
  $bad_start .= PDL->new('BAD');
  return $bad_start->glue(0, $result);
}

sub apply_slice {
  my ($pdl, $slices, $func, @fargs) = @_;
  my $result = null;
  $result->badflag(1);
  if ($pdl->dims > 1) {
    _apply_slice_ND($pdl, $slices, $result, $func, \@fargs);
  }
  else {
    _apply_slice_1D($slices, ones($pdl->type), $result, $pdl, $func, \@fargs);
  }
  return $result;
}

sub apply_over {
  my ($pdl, $func, @fargs) = @_;
  my $result = null;
  $result->badflag(1);
  _apply_over($pdl, $result, $func, \@fargs);
  return $result;
}

1;

__END__

=head1 NAME

PDL::Apply - Apply a given function in "rolling" / "moving" / "over" manners

=head1 SYNOPSIS

  use PDL;
  use PDL::Apply ':all';

  my $x = pdl([40.7,81.7,28.9,33.3,40.8,16.3]);

  print $x->apply_rolling(3, 'sum');
  # [ BAD BAD 151.3 143.9 103 90.4]

  print $x->apply_over('sum');
  # 241.7
  print $x->sumover;
  # 241.7

  my $slices = indx([ [0, 2], [4, 5] ]);
  print $x->apply_slice($slices, 'sum');
  # [151.3, 57.1]
  # 151.3 = 40.7+81.7+28.9 (indices 0..2)
  # 57.1  = 40.8+16.3 (indices 4..5)

=head1 DESCRIPTION

This module allows you to:

=over

=item * compute "rolling" functions (like C<Moving Average>) with given sliding window

=item * compute "over" like functions (like C<sumover>) with arbitrary function applied

=back

But keep in mind that the speed is far far beyond the functions with C implementation like C<sumover>.

=head1 FUNCTIONS

By default, PDL::Apply doesn't import any function. You can import individual functions like this:

 use PDL::Apply qw(apply_rolling apply_over);

Or import all available functions:

 use PDL::Apply ':all';

=head2 apply_over

 $result = apply_over($pdl, $func, @fargs);
 #or
 $result = $pdl->apply_over($func, @fargs);

 # $pdl    .. Input piddle, 1D or ND
 # $func   .. Function (PDL method) name as a string or code reference
 # @fargs  .. Optional arguments passed to function

=head2 apply_rolling

 $result = apply_rolling($pdl, $width, $func, @fargs);
 #or
 $result = $pdl->apply_rolling($width, $func, @fargs);

 # $pdl    .. Input piddle, 1D or ND
 # $width  .. Size of rolling window
 # $func   .. Function (PDL method) name as a string or code reference
 # @fargs  .. Optional arguments passed to function

=head2 apply_slice

 $result = apply_slice($pdl, $slices, $func, @fargs);
 #or
 $result = $pdl->apply_slice($slices, $func, @fargs);

 # $pdl    .. Input piddle, 1D or ND
 # $slices .. Piddle (2,N) with slices - [startidx, endidx] pairs
 # $func   .. Function (PDL method) name as a string or code reference
 # @fargs  .. Optional arguments passed to function

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

2015+ KMX E<lt>kmx@cpan.orgE<gt>
