use strict;
use warnings;
use utf8;
use File::Find::Rule;
use Time::Piece;
use Time::HiRes qw(gettimeofday tv_interval);
use LWP::UserAgent;
use HTTP::Date;

system('cd ~/dev/roast/ && git reset HEAD --hard');

my @files = sort File::Find::Rule->file()
                              ->name( '*.t' )
                              ->in( glob('~/dev/roast/') );

my $ok;
my $fail;

my $t0 = [gettimeofday];
for (@files) {
    if (system("./pvip $_")==0) {
        print "PASSED: $_\n";
        $ok++;
    } else {
        print "FAIL: $_\n";
        $fail++;
    }
}
my $elapsed = tv_interval($t0);

my $percentage = 100.0*((1.0*$ok)/(1.0*($ok+$fail)));
printf "%s - OK: %s, FAIL: %s ( %.2f%%) in %s sec\n", localtime->strftime('%Y-%m-%d %H:%M'), $ok, $fail, $percentage, $elapsed;

my $datetime = time2str(time);

my $hf_base = "http://hf.64p.org/api/perl6/pvip";

my $ua = LWP::UserAgent->new();
my $res = $ua->post("$hf_base/ok", [number => $ok, datetime => $datetime]);
warn $res->as_string unless $res->is_success;
$ua->post("$hf_base/fail", [number => $fail, datetime => $datetime]);
# $ua->post("$hf_base/percentage", [number => $percentage, datetime => $datetime]);
$ua->post("$hf_base/elapsed", [number => int($elapsed*1000), datetime => $datetime]);
$ua->post("$hf_base/total", [number => $ok+$fail, datetime => $datetime]);
