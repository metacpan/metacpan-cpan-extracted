#!/usr/bin/perl -w

use Proc::Simple;
use Test::More;

plan tests => 2;

sub test_output {
    print "hello stdout\n";
    print STDERR "hello stderr\n";
}

my $p = Proc::Simple->new();
$p->redirect_output ("stdout.txt", "stderr.txt");
$p->start(\&test_output);
while($p->poll()) {
}    

open FILE, "<stdout.txt" or die "Cannot open stdout.txt";
my $stdout = join '', <FILE>;
close FILE;

open FILE, "<stderr.txt" or die "Cannot open stderr.txt";
my $stderr = join '', <FILE>;
close FILE;

is $stderr, "hello stderr\n", "hello stderr";
is $stdout, "hello stdout\n", "hello stdout";

unlink("stdout.txt", "stderr.txt");
