#!/usr/bin/perl

  use strict;
  use Test;

  BEGIN{
      plan tests => 1;
  }

  use Sub::Caller;
  ok(1);
  exit;

1;
__END__

