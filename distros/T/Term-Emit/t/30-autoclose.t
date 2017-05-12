#!perl -w
use strict;
use warnings;
use Test::More tests => 3;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                          -fh      => \$out,
                          -width   => 35};

$out = q{};
{ emit "Frimrodding quickly" }
is($out, "Frimrodding quickly........ [DONE]\n",  "Default autoclose severity");

Term::Emit::setopts(closestat => 'OK');
$out = q{};
{ emit "Frimrodding quickly" }
is($out, "Frimrodding quickly........ [OK]\n",    "Set autoclose severity");

Term::Emit::setopts(closestat => 'Yoyum');
$out = q{};
{ emit "Frimrodding quickly" }
is($out, "Frimrodding quickly........ [Yoyum]\n", "Set autoclose non-standard severity");
