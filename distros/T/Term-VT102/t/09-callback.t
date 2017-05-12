#!/usr/bin/perl -w
#
# Make sure the VT102 module's callbacks work.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

require Term::VT102;

my $nt = 5;
my $i = 1;
my ($testarg1, $testarg2, $testpriv) = (0, 0, 0);

print "$i..$nt\n";

my $vt = Term::VT102->new ('cols' => 80, 'rows' => 25);

# Test 1 - ROWCHANGE callback runs at all

$vt->callback_call ('ROWCHANGE', 0, 0);
print "ok $i\n";
$i ++;

# Test 2 - ROWCHANGE callback sets private data

$vt->callback_set ('ROWCHANGE', \&testcallback, 123);
$vt->callback_call ('ROWCHANGE', 0, 0);
if ($testpriv != 123) {
	print "not ok $i\n";
} else {
	print "ok $i\n";
}
$vt->callback_set ('ROWCHANGE', undef);
$i ++;

# Test 3 - STRING callback reports ESC _ values OK

$vt->callback_set ('STRING', \&testcallback, $i);
$vt->process ("\033_Test String\033\\test");
if (($testarg1 ne 'APC') || ($testarg2 ne 'Test String') || ($testpriv != $i)) {
	print "not ok $i\n";
	print STDERR "\nTest $i: arg1=[$testarg1], arg2=[$testarg2], priv=[$testpriv]\n";
} else {
	print "ok $i\n";
}
$vt->callback_set ('STRING', undef);
$i ++;

# Test 4 - XICONNAME callback reports X icon name changes

$vt->callback_set ('XICONNAME', \&testcallback, $i);
$vt->process ("\033]1;Test Icon Name\033\\test");
if (($testarg1 ne 'Test Icon Name') || ($testpriv != $i)) {
	print "not ok $i\n";
	print STDERR "\nTest $i: arg1=[$testarg1], arg2=[$testarg2], priv=[$testpriv]\n";
} else {
	print "ok $i\n";
}
$vt->callback_set ('XICONNAME', undef);
$i ++;

# Test 5 - XWINTITLE callback reports X title changes

$vt->callback_set ('XWINTITLE', \&testcallback, $i);
$vt->process ("\033]2;Test Title\033\\test");
if (($testarg1 ne 'Test Title') || ($testpriv != $i)) {
	print "not ok $i\n";
	print STDERR "\nTest $i: arg1=[$testarg1], arg2=[$testarg2], priv=[$testpriv]\n";
} else {
	print "ok $i\n";
}
$vt->callback_set ('XWINTITLE', undef);
$i ++;


sub testcallback {
	my ($vtobj, $callname, $arg1, $arg2, $privdata) = @_;
	($testarg1, $testarg2, $testpriv) = ($arg1, $arg2, $privdata);
}

# EOF
