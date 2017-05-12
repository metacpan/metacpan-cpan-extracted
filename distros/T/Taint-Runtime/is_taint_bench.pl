#!/usr/bin/perl -w

use strict;
use Benchmark qw(timethese cmpthese countit timestr);
use Taint::Runtime qw($TAINT taint);
$TAINT = 1;

sub is1 { return if ! defined $_[0]; ! eval { eval '#'.substr($_[0], 0, 0); 1 } }
sub is2 { local $^W = 0; local $@; eval { kill 0 * $_[0] }; $@ =~ /^Insecure/ }
sub is3 { local $^W = 0; ! eval { my $t = 0 * $_[0]; eval("1 + $t") } }

my $var_bad = taint("foo");
my $var_ok  = "bar";
my $var_und = undef;


print is1($var_bad) ? "Correct\n" : "Wrong\n";
print is2($var_bad) ? "Correct\n" : "Wrong\n";
print is3($var_bad) ? "Correct\n" : "Wrong\n";

print is1($var_ok)  ? "Wrong\n" : "Correct\n";
print is2($var_ok)  ? "Wrong\n" : "Correct\n";
print is3($var_ok)  ? "Wrong\n" : "Correct\n";

print is1($var_und) ? "Wrong\n" : "Correct\n";
print is2($var_und) ? "Wrong\n" : "Correct\n";
print is3($var_und) ? "Wrong\n" : "Correct\n";

foreach my $var ($var_ok, $var_bad, $var_und) {
  print "Run: ".(! $var ? "Undefined" : $var eq 'foo' ? 'Tainted' : 'Untainted')."\n";
  cmpthese (-2,{
    is1 => sub { is1($var) },
    is2 => sub { is2($var) },
    is3 => sub { is3($var) },
  },'auto');
}

__END__

### Perl 5.8.5 Mandrake 10.1 1.4 Mobile
# Run: Untainted
# Benchmark: running is1, is2, is3 for at least 2 CPU seconds...
#   is1:  3 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 40906.86/s (n=83450)
#   is2:  1 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 147537.74/s (n=312780)
#   is3:  2 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 29252.38/s (n=61430)
#         Rate  is3  is1  is2
# is3  29252/s   -- -28% -80%
# is1  40907/s  40%   -- -72%
# is2 147538/s 404% 261%   --
# Run: Tainted
# Benchmark: running is1, is2, is3 for at least 2 CPU seconds...
#   is1:  2 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 67086.85/s (n=142895)
#   is2:  2 wallclock secs ( 2.02 usr +  0.00 sys =  2.02 CPU) @ 52951.49/s (n=106962)
#   is3:  3 wallclock secs ( 2.07 usr +  0.00 sys =  2.07 CPU) @ 48884.06/s (n=101190)
#        Rate  is3  is2  is1
# is3 48884/s   --  -8% -27%
# is2 52951/s   8%   -- -21%
# is1 67087/s  37%  27%   --
# Run: Undefined
# Benchmark: running is1, is2, is3 for at least 2 CPU seconds...
#   is1:  1 wallclock secs ( 2.02 usr +  0.00 sys =  2.02 CPU) @ 40643.56/s (n=82100)
#   is2:  2 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 111499.07/s (n=240838)
#   is3:  2 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 26348.04/s (n=53750)
#         Rate  is3  is1  is2
# is3  26348/s   -- -35% -76%
# is1  40644/s  54%   -- -64%
# is2 111499/s 323% 174%   -
