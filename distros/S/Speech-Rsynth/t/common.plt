# -*- Mode: Perl -*-
# File: t/common.plt
# Description: re-usable test subs
use Test;
$| = 1;

sub safestr {
  return defined($_[0]) ? "'$_[0]'" : 'undef';
}


# isok($label,@_) -- prints helpful label
sub isok {
  my $label = shift;
  print "$label:\n";
  if ($#_ == 0) { return ok($_[0]); }
  elsif ($#_ == 1) { return ok($_[0],$_[1]); }
  else { return ok(@_); }
}

# ulistok($label,\@got,\@expect)
# --> ok() for unsorted lists (no ',' allowed in elements!)
sub ulistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',sort(@$l1)),join(',',sort(@$l2)));
}

# slistok($label,\@got,\@expect)
# --> ok() for sorted lists (no ',' allowed in elements!)
sub slistok {
  my ($label,$l1,$l2) = @_;
  isok($label,join(',',@$l1),join(',',@$l2));
}

# hashok($label,\%got,\%expect)
# --> ok() for hashrefs (no ',' or '=>' allowed in elements!)
sub hashok {
  my ($label,$h1,$h2) = @_;
  isok($label,
       join(',',
	    (map { "$_=>$h1->{$_}" } keys(%$h1)),
	    (map { "$_=>$h2->{$_}" } keys(%$h2))));
}

# fileok($label,$template_filename,$test_filename)
# --> ok() for file contents
sub fileok {
  my ($label,$f1,$f2) = @_;
  unless (open(F1,"<$f1")) {
    print "open failed for file `$f1': $!";
    return isok(0);
  }
  unless (open(F2,"<$f2")) {
    print ("open failed for file `$f2': $!");
    close(F1);
    return ok(0);
  }
  my @f1data = <F1>;
  my @f2data = <F2>;
  close(F1);
  close(F2);

  print "$label:\n";
  if (join('',@f1data) eq join('',@f2data)) {
    print "ok\n";
  } else {
    print "NOT ok -- files '$f1' and '$f2' differ.\n"
  }
}


print "common.plt loaded.\n";

1;

