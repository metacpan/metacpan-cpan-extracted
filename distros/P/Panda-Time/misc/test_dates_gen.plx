#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use POSIX qw/ceil/;
use Data::Dumper qw/Dumper/;
use Panda::Time qw/systimelocal timelocal tzset/;

unlink glob 't/data/*.txt';

my $genlist_file = 't/data/genlist';
open my $genlist_fh, '<', $genlist_file or die "Cannot open $genlist_file: $!";

while (my $line = <$genlist_fh>) {
    chomp($line);
    $line =~ s/#.+//;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my ($filename, $from_str, $till_str, $step, @zones) = split /\s*,\s*/, $line;
    next unless $filename and $from_str and $till_str and $step;
    @zones = grep {$_} @zones;
    die "no zones in '$line'" unless @zones;

    my %data;
    my $cnt;
    
    say "Generating $line";
    foreach my $tz (@zones) {
        $ENV{TZ} = $tz;
        POSIX::tzset();
        tzset();
        
        my $from = get_epoch($from_str);
        my $till = get_epoch($till_str);
        die "BAD from or till" if $from == -1 or $till == -1;
        my $list = $data{$tz} = [];
        
        if ($step > 0) {
            $cnt = ceil(($till - $from) / $step);
            for (my $time = $from; $time <= $till; $time += $step) {
                my @date = localtime($time);
                $date[5] += 1900;
                push @$list, ["$time", \@date];
            }
        } else {
            $cnt = -$step;
            my $range = $till - $from;
            for (my $i = 0; $i < $cnt; $i++) {
                my $time = int rand($range);
                my @date = localtime($time);
                $date[5] += 1900;
                push @$list, ["$time", \@date];
            }
        }
    }
    
    my $file = 't/data/'.$filename.'.txt';
    open my $fh, '>', $file or die "Cannot open $file: $!";
    print $fh "$from_str, $till_str, $step, @zones, $cnt items per zone\n";
    $Data::Dumper::Indent = 0;
    print $fh Dumper(\%data);
    close $fh;
}

close $genlist_fh;

sub get_epoch {
    my $str = shift;
    die "cannot parse date '$str'" unless $str =~ m#^"?(-?\d+)[/-](-?\d+)[/-](-?\d+) (-?\d+):(-?\d+):(-?\d+)"?$#;
    my ($Y, $M, $D, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
    return timelocal($s, $m, $h, $D, $M-1, $Y);
}

1;