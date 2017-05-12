#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 8;

SKIP: {
  skip("PangoScript is new in 1.4", 8)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  is(Pango::Script -> for_unichar("a"), "latin");

  my $lang = Pango::Script -> get_sample_language("latin");
  isa_ok($lang, "Pango::Language");
  is($lang -> includes_script("latin"), 1);

  my $iter = Pango::ScriptIter -> new("urgs");
  isa_ok($iter, "Pango::ScriptIter");

  my ($start, $end, $script) = $iter -> get_range();
  is($start, "urgs");
  is($end, "");
  is($script, "latin");

  ok(!$iter -> next());
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
