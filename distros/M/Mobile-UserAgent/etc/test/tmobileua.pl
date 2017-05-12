#!/usr/bin/perl -w
# $Id: tmobileua.pl,v 1.1 2005/10/14 14:27:19 cmanley Exp $
use strict;
use FindBin;
use lib ("$FindBin::Bin/../../lib");
use Mobile::UserAgent;


my @standard;
my @imode;
my @mozilla;
my @rubbish;
my @bad;
my @good_useragents;

my @lines;
if (1){
 my $h;
 my $filename = "$FindBin::Bin/../useragents.txt";
 open($h, "<$filename") || die("Failed to open test useragents file '$filename'.\n");
 @lines = <$h>;
 close($h);
}



foreach my $useragent (@lines) {
  chomp($useragent);
  my $ua = new Mobile::UserAgent($useragent);
  #if ($ua->success()) {
  #  print 'Vendor:    ' . $ua->vendor() . "\n";
  #  print 'Model:     ' . $ua->model() . "\n";
  #  print 'Version:   ' . $ua->version() . "\n";
  #  print 'Series60:  ' . $ua->isSeries60() . "\n";
  #  print 'Imode?:    ' . $ua->isImode() . "\n";
  #  print 'Mozilla?:  ' . $ua->isMozilla() . "\n";
  #  print 'Standard?: ' . $ua->isStandard() . "\n";
  #  print 'Rubbish?:  ' . $ua->isRubbish() . "\n";
  #}
  #else {
  #  print "Unsupported: $useragent\n";
  #}
  #print "\n";
  if ($ua->success()) {
    if ($ua->isStandard()) {
      push(@standard, $ua->vendor() . "\t" . $ua->model() . "\t" . ifnull($ua->version(),'') . "\t" . ifnull($ua->isSeries60(),'') . "\t" . ifnull($ua->screenDims(),'') . "\t" . ifnull($ua->imodeCache(),'') . "\tstandard" . "\t$useragent");
    }
    elsif ($ua->isImode()) {
      push(@imode,    $ua->vendor() . "\t" . $ua->model() . "\t" . ifnull($ua->version(),'') . "\t" . ifnull($ua->isSeries60(),'') . "\t" . ifnull($ua->screenDims(),'') . "\t" . ifnull($ua->imodeCache(),'') . "\timode" . "\t$useragent");
    }
    elsif ($ua->isMozilla()) {
      push(@mozilla,  $ua->vendor() . "\t" . $ua->model() . "\t" . ifnull($ua->version(),'') . "\t" . ifnull($ua->isSeries60(),'') . "\t" . ifnull($ua->screenDims(),'') . "\t" . ifnull($ua->imodeCache(),'') . "\tmozilla" . "\t$useragent");
    }
    elsif ($ua->isRubbish()) {
      push(@rubbish,  $ua->vendor() . "\t" . $ua->model() . "\t" . ifnull($ua->version(),'') . "\t" . ifnull($ua->isSeries60(),'') . "\t" . ifnull($ua->screenDims(),'') . "\t" . ifnull($ua->imodeCache(),'') . "\trubbishup" . "\t$useragent");
    }
    else {
      die("Oops!\n");
    }
    push(@good_useragents, $useragent);
  }
  else {
    push(@bad, $useragent);
  }
}

file_put_contents('good_standard.txt', join("\n",@standard));
file_put_contents('good_imode.txt', join("\n",@imode));
file_put_contents('good_mozilla.txt', join("\n",@mozilla));
file_put_contents('good_rubbish.txt', join("\n",@rubbish));
file_put_contents('good.txt', join("\n", @standard, @imode, @mozilla, @rubbish));
file_put_contents('bad.txt', join("\n",@bad));
file_put_contents('good_useragents.txt', join("\n", @good_useragents));



# Silly PHP like functions:
sub array_unique {
  my $aref = shift;
  my %hash;
  foreach my $e (@{$aref}) {
    $hash{$e} = 1;
  }
  return sort keys %hash;
}


sub file_put_contents {
  my $file = shift;
  my $data = shift;
  my $h;
  open($h, ">$file") || die $!;
  binmode($h);
  print $h $data;
  close($h);
  return 1;
}


# MySQL function:
sub ifnull {
  my $p1 = shift;
  my $p2 = shift;
  return defined($p1) ? $p1 : $p2;
}
