#! /usr/bin/perl -w
################################################################################
#
# z-finial.t (Final test to run)
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
	plan test => 2
} use PML;
################################################################################
#
# Start
#
################################################################################
my ($parser, @code, $output);

$parser = new PML;
@code = <DATA>;
$parser->parse(\@code); ok(1);
$output = $parser->execute;

$output =~ s/(\s|\n)//g;
ok($output =~ /^abcdefghijklmnopqrstuvwxyz$/);
################################################################################
#                              END-OF-SCRIPT                                   #
################################################################################
__END__
#
# This is PML for Testing
#
# produce the abc's
@set(x, a)
@if(${x}) {
	${x}
} @else {
	error
}

@perl {'b', 'c'}
@set(x, d, e, f)

LABEL: @foreach (0, 1, 2) {
	${x[${LABEL}]}
}

@set(x, 1)
@while(${x}) {
	g
	@last()
}

@rib(h){}
@rib(error){i}

@skip{j}

@set(y, blah)
@set(z, blah blah)
@set(x, 
	This is a test of the parsing of text and
	then doing things like ${y} and ${z} inside
	the text for performance reasons
)

@unless(0) {k}

@perl {$v{test} = {x => 'l'};undef}
${test.x}

# 
#
# this should all be skiped
#
# ${x} ${y} ${z}

m
@x()
@macro (x) {
	n
}

@set(x, magic)
@${x}()
@macro (magic) {
	o
}

pqrstuvwxyz
