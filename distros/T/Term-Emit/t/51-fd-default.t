#!perl -w
use strict;
use warnings;
use Test::More tests => 2;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                    -fh      => \$out,
                    -width   => 35};

# This script tests if you emit to a FD that's the same as
#  the base object 0's FD, that you end up using the base
#  object 0.

{ emit "Level 0";
  { emit \$out, "Level 1";
    { emit "Level 2";
      { emit \$out, "Level 3";
        { emit "Level 4";
        }
      }
    }
  }
}
is($out, "Level 0...\n".
         "  Level 1...\n".
         "    Level 2...\n".
         "      Level 3...\n".
         "        Level 4............ [DONE]\n".
         "      Level 3.............. [DONE]\n".
         "    Level 2................ [DONE]\n".
         "  Level 1.................. [DONE]\n".
         "Level 0.................... [DONE]\n",  "String outputs consolidate to base 0");

$out = q{};
{ emit "Level 0";
  emit_text "Explanation 0";
  { emit \$out, "Level 1";
    emit_text \$out, "Explanation 1";
    { emit "Level 2";
      emit_text "Explanation 2";
      { emit \$out, "Level 3";
        emit_text \$out, "Explanation 3";
        { emit "Level 4";
          emit_text "Explanation 4";
        }
      }
    }
  }
}
is($out, "Level 0...\n".
         "    Explanation 0\n".
         "  Level 1...\n".
         "      Explanation 1\n".
         "    Level 2...\n".
         "        Explanation 2\n".
         "      Level 3...\n".
         "          Explanation 3\n".
         "        Level 4...\n".
         "            Explanation 4\n".
         "        Level 4............ [DONE]\n".
         "      Level 3.............. [DONE]\n".
         "    Level 2................ [DONE]\n".
         "  Level 1.................. [DONE]\n".
         "Level 0.................... [DONE]\n",  "Additional text consolidates to base 0");

