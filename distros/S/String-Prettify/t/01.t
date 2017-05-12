use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use constant DEBUG => 1;
use String::Prettify;

print STDERR " - $0 started\n" if DEBUG;

ok(1);

my @strings = ( qw(ino dev udev gmail celar 238957&$*^$582606*##&$HomeEquity12444Line)


);

for my $string (@strings){
   
   my $clean = prettify($string);
  # print STDERR "\n\n# '$string'\n";

   ok($clean,"from, to..\n$string\n$clean\n");

   
}

print STDERR "\n\nAND\n\n";


my %and = (
   'John and Laura' => 'John And Laura',
   'John & Laura' => 'John And Laura',
   'John&Laura' => 'John And Laura',
   'John &Laura' => 'John And Laura',
   'John &' => 'John And',
   '234&23 Home Prices' => '234 23 Home Prices',
   'H&R Sipps' => 'HR Sipps',
);

while( my($ugly, $pretty) = each %and){
  my $got = prettify($ugly); 

  ok($got eq $pretty) or
     print STDERR "ugly:$ugly\npretty should be:$pretty\npretty got:$got\n\n";

}
