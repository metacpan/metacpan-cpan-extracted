# Copyright 2009 Francesco Nidito. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Statistics::OnLine;

use strict;

use vars qw($VERSION);
$VERSION = '0.02';

sub new {
  my $class = shift;
  return bless {
                _count => 0,
                _mean => 0,
                _M2 => 0,
                _M3 => 0,
                _M4 => 0,
                version => $VERSION,
               }, $class;
}

sub add_data {
  my $self = shift;
  foreach my $x (@_) { $self->_update_statistics($x); }
  return $self;
}

sub clean {
  my ($self) = @_;
  foreach my $i (grep /^_/, keys %{$self} ){ $self->{$i} = 0; }
  return $self;
}

# fast algorithm to update all the statistics at once:
# http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Higher-order_statistics
sub _update_statistics {
  my ($self, $x) = @_;
  my ($mean, $M2, $M3, $M4) = (0, 0, 0, 0);

  $self->{_count}++;
  my $n = $self->{_count}; # shorter to write $n ;-)

  # $n**2 and $n**3 efficiently
  my $n2 = $n*$n;
  my $n3 = $n2*$n;

  my $delta = $x - $self->{_mean};

  # $delta**(2|3|4)... efficiently
  my $delta2 = $delta*$delta;
  my $delta3 = $delta2*$delta;
  my $delta4 = $delta3*$delta;

  $mean = $self->{_mean} + $delta/$n;
  $M2   = $self->{_M2}   + $delta2*($n - 1)/$n;
  $M3   = $self->{_M3}   + $delta3*($n-1)*($n-2)/$n2       - 3*$delta*$self->{_M2}/$n;
  $M4   = $self->{_M4}   + $delta4*($n-1)*($n2-3*$n+3)/$n3 + 6*$delta2*$self->{_M2}/$n2 - 4*$delta*$self->{_M3}/$n;

  $self->{_mean} = $mean;
  $self->{_M2}   = $M2;
  $self->{_M3}   = $M3;
  $self->{_M4}   = $M4;
}

sub count {
  return $_[0]->{_count};
}

sub mean {
  die "too few elements to compute mean" if( $_[0]->{_count} == 0 );
  return $_[0]->{_mean};
}

sub variance {
  die "too few elements to compute variance" if( $_[0]->{_count} < 2 );
  return $_[0]->{_M2}/($_[0]->{_count} - 1);
}

sub variance_n {
  die "too few elements to compute variance_n" if( $_[0]->{_count} == 0 );
  return $_[0]->{_M2}/$_[0]->{_count};
}

sub skewness {
  die "too few elements to compute skewness" if( $_[0]->{_count} == 0 );
  die "variance is zero: cannot compute skewness" if( $_[0]->{_M2} == 0 );

  return sqrt( $_[0]->{_count} )*$_[0]->{_M3}/( $_[0]->{_M2}**(3/2));
}

sub kurtosis {
  die "too few elements to compute kurtosis" if( $_[0]->{_count} < 4 );
  die "variance is zero: cannot compute kurtosis" if( $_[0]->{_M2} == 0 );

  return $_[0]->{_count}*$_[0]->{_M4}/($_[0]->{_M2}*$_[0]->{_M2}) - 3;
}

1;

__END__

=head1 NAME

Statistics::OnLine - Pure Perl implementation of the on-line algorithm to produce statistics

