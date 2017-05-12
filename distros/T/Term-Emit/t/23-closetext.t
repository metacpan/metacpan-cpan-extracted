#!perl -w
use strict;
use warnings;
use Test::More tests => 5;

my $out;
use Term::Emit qw/:all/, {-bullets => 0,
                          -fh      => \$out,
                          -width   => 40};

$out = q{};
{ emit ["Begin task", "Task complete"];
  emit_ok;
}
is($out, "Begin task...\n".
         "Task complete................... [OK]\n",
            "One level [otext,ctext]");

$out = q{};
{ emit ["Hugolate", "Hugolate"];
  emit_ok;
}
is($out, "Hugolate........................ [OK]\n",
            "One level [otext,ctext] the same");

$out = q{};
{ emit {-closetext => "Should not see this"}, ["Starting yerk", "Yerk complete"];
  emit_ok;
}
is($out, "Starting yerk...\n".
         "Yerk complete................... [OK]\n",
            "One level [otext,ctext], but -closetext too");

$out = q{};
{ emit {-closetext => "Should not see this"}, ["Hugolate", "Hugolate"];
  emit_ok;
}
is($out, "Hugolate........................ [OK]\n",
            "One level [otext,ctext] the same, but -closetext too");

$out = q{};
{ emit {-closetext => "All done!"}, "Begin task";
  emit_ok;
}
is($out, "Begin task...\n".
         "All done!....................... [OK]\n",
            "One level [otext,ctext]");

