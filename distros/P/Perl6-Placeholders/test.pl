BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Perl6::Placeholders;
$loaded = 1;
print "ok 1\n";

my $print = { print "$^ok $^val\n" };

$print->("ok",2);

$print->('ok',$_) foreach grep { $^x > 2 }
		    map { $^n-10 }
		      sort { $^i <=> $^j } reverse 11..20;

my $dbl = { $^x + $^x };
print "ok 11\n" if $dbl->(21) == 42;
