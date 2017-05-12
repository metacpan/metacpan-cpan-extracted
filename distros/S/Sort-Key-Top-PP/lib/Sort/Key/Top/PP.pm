package Sort::Key::Top::PP;

use 5.008;
use strict;
use warnings;
no warnings qw( once );

BEGIN {
	$Sort::Key::Top::PP::AUTHORITY = 'cpan:TOBYINK';
	$Sort::Key::Top::PP::VERSION   = '0.003';
}

use Exporter::Shiny our(@EXPORT) = qw(
	top
	topsort
	keytop
	keytopsort
	ntop
	ntopsort
	nkeytop
	nkeytopsort
	rtop
	rtopsort
	rkeytop
	rkeytopsort
	rntop
	rntopsort
	rnkeytop
	rnkeytopsort
	head
	nhead
	keyhead
	nkeyhead
	tail
	ntail
	keytail
	nkeytail
);

sub _tail_numeric {
	my ($list, $top_n) = @_;
	my @top;
	my $cur;
	for my $i (@$list) {
		next if @top==$top_n && $i->[0] < $top[0][0];
		((@top = $i), next) unless @top;
		my ($low, $high) = (0, scalar @top);
		(
			($cur = ($low + $high) >> 1),
			($i->[0] - $top[$cur][0] > 0)
				? ($low = $cur + 1)
				: ($high = $cur),
		) while $low < $high;
		splice(@top, $low, 0, $i);
		shift @top if @top > $top_n;
	}
	return reverse @top;
}

sub _head_numeric {
	my ($list, $top_n) = @_;
	my @top;
	my $cur;
	for my $i (@$list) {
		next if @top==$top_n && $i->[0] > $top[0][0];
		((@top = $i), next) unless @top;
		my ($low, $high) = (0, scalar @top);
		(
			($cur = ($low + $high) >> 1),
			($top[$cur][0] - $i->[0] > 0)
				? ($low = $cur + 1)
				: ($high = $cur),
		) while $low < $high;
		splice(@top, $low, 0, $i);
		shift @top if @top > $top_n;
	}
	return reverse @top;
}

sub _head_stringy {
	my ($list, $top_n) = @_;
	my @top;
	my $cur;
	for my $i (@$list) {
		next if @top==$top_n && $i->[0] gt $top[0][0];
		((@top = $i), next) unless @top;
		my ($low, $high) = (0, scalar @top);
		(
			($cur = ($low + $high) >> 1),
			(($top[$cur][0] cmp $i->[0]) > 0)
				? ($low = $cur + 1)
				: ($high = $cur),
		) while $low < $high;
		splice(@top, $low, 0, $i);
		shift @top if @top > $top_n;
	}
	return reverse @top;
}

sub _tail_stringy {
	my ($list, $top_n) = @_;
	my @top;
	my $cur;
	for my $i (@$list) {
		next if @top==$top_n && $i->[0] lt $top[0][0];
		((@top = $i), next) unless @top;
		my ($low, $high) = (0, scalar @top);
		(
			($cur = ($low + $high) >> 1),
			(($top[$cur][0] cmp $i->[0]) < 0)
				? ($low = $cur + 1)
				: ($high = $cur),
		) while $low < $high;
		splice(@top, $low, 0, $i);
		shift @top if @top > $top_n;
	}
	return reverse @top;
}

sub _preprocess {
	my $code  = shift;
	my $count = 0;
	$code
		? [ map [ $code->($_), $_, $count++ ], @_ ]
		: [ map [ $_         , $_, $count++ ], @_ ];
}

sub _postprocess {
	my $n = shift;
	wantarray
		? map($_->[1], @_)
		: ( @_ >= $n ? $_[-1][1] : undef )
}

sub _restore_order;
if (eval { require Sort::Key }) {
	*_restore_order = sub { &Sort::Key::ikeysort(sub { $_->[2] }, @_) };
}
else {
	*_restore_order = sub { sort { $a->[2] <=> $b->[2] } @_ };
}

sub top {
	my $n = shift;
	_postprocess $n,
	_restore_order
	_head_stringy(
		_preprocess(undef, @_),
		$n
	);
}

sub topsort {
	my $n = shift;
	_postprocess $n,
	_head_stringy(
		_preprocess(undef, @_),
		$n
	);
}

sub keytop (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_restore_order
	_head_stringy(
		_preprocess($k, @_),
		$n
	);
}

