# -*- mode: cperl -*-

my $REPO = $ENV{PERL_REPOSITORY_APC_REPO};

my $Id = q$Id: apc.t 293 2008-02-22 08:33:10Z k $;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $tests;

BEGIN { $tests = 20; $| = 1; print "1..$tests\n"; }
END {print "not ok 1\n" unless $loaded;}
use Perl::Repository::APC;
$loaded = 1;
print "ok 1 # greets\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

eval { Perl::Repository::APC->new };
if ($@) {
  print "ok 2 # no repo, no object\n";
} else {
  print "not ok 2\n";
}

if (defined $REPO and -d $REPO) {
  my $i = 3;
  my $apc = Perl::Repository::APC->new($REPO);
  print "ok $i # ->new('$REPO')\n";
  $i++;

  my $pver;
  $pver = $apc->get_to_version("perl",7100);
  print "not " unless $pver eq "5.7.1";
  print "ok $i # 7100 to 5.7.1\n";
  $i++;
  $pver = $apc->get_from_version("perl",7100);
  print "not " unless $pver eq "5.7.0";
  print "ok $i # 7100 from 5.7.0\n";
  $i++;
  $pver = $apc->get_from_version("maint-5.005",1656);
  print "not " unless $pver eq "5.005_00";
  print "ok $i @ 1656 from 5.005_00\n";
  $i++;
  $pver = $apc->get_from_version("maint-5.6",12823);
  print "not " unless $pver eq "5.6.1";
  print "ok $i # 12823/maint-5.6 from 5.6.1\n";
  $i++;
  $pver = $apc->get_from_version("perl",12823);
  print "not " unless $pver eq "5.7.2";
  print "ok $i # 12823/perl from 5.7.2\n";
  $i++;
  eval {$pver = $apc->get_from_version("perl",12822);}; # does not exist
  print "not " unless $@;
  print "ok $i # 12822 not exists exception\n";
  $i++;

  my $range;
  $range = $apc->version_range("perl",17600,17700);
  print "not " unless @$range == 2;
  print "ok $i # [@$range]\n";
  $i++;
  $range = $apc->patch_range("perl",17600,17700);
  print "not " unless @$range == 73;
  print "ok $i # [@$range]\n";
  $i++;

  my $closest;
  $closest = $apc->closest("perl",">",12821);
  print "not " unless $closest == 12823;
  print "ok $i # $closest\n";
  $i++;
  $closest = $apc->closest("perl","<",12821);
  print "not " unless $closest == 12818;
  print "ok $i # $closest\n";
  $i++;
  $closest = $apc->closest("perl",">",0);
  print "not " unless $closest == 1;
  print "ok $i # $closest\n";
  $i++;

  eval {$closest = $apc->closest("perl",">",999999990);};
  print "not " unless $@;
  print "ok $i # >999999990 exception\n";
  $i++;
  eval {$closest = $apc->closest("perl","<",0);};
  print "not " unless $@;
  print "ok $i # <0 exception\n";
  $i++;

  my $next;
  $next = $apc->first_in_branch("maint-5.004");
  print "not " unless $next eq "5.004_00";
  print "ok $i # $next\n";
  $i++;
  $next = $apc->first_in_branch("perl");
  print "not " unless $next eq "5.004_50";
  print "ok $i # $next\n";
  $i++;
  $next = $apc->next_in_branch("5.6.0");
  print "not " unless $next eq "5.7.0";
  print "ok $i # $next\n";
  $i++;

  $range = $apc->patches("5.7.1");
  my $res = @$range;
  print "not " unless $res == 1820;
  print "ok $i # $res\n";
  $i++;

  my @perl;
  for (my $next = $apc->first_in_branch("perl");
       $next;
       $next = $apc->next_in_branch($next)
      ) {
    push @perl, $next;
  }
  # warn "perl[@perl]";

} else {

  warn "\n\n\a  Skipping tests! If you want to run the tests against your copy
  of APC, please set environment variable \$PERL_REPOSITORY_APC_REPO to
  the path to your APC\n\n";

  for (3..$tests) {
    print "ok $_ # skip\n";
  }
}
