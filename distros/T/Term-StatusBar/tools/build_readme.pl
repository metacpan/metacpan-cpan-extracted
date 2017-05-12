#!/usr/bin/perl

  chomp (my $pod2text = `which pod2text`);
  my $path = '../lib/Term/StatusBar.pm';
  my $opath = '../README';

  `$pod2text $path $opath`;
