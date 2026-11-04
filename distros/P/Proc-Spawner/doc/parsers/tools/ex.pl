# ex.pl SRCRE REASONRE N: show N samples (spread over lengths) of rejected one-liners/regions
use JSON::PP; my ($sre, $rre, $n) = @ARGV; $n ||= 6; my @t;
open my $h, '<', 'results.jsonl'; while (<$h>) { my $x = decode_json($_);
  push @t, $x->{text} if $x->{v} eq 'rej' && $x->{src} =~ /$sre/ && $x->{why} =~ /$rre/ }
@t = sort { length $a <=> length $b } @t; binmode STDOUT, ':utf8';
print "-- $rre [$sre]: ", scalar @t, "\n";
for my $i (0 .. $n - 1) { last if $i > $#t; my $s = $t[int($i * @t / $n)]; $s =~ s/\n/\\n/g; print "   ", substr($s, 0, 110), "\n" }
