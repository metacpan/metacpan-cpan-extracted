#!perl -w
use strict;
use warnings;
use Test::More tests => 27;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                          -fh      => \$out,
                          -width   => 40};

# Scope nesting
$out = q{};
{ emit "Subdoulation of quantifoobar"; emit_done;}
is($out, "Subdoulation of quantifoobar.... [DONE]\n",
            "One level closed by unspecified DONE");

$out = q{};
{ emit "Subdoulation of quantifoobar"; }
is($out, "Subdoulation of quantifoobar.... [DONE]\n",
            "One level autoclosed");

foreach my $sev (keys %Term::Emit::SEVLEV, "Blah") {
    $out = q{};
    { emit "Subdoulation of quantifoobar"; emit_done $sev;}
    is($out, "Subdoulation of quantifoobar.... [$sev]\n",
            "One level closed by $sev");
}

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider" }}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [DONE]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Two levels autoclosed");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider"; emit_ok }
  emit_done;}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [OK]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Two levels closed");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider"; emit_warn }
    { emit "Nimrodicator"; emit_ok }
    { emit "Obfuscator of vanilse"; emit_notry }
  emit_done;}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [WARN]\n".
         "  Nimrodicator.................. [OK]\n".
         "  Obfuscator of vanilse......... [NOTRY]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Two levels, inner series, closed");

$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark" }
        { emit "Eouing our zyxxpth"; emit_crit }
      emit_warn; }
    { emit "Nimrodicator"; emit_ok }
    { emit "Obfuscator of vanilse"; emit_notry }
  emit_done;}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "    Frimrodding the quark....... [DONE]\n".
         "    Eouing our zyxxpth.......... [CRIT]\n".
         "  Morgozider.................... [WARN]\n".
         "  Nimrodicator.................. [OK]\n".
         "  Obfuscator of vanilse......... [NOTRY]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Three levels, mixed");

# Line wrapping
$out = q{};
{ emit "Wrappification of superlinear magmafied translengthed task strings";}
is($out, "Wrappification of superlinear\n".
         "magmafied translengthed task\n".
         "strings......................... [DONE]\n",
            "One level wrapped");

$out = q{};
{ emit "Wrappification of superlinear magmafied translengthed task strings";
  { emit "Short level 1 line"; }
}
is($out, "Wrappification of superlinear\n".
         "magmafied translengthed task\n".
         "strings...\n".
         "  Short level 1 line............ [DONE]\n".
         "Wrappification of superlinear\n".
         "magmafied translengthed task\n".
         "strings......................... [DONE]\n",
            "Two levels, outer wrapped");

$out = q{};
{ emit "Short level 0";
  { emit "Wrappification of superlinear magmafied translengthed task strings"; }
}
is($out, "Short level 0...\n".
         "  Wrappification of superlinea\n".
         "  r magmafied translengthed\n".
         "  task strings.................. [DONE]\n".
         "Short level 0................... [DONE]\n",
            "Two levels, inner wrapped");

$out = q{};
{ emit "Spatial folding process is underway at this very moment";
  { emit "Wrappification of superlinear magmafied translengthed task strings"; }
}
is($out, "Spatial folding process is\n".
         "underway at this very moment...\n".
         "  Wrappification of superlinea\n".
         "  r magmafied translengthed\n".
         "  task strings.................. [DONE]\n".
         "Spatial folding process is\n".
         "underway at this very moment.... [DONE]\n",
            "Two levels, both wrapped");
