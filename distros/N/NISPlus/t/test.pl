$inc = "-I".join(" -I", @INC);

sub run
{
  open(PERL, "$^X $inc $_[0]|") ||
    do { print "could not run PERL command '$_[0]': $!\n"; return 0; };
  @perl = <PERL>;
  close(PERL);
  open(NIS, "$_[1]|") ||
    do { print "could not run NIS command '$_[1]': $!\n"; return 0; };
  @nis = <NIS>;
  close(NIS);
  foreach $pos ($[..$#perl)
  {
    next if $perl[$pos] eq $nis[$pos];
    print "output differs on line $pos: \n";
    print "perl: $perl[$pos]\n";
    print "nis: $nis[$pos]\n";
    return 0;
  }
  return 1;
}

sub run2
{
  open(A, "$_[0]|") ||
    do { print "could not run A command '$_[0]': $!\n"; return 0; };
  @a = <A>;
  close(A);
  open(B, "$_[1]|") ||
    do { print "could not run B command '$_[1]': $!\n"; return 0; };
  @b = <B>;
  close(B);
  foreach $pos ($[..$#a)
  {
    next if $a[$pos] eq $b[$pos];
    print "output differs on line $pos: \n";
    print "a: $a[$pos]\n";
    print "b: $b[$pos]\n";
    return 0;
  }
  return 1;
}

1;
