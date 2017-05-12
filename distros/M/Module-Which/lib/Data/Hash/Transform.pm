
package Data::Hash::Transform;
$Data::Hash::Transform::VERSION = '0.05';
use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hash_f hash_l hash_m hash_a hash_em);

use Carp qw(croak);

=head1 NAME

Data::Hash::Transform - Turns array of hashes to hash of hashes in predefined ways

=head1 SYNOPSIS

  use Data::Hash::Transform qw(hash_f hash_l hash_m hash_a hash_em);

  my $loh = [ { k => 1, n => 'one' }, { k => 2, n => 'two' }, { k => 1, n => 'ein' } ];
  $hoh1 = hash_f($loh, 'k'); # keep first
  $hoh2 = hash_l($loh, 'k'); # keep last
  $hoh3 = hash_m($loh, 'k'); # keep a list (if needed)
  $hoh4 = hash_a($loh, 'k'); # always keep a list

  $hoh = hash_em($loh, 'k', $meth); # $meth is one of 'f', 'l', 'm', or 'a'

=head1 DESCRIPTION

This module provides four algorithms to turn an array of hashes 
to a hash of hashes. The transformation is based on using
the value at a certain key of inner hashes as the key 
in the outer hash.

So:

  [ { k => 1, n => 'one' }, { k => 2, n => 'two' } ]

turns to

  { 1 => { k => 1, n => 'one' }, 2 => { k => 2, n => 'two } }

when C<'k'> is the key of keys. (From this example, it was
made obvious that here we mean array and hash refs when talking about
arrays and hashes.)

The difference among the algorithms happen when the same key happens
twice or more. For example, how do the following array maps
to a hash? (C<'k'> is still the key of keys here.)

  [ { k => 1, n => 'one' }, { k => 2, n => 'two' }, { k => 1, n => 'ein' } ]

The following alternatives (among others) are possible:

=over 4

=item *

keep the first

  { 1 => { k => 1, n => 'one' }, 2 => { k => 2, n => 'two' } }

=item *

keep the last

  { 2 => { k => 2, n => 'two' }, 1 => { k => 1, n => 'ein' }  }

=item *

keep a list in the case of collisions

  { 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ],
    2 => { k => 2, n => 'two' } }

=item *

always keep a list (for the case of collisions)

  { 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ],
    2 => [ { k => 2, n => 'two' } ] }

=back

That is exactly what we implement here.

=head2 EXPORT

None by default. C<hash_f>, C<hash_l>, C<hash_m>, C<hash_a>,
C<hash_em> can be exported on demand.

=cut


# keep last (remember (l)ast)
sub hash_l {
	my ($ary, $kk) = @_;
	my %hash;
	$hash{$_->{$kk}} = $_ for @$ary;
	return \%hash;
}

# note. The implementation takes for granted that
# the inner hashes have $kk as keys. If they don't
# C<undef> will turn to C<''> and things can get
# messed up.

# keep first (remember (f)irst)
sub hash_f {
	my ($ary, $kk) = @_;
	my %hash;
	for (@$ary) {
		my $k = $_->{$kk};
		$hash{$k} = $_ unless exists $hash{$k};
	}
	return \%hash;
}

# keep an array in case of collisions (remember (m)ulti)
sub hash_m {
	my ($ary, $kk) = @_;
	my %hash;
	for (@$ary) {
		my $k = $_->{$kk};
		if (exists $hash{$k}) {
			$hash{$k} = [ $hash{$k} ] if ref $hash{$k} ne 'ARRAY';
			push @{$hash{$k}}, $_;
		} else {
			$hash{$k} = $_;
		}
	}
	return \%hash;
}

# always keep an array (remember (a)rray)
sub hash_a {
	my ($ary, $kk) = @_;
	my %hash;
	for (@$ary) {
		my $k = $_->{$kk};
		if (exists $hash{$k}) {
			push @{$hash{$k}}, $_;
		} else {
			$hash{$k} = [ $_ ];
		}
	}
	return \%hash;
}

# all of them together
sub hash_em {
	my ($ary, $kk, $m) = @_;
	my %methods = ( l => \&hash_l, f => \&hash_f, m => \&hash_m, a => \&hash_a );
	my $method = $methods{$m || 'f'}
		or croak "hash_em method '$m' unknown: should be one of 'l', 'f', 'm', or 'a'";
	return &$method($ary, $kk);
}

=pod

=head1 HASH_M VERSUS HASH_A

The difference between using C<hash_m> and C<hash_a> is
primarily oriented to the code that is going to consume
the transformed hash. In the case of C<hash_m>, it must
be ready to handle two cases: a single element which appears
as a hash ref and multiple elements which appear as an
array ref of hash refs. In the case of C<hash_a>, 
the treatment is more homogeneous and you will always
get an array ref of hash refs.

A typical code with the return of C<hash_m> is illustrated
by the code below.

  my $h = hash_m($loh);
  while (my ($k, $v) = each %$h) {
	  if (ref $v eq 'ARRAY') {
		  do something with $_ for @$v;
	  } else {
		  do something with $v
	  }
  }

or the shorter:

  my $h = hash_m($loh);
  while (my ($k, $v) = each %$h) {
	  my @vs = (ref $v eq 'ARRAY') ? @$v : ($v);
	  do something with $_ for @vs;
  }

With C<hash_a>, it would look like:

  my $h = hash_m($loh);
  while (my ($k, $v) = each %$h) {
	  do something with $_ for @$v;
  }

It is a trade-off: the client code can be simple (C<hash_a>)
or the overhead of data structures can be reduced (C<hash_m>).

=head1 TO DO

If you are familiar with L<XML::Simple>, you probably have
recognized some of the tranformations it does with hashes against arrays.
Mainly, the ones represented by C<hash_m> and C<hash_l>
(when C<ForceArray> is used).

Other transformations based on typical behavior of
L<XML::Simple> are possible. For example,

=over 4

=item *

discard the key element

  [ { k => 1, n => 'one' }, { k => 2, n => 'two' } ]

to

  { 1 => { n => 'one' }, 2 => { n => 'two' } }

and even (for C<'n'> defined to be the contents key)

  { 1 => 'one', 2 => 'two' }

=item *

mark the key element

  [ { k => 1, n => 'one' }, { k => 2, n => 'two' }, { k => 1, n => 'ein' } ]

to

  { 1 => { -k => 1, n => 'one' }, 2 => { -k => 2, n => 'two' } }

=back

Maybe someday this gets implemented too. 

=head1 ISSUES

The functions C<hash_*> have been designed to be fast
and that's why their code is redundant. One could write a 
function with all bells and whistles which does all the
work of them together, by using options and querying them
at runtime. I think the code would be slightly harder to maintain
and perfomance may suffer. But this is just guessing.
Soon I will write such an implementation and a benchmark
to make sure it is worth to use this code as it is.

=for comment
=head1 SEE ALSO

=head1 BUGS

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Which>.

=head1 AUTHOR

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1;

