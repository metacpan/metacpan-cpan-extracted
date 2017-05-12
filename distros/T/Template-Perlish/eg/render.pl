#!/usr/bin/perl 
use strict;
use warnings;
use lib qw( ../lib );
use Template::Perlish qw( render );

my %variables = (
   director => 'PolettiX',
   locations =>
      [[city => qw( cars smog )], [country => qw( cow orkers )],]
);

my $template = do { open my $fh, '<', 'example.tmpl'; local $/; <$fh> };

print {*STDOUT} "--- one for Average Joe...\n",
  render($template, %variables, customer => 'Average Joe'), "\n\n";
