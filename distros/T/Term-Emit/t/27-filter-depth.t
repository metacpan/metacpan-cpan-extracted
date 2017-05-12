#!perl -w
use strict;
use warnings;
use Test::More tests => 9;

my $out;
use Term::Emit qw/:all/, {-fh      => \$out,
                          -step    => 2,
                          -width   => 40};


$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
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
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Unfiltered");

Term::Emit::setopts(-maxdepth => 0);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "", "All filtered - nothing shown");

Term::Emit::setopts(-maxdepth => 1);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out,"Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 1");

Term::Emit::setopts(-maxdepth => 2);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 2");

Term::Emit::setopts(-maxdepth => 3);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 3");

Term::Emit::setopts(-maxdepth => 4);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
            }
          emit_ok;
        }
      emit_warn;
    }
}
is($out, "Subdoulation of quantifoobar...\n".
         "  Morgozider...\n".
         "    Frimrodding the quark...\n".
         "      Eouing our zyxxpth........ [CRIT]\n".
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 4");

Term::Emit::setopts(-maxdepth => 5);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
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
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 5");

Term::Emit::setopts(-maxdepth => 99);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
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
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth = 99");

Term::Emit::setopts(-maxdepth => undef);
$out = q{};
{ emit "Subdoulation of quantifoobar";
    { emit "Morgozider";
        { emit "Frimrodding the quark";
            { emit "Eouing our zyxxpth";
                { emit "Shiniffing";
                }
              emit_crit;
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
         "    Frimrodding the quark....... [OK]\n".
         "  Morgozider.................... [WARN]\n".
         "Subdoulation of quantifoobar.... [DONE]\n",
            "Max Depth back to Unfiltered");

