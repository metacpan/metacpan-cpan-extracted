#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

$^O eq "linux" or
   plan skip_all => "This test only works on Linux (or at least, ELF platforms)";

require Object::Pad;

my $idx;
foreach( @DynaLoader::dl_modules ) {
   last if $_ eq "Object::Pad";
   $idx++;
}
my $sofile = $DynaLoader::dl_shared_objects[$idx];

# Since we load with RTLD_GLOBAL it's important that we don't pollute the
# symbol namespace. Therefore, aside from the `boot_Object__Pad` function, the
# only other defined symbols should all have names beginning `ObjectPad_...`

# Some symbol names to ignore
my %IGNORE = map { $_ => 1 } qw( _init _fini __bss_start _edata _end );

my @unexpected_symbols;
my @objectpad_symbols;
{
   open my $fh, "-|", "nm", "-D", $sofile or
      plan skip_all => "Cannot pipeopen nm -D - $!";

   while( <$fh> ) {
      chomp;
      next unless m/^[0-9a-f]+ . (.*)$/;
      my $symb = $1;

      next if $symb =~ m/^boot_Object__Pad/;

      if( $symb =~ m/^ObjectPad_(.*)$/ ) {
         my $shortname = $1;
         next if $shortname =~ m/^_/;
         push @objectpad_symbols, $shortname;
         next;
      }

      next if $IGNORE{$symb};

      push @unexpected_symbols, $symb;
   }
}

ok( !@unexpected_symbols, "No unexpected symbols found in $sofile" ) or
   diag( "Symbols found:\n  " . join( "\n  ", @unexpected_symbols ) );

# Now compare to the #define'd macros in object_pad.h
my %macros;
{
   open my $fh, "include/object_pad.h" or
      die "Cannot read include/object_pad.h - $!";

   while( <$fh> ) {
      chomp;
      next unless m/^#define (.*?)\(/;

      $macros{$1}++;
   }
}

foreach my $symbol ( sort @objectpad_symbols ) {
   ok( $macros{$symbol}, "Symbol ObjectPad_$symbol has a macro" );
}

done_testing;
