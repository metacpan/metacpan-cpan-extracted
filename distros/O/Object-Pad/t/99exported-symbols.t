#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

$^O eq "linux" or
   plan skip_all => "This test only works on Linux (or at least, ELF platforms)";

my $sofile = "blib/arch/auto/Object/Pad/Pad.so";

# Since we load with RTLD_GLOBAL it's important that we don't pollute the
# symbol namespace. Therefore, aside from the `boot_Object__Pad` function, the
# only other defined symbols should all have names beginning `ObjectPad_...`

my @unexpected_symbols;
{
   open my $fh, "-|", "nm", "-D", $sofile or
      plan skip_all => "Cannot pipeopen nm -D - $!";

   while( <$fh> ) {
      chomp;
      next unless m/^[0-9a-f]+ . (.*)$/;
      my $symb = $1;

      next if $symb =~ m/^boot_Object__Pad/;
      next if $symb =~ m/^ObjectPad_/;

      push @unexpected_symbols, $symb;
   }
}

ok( !@unexpected_symbols, "No unexpected symbols found in $sofile" ) or
   diag( "Symbols found:\n  " . join( "\n  ", @unexpected_symbols ) );

done_testing;
