#!perl -w
use strict;
use warnings;
use Test::More tests => 23;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                          -fh      => \$out,
                          -width   => 40};

# Scope nesting
$out = q{};
{ emit "Subdoulation of quantifoobar"; emit_done {-silent => 1};}
is($out, "Subdoulation of quantifoobar...\n",
            "One level silent closed by unspecified DONE");

$out = q{};
{ emit {-silent => 1}, "Subdoulation of quantifoobar"; }
is($out, "Subdoulation of quantifoobar...\n",
            "One level silent on emit, autoclosed");

foreach my $sev (keys %Term::Emit::SEVLEV, "Blah") {
    $out = q{};
    { emit "Subdoulation of quantifoobar"; emit_done {-silent => 1}, $sev;}
    is($out, "Subdoulation of quantifoobar...\n",
            "One level silent closed by $sev");
}

$out = q{};
{ emit {-silent => 1}, "Subdoulation of quantifoobar";
    { emit "Morgozider" }}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [DONE]\n",
            "Two levels autoclosed, outer silent");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider"; emit_ok }
  emit_done {-silent => 1};}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [OK]\n",
            "Two levels closed, outer silent");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider"; emit_warn }
    { emit "Nimrodicator"; emit_ok }
    { emit "Obfuscator of vanilse"; emit_notry }
  emit_done {-silent => 1};}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [WARN]\n".
         "  Nimrodicator.................. [OK]\n".
         "  Obfuscator of vanilse......... [NOTRY]\n",
            "Two levels, inner series, closed, outer silent");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit {-silent => 1}, "Morgozider";
        { emit "Frimrodding the quark" }
        { emit "Eouing our zyxxpth"; emit_crit }
    }
    { emit "Nimrodicator"; emit_ok }
    { emit "Obfuscator of vanilse"; emit_notry }
  emit_done;}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "    Frimrodding the quark....... [DONE]\n".
         "    Eouing our zyxxpth.......... [CRIT]\n".
         "  Nimrodicator.................. [OK]\n".
         "  Obfuscator of vanilse......... [NOTRY]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Three levels, mixed, mid silent");
