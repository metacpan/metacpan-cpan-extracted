#!/usr/bin/perl -w
#
# Make sure the VT102 module's callbacks work.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

require Term::VT102::ZeroBased;

my $nt = 2;
my $i = 1;
my $testvar = 0;

print "$i..$nt\n";

my $vt = Term::VT102::ZeroBased->new ('cols' => 80, 'rows' => 25);

$vt->callback_call ('ROWCHANGE', 0, 0);

print "ok $i\n";
$i ++;

$vt->callback_set ('ROWCHANGE', \&testcallback, 123);
$vt->callback_call ('ROWCHANGE', 0, 0);
if ($testvar != 123) {
	print "not ok $i\n";
} else {
	print "ok $i\n";
}
$i ++;

sub testcallback {
	my ($vtobj, $callname, $arg1, $arg2, $privdata) = @_;
	$testvar = $privdata;
}

# EOF