sub keytopsort (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_head_stringy(
		_preprocess($k, @_),
		$n
	);
}

sub ntop {
	my $n = shift;
	_postprocess $n,
	_restore_order
	_head_numeric(
		_preprocess(undef, @_),
		$n
	);
}

sub ntopsort {
	my $n = shift;
	_postprocess $n,
	_head_numeric(
		_preprocess(undef, @_),
		$n
	);
}

sub nkeytop (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_restore_order
	_head_numeric(
		_preprocess($k, @_),
		$n
	);
}

sub nkeytopsort (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_head_numeric(
		_preprocess($k, @_),
		$n
	);
}

sub rtop {
	my $n = shift;
	_postprocess $n,
	_restore_order
	_tail_stringy(
		_preprocess(undef, @_),
		$n
	);
}

sub rtopsort {
	my $n = shift;
	_postprocess $n,
	_tail_stringy(
		_preprocess(undef, @_),
		$n
	);
}

sub rkeytop (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_restore_order
	_tail_stringy(
		_preprocess($k, @_),
		$n
	);
}

sub rkeytopsort (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_tail_stringy(
		_preprocess($k, @_),
		$n
	);
}

sub rntop {
	my $n = shift;
	_postprocess $n,
	_restore_order
	_tail_numeric(
		_preprocess(undef, @_),
		$n
	);
}

sub rntopsort {
	my $n = shift;
	_postprocess $n,
	_tail_numeric(
		_preprocess(undef, @_),
		$n
	);
}

sub rnkeytop (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_restore_order
	_tail_numeric(
		_preprocess($k, @_),
		$n
	);
}

sub rnkeytopsort (&$@) {
	my $k = shift;
	my $n = shift;
	_postprocess $n,
	_tail_numeric(
		_preprocess($k, @_),
		$n
	);
}

sub head {
	unshift @_, 1;
	scalar &topsort;
}

sub nhead {
	unshift @_, 1;
	scalar &ntopsort;
}

sub keyhead (&@) {
	splice(@_, 1, 0, 1);
	scalar &keytopsort;
}

sub nkeyhead (&@) {
	splice(@_, 1, 0, 1);
	scalar &nkeytopsort;
}

sub tail {
	unshift @_, 1;
	scalar &rtopsort;
}

sub ntail {
	unshift @_, 1;
	scalar &rntopsort;
}

sub keytail (&@) {
	splice(@_, 1, 0, 1);
	scalar &rkeytopsort;
}

sub nkeytail (&@) {
	splice(@_, 1, 0, 1);
	scalar &rnkeytopsort;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sort::Key::Top::PP - pure Perl implementation of parts of Sort::Key::Top

=head1 SYNOPSIS

	use Sort::Key::Top::PP 'top';
	my @top5 = top 5 => @biglist;

=head1 DESCRIPTION

Sort::Key::Top::PP is set of functions for finding the top "n" items in an
array by some criteria. It's not as fast as L<Sort::Key::Top>, but it is
generally quite a bit faster than sorting the entire array and taking the
first "n" items.

This module implements pure Perl equivalents of the following functions as
descibed in L<Sort::Key::Top>.

=over

=item *

C<top>

=item *

C<topsort>

=item *

C<keytop>

=item *

C<keytopsort>

=item *

C<ntop>

=item *

C<ntopsort>

=item *

C<nkeytop>

=item *

C<nkeytopsort>

=item *

C<rtop>

=item *

C<rtopsort>

=item *

C<rkeytop>

=item *

C<rkeytopsort>

=item *

C<rntop>

=item *

C<rntopsort>

=item *

C<rnkeytop>

=item *

C<rnkeytopsort>

=item *

C<head>

=item *

C<nhead>

=item *

C<keyhead>

=item *

C<nkeyhead>

=item *

C<tail>

=item *

C<ntail>

=item *

C<keytail>

=item *

C<nkeytail>

=back

By default I<< all functions are exported >>. If you don't like that, then
please specify an explicit list of functions to import, a la:

   use Sort::Key::Top::PP qw( top );

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sort-Key-Top-PP>.

=head1 SEE ALSO

L<Sort::Key::Top>,
L<http://blogs.perl.org/users/stas/2012/12/tmtowtdi-plus-benchmarking.html#comments>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Key parts of the top n selection algorithm (and much egging on) by Stanislaw
Pusep (cpan:SYP).

API inspired by L<Sort::Key::Top> by Salvador Fandiño García (cpan:SALVA).

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

