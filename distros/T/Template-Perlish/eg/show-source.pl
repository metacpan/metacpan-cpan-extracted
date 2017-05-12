#!/usr/bin/perl 
use strict;
use warnings;
use lib qw( ../lib );
use Template::Perlish;

my $tp = Template::Perlish->new(
   variables => {
      director => 'PolettiX',
      locations =>
        [[city => qw( cars smog )], [country => qw( cow orkers )],]
   },
);

my $template = do { open my $fh, '<', 'example.tmpl'; local $/; <$fh> };
print {*STDOUT} $tp->compile($template);
