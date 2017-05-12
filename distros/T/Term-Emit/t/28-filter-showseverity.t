#!perl -w
use strict;
use warnings;
use Test::More tests => 5;

my $out;
use Term::Emit qw/:all/, {-fh      => \$out,
                          -step    => 2,
                          -width   => 40};

# Baseline
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit {-reason => "Important"};
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "    Frimrodding the quark...\n".
         "      Eouing our zyxxpth...\n".
         "        Shiniffing.............. [DONE]\n".
         "      Eouing our zyxxpth........ [CRIT]\n".
         "        Important\n".
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Unfiltered");

# Show a severe message from the depths
Term::Emit::setopts(-maxdepth => 0, -showseverity => $Term::Emit::SEVLEV{'CRIT'});
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit {-reason => "Important"};
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "      Eouing our zyxxpth........ [CRIT]\n".
         "        Important\n",
   "All filtered, but criticals");

# Depth filtering at outermost plus a severe message
Term::Emit::setopts(-maxdepth => 1, -showseverity => $Term::Emit::SEVLEV{'CRIT'});
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit {-reason => "Important"};
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out,"Subdoulation of quantifoobar...\n".
         "      Eouing our zyxxpth........ [CRIT]\n".
         "        Important\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
   "Max Depth = 1 and CRIT severity");

# Depth filtering at outermost plus any WARN or worse
Term::Emit::setopts(-maxdepth => 1, -showseverity => $Term::Emit::SEVLEV{'WARN'});
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit {-reason => "Important"};
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out,"Subdoulation of quantifoobar...\n".
         "      Eouing our zyxxpth........ [CRIT]\n".
         "        Important\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
   "Max Depth = 1 and all WARN or worse severities");


# Depth filtering at two plus a severe message
Term::Emit::setopts(-maxdepth => 2, -showseverity => $Term::Emit::SEVLEV{'CRIT'});
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit {-reason => "Important"};
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out,"Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "      Eouing our zyxxpth........ [CRIT]\n".
         "        Important\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
   "Max Depth = 2 and CRIT severity");


