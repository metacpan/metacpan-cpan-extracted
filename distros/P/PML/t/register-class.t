#! /usr/bin/perl -w
################################################################################
#
# 2_new.t (Test calling new as a method)
#
################################################################################
#
# Includes
#
################################################################################
use strict;
use Test;
################################################################################
#
# Setup
#
################################################################################
BEGIN {
	plan test => 4
} use PML;
################################################################################
#
# Start
#
################################################################################
my ($pml, @code, $output);

PML->register(
	name		=> 'test::arg',
	type		=> PML->ARG_ONLY,
	token		=> sub {
		my ($pml, $token) = @_;
		my ($name, $a, $b) = @{$token->data};
		return $pml->tokens_execute($a) + 1;
	},
);

PML->register(
	name		=> 'test::argblock',
	type		=> PML->ARG_BLOCK,
	token		=> sub {
		my ($pml, $token) = @_;
		my ($name, $a, $b) = @{$token->data};
		my $r = $pml->tokens_execute($a) + 1;
		$r .= ' ' . ($pml->tokens_execute($b) + 1);
		return $r;
	},
);

PML->register(
	name		=> 'test::block',
	type		=> PML->BLOCK_ONLY,
	token		=> sub {
		my ($pml, $token) = @_;
		my ($name, $a, $b) = @{$token->data};
		return $pml->tokens_execute($b) + 1;
	},
);

$pml = new PML;
@code = <DATA>;
$pml->parse(\@code);
$output = $pml->execute;

foreach (2, 4, 6, 8) {
	ok($output =~ /$_/);
}
################################################################################
#                              END-OF-SCRIPT                                   #
################################################################################
__END__
#
# This is PML for Testing
#
@test::arg("1")
@test::argblock("3"){5}
@test::block{7}
