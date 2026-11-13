#!/usr/bin/env perl

# Release-consistency checks: the version must agree everywhere, and the
# Strict <-> BNF module pair must load cleanly in either order.

use strict;
use warnings;
use Test::Most;

use File::Spec;

use_ok('Params::Validate::Strict');
use_ok('Params::Validate::Strict::BNF');

# ── Version agreement ────────────────────────────────────────────────────────

my $version = $Params::Validate::Strict::VERSION;
ok(defined($version) && length($version), 'Params::Validate::Strict has a $VERSION');
is($Params::Validate::Strict::BNF::VERSION, $version, 'BNF.pm $VERSION matches Strict.pm');

my $strict_pm = $INC{'Params/Validate/Strict.pm'};
my $root = File::Spec->catdir((File::Spec->splitpath($strict_pm))[1], File::Spec->updir, File::Spec->updir, File::Spec->updir);

sub _slurp {
	my $file = shift;
	open(my $fh, '<', $file) or return;
	local $/;
	return scalar <$fh>;
}

SKIP: {
	my $pod = _slurp($strict_pm);
	skip 'cannot read the module source', 1 unless defined $pod;
	my ($pod_version) = $pod =~ /^=head1 VERSION\s+Version\s+(\S+)/m;
	is($pod_version, $version, 'POD "Version" line matches $VERSION');
}

SKIP: {
	my $changes = _slurp(File::Spec->catfile($root, 'Changes'));
	skip 'Changes is not available (installed copy)', 1 unless defined $changes;
	my ($top) = $changes =~ /^(\d+\.\d+(?:_\d+)?)\b/m;
	is($top, $version, 'topmost Changes entry matches $VERSION');
}

SKIP: {
	my $readme = _slurp(File::Spec->catfile($root, 'README.md'));
	skip 'README.md is not available (installed copy)', 1 unless defined $readme;
	my ($readme_version) = $readme =~ /^Version\s+(\S+)/m;
	is($readme_version, $version, 'README.md version matches $VERSION');
}

# ── Load order (each in a fresh perl, so nothing is pre-loaded) ──────────────

my $lib = File::Spec->catdir((File::Spec->splitpath($strict_pm))[1], File::Spec->updir);
$lib = File::Spec->canonpath($lib);

sub _perl_ok {
	my ($code, $name) = @_;
	my $out = `"$^X" "-I$lib" -we '$code' 2>&1`;
	is($? >> 8, 0, $name) or diag($out);
	unlike($out, qr/redefined|Subroutine .* redefined/i, "$name: no redefinition warnings");
}

_perl_ok(
	'use Params::Validate::Strict::BNF qw(bnf_to_matcher); my $m = bnf_to_matcher([q{<digit> ::= "1"}]); exit($m->("1") ? 0 : 1);',
	'BNF loaded first'
);
_perl_ok(
	'use Params::Validate::Strict qw(validate_strict); validate_strict(schema => { x => { type => "string", bnf => [q{<s> ::= "a"}] } }, input => { x => "a" }); exit 0;',
	'Strict loaded first, BNF loaded lazily by a bnf rule'
);

# ── Namespace hygiene ────────────────────────────────────────────────────────

foreach my $name (qw(croak carp confess cluck)) {
	ok(!Params::Validate::Strict->can($name), "Params::Validate::Strict does not leak $name");
	ok(!Params::Validate::Strict::BNF->can($name), "Params::Validate::Strict::BNF does not leak $name");
}

done_testing();
