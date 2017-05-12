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

print {*STDOUT} "--- one for Average Joe...\n",
  $tp->process($template, {customer => 'Average Joe'}), "\n\n";

print "Now a series for some Customers...\n";
my $compiled = $tp->compile($template);
for my $customer (qw( tizio caio sempronio )) {
   print {*STDOUT} "---------------------------------\n",
     $tp->evaluate($compiled, {customer => $customer}), "\n\n";
}
