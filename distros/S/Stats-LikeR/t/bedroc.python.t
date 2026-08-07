#!/usr/bin/env perl
# Cross-language check of bedroc() against the production Python code in
# ~/ui/pep-priml (train-anomaly/pipeline/_compute.py's bedroc_score/ef_at_frac
# and train-regress/train.py's _bedroc, copied verbatim into
# t/bedroc.python.py).  t/bedroc.t pins bedroc() against an independent R
# reimplementation; this one pins it against the Python one, including the
# regression variant (actives = lowest active_frac of a raw numeric column,
# ranked lowest-prediction-first) that active_frac/active_side/direction
# exist to reproduce.
require 5.010;
use warnings FATAL => 'all';
use strict;
use Stats::LikeR;
use Test::More;
use File::Basename 'dirname';
use File::Spec;

my $py = File::Spec->catfile(dirname(__FILE__), 'bedroc.python.py');
plan skip_all => "reference generator $py not found" unless -f $py;

eval { require JSON::PP; 1 } or plan skip_all => 'JSON::PP not available';

my $probe = `python3 -c "import numpy, scipy" 2>&1`;
plan skip_all => 'python3 with numpy + scipy not available' if $?;

my $json = `python3 \Q$py\E`;
plan skip_all => "python3 $py failed: $json" if $? or $json !~ /\S/;

my $cases = JSON::PP->new->decode($json);
plan skip_all => 'no cases generated' unless @$cases;

# BEDROC in [0,1] can be as small as ~1e-14 for the worst-case orderings at
# large alpha, so accept either an absolute or a relative match.
sub is_close {
	my ($got, $want, $name, $tol) = @_;
	$tol //= 1e-9;
	if (not defined $got) { fail("$name (got undef)"); return 0 }
	my $diff = abs($got - $want);
	my $rel  = abs($want) > 0 ? $diff / abs($want) : $diff;
	return pass($name) if $diff <= $tol or $rel <= $tol;
	fail($name);
	diag("         got: $got\n    expected: $want\n        diff: $diff (rel $rel)");
	return 0;
}

my $n_bin = my $n_reg = 0;
for my $c (@$cases) {
	my %opt = %{ $c->{opts} };
	my $r   = bedroc($c->{scores}, $c->{labels}, %opt);
	my $tag = "$c->{python_fn}: $c->{name}";

	is_close($r->{bedroc}, $c->{bedroc}, "$tag: bedroc");
	is($r->{n},        $c->{n},        "$tag: n");
	is($r->{n_active}, $c->{n_active}, "$tag: n_active");

	if (exists $c->{rie}) {          # binary cases also pin the RIE internals
		is_close($r->{rie},     $c->{rie},     "$tag: rie");
		is_close($r->{rie_min}, $c->{rie_min}, "$tag: rie_min");
		is_close($r->{rie_max}, $c->{rie_max}, "$tag: rie_max");
		is_close($r->{ra},      $c->{ra},      "$tag: ra");
		# the Python (RIE - RIE_min)/(RIE_max - RIE_min) normalisation must
		# equal the XS's RIE * factor1 + factor2 form
		is_close(($r->{rie} - $r->{rie_min}) / ($r->{rie_max} - $r->{rie_min}),
		         $c->{bedroc}, "$tag: (rie-min)/(max-min) == python bedroc");
	}
	if (exists $c->{ef}) {           # top => enrichment vs ef_at_frac()
		is_close($r->{enrichment}{enrichment_factor}, $c->{ef}, "$tag: EF top=$opt{top}");
	}
	$c->{python_fn} eq '_bedroc' ? $n_reg++ : $n_bin++;
}

note("compared $n_bin binary-label cases and $n_reg regression-variant cases "
   . "against python3");
done_testing();
