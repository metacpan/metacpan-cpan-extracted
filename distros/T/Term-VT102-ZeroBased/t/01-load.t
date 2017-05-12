#!/usr/bin/perl -w
#
# Make sure the VT102 module loads OK and can return its version number.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

BEGIN {
	print "1..1\n";
}

require Term::VT102::ZeroBased;

my $vt = Term::VT102::ZeroBased->new ('cols' => 80, 'rows' => 25);

print "Version: " . $vt->version () . "\n";

print "ok 1\n";

# EOF
