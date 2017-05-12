#!perl -w
use strict;
use warnings;
use Test::More tests => 4;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                          -fh      => \$out,
                          -width   => 50};

# No timestamp
$out = q{};
{ emit "Now is the time for"; emit_done;}
is($out, "Now is the time for....................... [DONE]\n",   "No Timestamp");

# Default Timestamp
Term::Emit::setopts(-timestamp => 1);
$out = q{};
{ emit "Now is the time for"; emit_done;}
like($out, qr/^\d\d:\d\d:\d\d Now is the time for\.+ \[DONE]\n/, "Default Timestamp");

# Timestamp on wrapped line
$out = q{};
{ emit "Now is the time for all good men to come"; emit_done;}
like($out, qr/^\d\d:\d\d:\d\d Now is the time for all good\n\s+men to come\.+ \[DONE]\n/, "Wrapped line");

# Custom Timestamp
Term::Emit::setopts(-timestamp => \&t);
$out = q{};
{ emit "Now is the time for"; emit_done;}
like($out, qr/^\d+-\d+-Now is the time for\.+ \[DONE]\n/, "Custom Timestamp");

exit 0;

# Example Custom timestamp
sub t {
    my $level = shift;
    return sprintf "%d-%d-", $level, time();
}