=head1 SYNOPSIS

 use Statistics::OnLine;
 my $s = Statistics::OnLine->new;
 
 my @data = (1, 2, 3, 4, 5);
 $s->add_data( @data );
 $s->add_data( 6, 7 );
 $s->add_data( 8 );
 
 print "count = ",$s->count,"\tmean = ",$s->mean,"\tvariance = ",$s->variance,"\tvariance_n = ",
       $s->variance_n,"\tskewness = ",$s->skewness,"\tkurtosis = ",$s->kurtosis,"\n";
 
 $s->add_data( ); # does nothing!
 print "count = ",$s->count,"\tmean = ",$s->mean,"\tvariance = ",$s->variance,"\tvariance_n = ",
       $s->variance_n,"\tskewness = ",$s->skewness,"\tkurtosis = ",$s->kurtosis,"\n";
 
 $s->add_data( 9, 10 );
 print "count = ",$s->count,"\tmean = ",$s->mean,"\tvariance = ",$s->variance,"\tvariance_n = ",
       $s->variance_n,"\tskewness = ",$s->skewness,"\tkurtosis = ",$s->kurtosis,"\n";

=head1 DESCRIPTION

This module implements a tool to perform statistic operations on large datasets which, typically, could not fit the memory of the machine, e.g. a stream of data from the network.

Once instantiated, an object of the class provide an C<add_data> method to add data to the dataset. When the computation of some statistics is required, at some point of the stream, the appropriate method can be called. After the execution of the statistics it is possible to continue to add new data. In turn, the object will continue to update the existing data to provide new statistics.

=head1 METHODS

=over 4

=item new()

Creates a new C<Statistics::OnLine> object and returns it.

=item add_data(@)

Adds new data to the object and updates the internal state of the statistics.

The method return the object itself in order to use it in chaining:

 my $v = $s->add_data( 1, 2, 3, 4 )->variance;

=item clean()

Cleans the internal state of the object and resets all the internal statistics.

Return the object itself in order to use it in chaining:

 my $v = $s->clean->add_data( 1, 2, 3, 4 )->variance;

=item count()

Returns the actual number or elements inserted and processed by the object.

=item mean()

Returns the average of the elements inserted into the system:

 \fract{ \sum_1^n{x_i} }{ n }

=item variance()

Returns the variance of the element inserted into the system:

 \fract{ \sum_1^n{avg - x_i} }{ n - 1 }

=item variance_n()

Returns the variance of the element inserted into the system:

 \fract{ \sum_1^n{avg - x_i} }{ n }

=item skewness()

Returns the skewness (third standardized moment) of the element inserted into the system L<http://en.wikipedia.org/wiki/Skewness>

=item kurtosis()

Returns the kurtosis (fourth standardized moment) of the element inserted into the system L<http://en.wikipedia.org/wiki/Kurtosis>

=back

=head1 ERROR MESSAGES

The conditions in which the system can return errors, using a C<die> are:

=over 4

=item too few elements to compute I<function>

Some functions need a minimum number of elements to be computed: C<mean>, C<variance_n> and C<skewness> need at least one element, C<variance> at least two and C<kurtosis> needs at least four.

=item variance is zero: cannot compute I<kurtosis|skewness>

Both kurtosis and skewness need that variance to be greater than zero.

=back

=head1 THEORY

On-line statistics are based on strong mathematical foundations which transform the standard computations into a sequence of operations that incrementally update with new values the actual ones.

There are some referencence in the web. This documentation suggest to start your investigation from L<http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Higher-order_statistics>. The linked page provides other useful references on the foundations of the method.

=head1 CAVEAT

The module is intended to be used in all the situations in which: (1) the number of data elements could be too large with respect the memory of the system, or (2) the elements arrive at different time stamps and intermediate results are needed.

If the length of the stream is fixed, all the data elements are present in a single place and there is not need for intermediate results, it could be better to use different modules, for instance L<Statistics::Lite>, to make computations.

The reason for this choice is that the module uses a stable approximation, well suited for the use on steams (effectively an on-line algorithm). Using this system on fixed datasets could introduce some (little) approximation.

=head1 HISTORY

=over 4

=item 0.02

Corrected typos in documentation

=item 0.01

Initial version of the module

=back

=head1 AUTHOR

Francesco Nidito

=head1 COPYRIGHT

Copyright 2009 Francesco Nidito. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Statistics::Lite>, L<http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Higher-order_statistics>

=cut
