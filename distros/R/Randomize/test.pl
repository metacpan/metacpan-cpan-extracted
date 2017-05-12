# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..50\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Dumper;
use Randomize;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $slop = .30; 
my @slop_failures;

# Try something simple first

my $r1 = Randomize->new([{Field => 'Alpha',
                          Values => ['aaa'..'aaj']},
                         {Field => 'Numeric',
                          Values => [1..10]}]);
print 'not ' unless defined $r1;
print "ok 2\n";


if (defined $r1) {
  my (%alphas, %numerics);
  for (1..1000) {
    my $thing = $r1->generate();
    $alphas{$thing->{Alpha}}++;
    $numerics{$thing->{Numeric}}++;
  }
  my @alphakeys = keys %alphas;
  my @numerickeys = keys %numerics;

  print 'not ' unless @alphakeys == 10 && @numerickeys == 10;
  print "ok 3\n";

  my $notok;
  my $low  = 100 * (1 - $slop);
  my $high = 100 * (1 + $slop);
  foreach my $key (@alphakeys) {
    if ($alphas{$key} < $low || 
        $alphas{$key} > $high) {
      print "not ok 4  ",
            "$key appears $alphas{$key} times.  ",
            "Expected something between $low and $high.\n";
      $notok = 1;
      push @slop_failures, 4;
      last;
    }
  }
  foreach my $key (@numerickeys) {
    if ($numerics{$key} < $low || 
        $numerics{$key} > $high) {
      print "not ok 4  ",
            "$key appears $numerics{$key} times.  ",
            "Expected something between $low and $high.\n";
      $notok = 1;
      push @slop_failures, 4;
      last;
    }
  }
  print "ok 4\n" unless $notok;
}
else {
  print "skipped 3\n";
  print "skipped 4\n";
}


# Now some weighted stuff

my %weights;
@weights{'bba'..'bbj'} = (1) x 10;
@weights{'bbk','bbl'} = (10,10);
$weights{bbm} = 20;
my $r = Randomize->new([{Field => 'Weighted_Alpha',
                          Values => [{Data => ['bba'..'bbj'],
                                      Weight => 1},
                                     {Data => ['bbk','bbl'],
                                      Weight => 10},
                                     {Data => ['bbm'],
                                      Weight => 20}]}]);
print 'not ' unless defined $r;
print "ok 5\n";


if (defined $r) {
  my %alphas;
  for (1..5000) {
    my $thing = $r->generate();
    $alphas{$thing->{Weighted_Alpha}}++;
  }
  my @alphakeys = keys %alphas;

  print 'not ' unless @alphakeys == 13;
  print "ok 6\n";

  my $notok;
  foreach my $key (@alphakeys) {
    my $low  = $weights{$key} * 100 * (1 - $slop);
    my $high = $weights{$key} * 100 * (1 + $slop);
    if ($alphas{$key} < $low || 
        $alphas{$key} > $high) {
      print "not ok 7  ",
            "$key appears $alphas{$key} times.  ",
            "Expected something between $low and $high.\n";
      $notok = 1;
      push @slop_failures, 7;
      last;
    }
  }
  print "ok 7\n" unless $notok;
}
else {
  print "skipped 6\n";
  print "skipped 7\n";
}


# Add in some preconditions

%weights = ();
@weights{'Aa'..'Aj'} = (1) x 10;
@weights{'Ak','Al'} = (10,10);
@weights{'Ba','Bb'} = (15) x 2;
$weights{CD} = 60;
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}]}]);
print 'not ' unless defined $r;
print "ok 8\n";

if (defined $r) {
  my %things;
  my $notok_msg;
  for (1..12000) {
    my $thing = $r->generate();
    if ($thing->{ABCD} eq 'A') {
      if ($thing->{Conditional} !~ /^A/) {
        $notok_msg = "ABCD is '$thing->{ABCD}', " .
                     "but Conditional is '$thing->{Conditional}'.";
      }
    }
    elsif ($thing->{ABCD} eq 'B') {
      if ($thing->{Conditional} !~ /^B/) {
        $notok_msg = "ABCD is '$thing->{ABCD}', " .
                     "but Conditional is '$thing->{Conditional}'.";
      }
    }
    else {
      if ($thing->{Conditional} !~ /^[CD]/) {
        $notok_msg = "ABCD is '$thing->{ABCD}', " .
                     "but Conditional is '$thing->{Conditional}'.";
      }
    }
    $things{$thing->{Conditional}}++;
  }
  if ($notok_msg) {
    print "not ok 9 ($notok_msg)\n";
  }
  else {
    print "ok 9\n";

    my @thingkeys = keys %things;

    print 'not ' unless @thingkeys == 15;
    print "ok 10\n";

    my $notok;
    foreach my $key (@thingkeys) {
      my $low  = $weights{$key} * 100 * (1 - $slop);
      my $high = $weights{$key} * 100 * (1 + $slop);
      if ($things{$key} < $low || 
          $things{$key} > $high) {
        print "not ok 11  ",
              "$key appears $things{$key} times.  ",
              "Expected something between $low and $high.\n";
        $notok = 1;
        push @slop_failures, 11;
        last;
      }
    }
    print "ok 11\n" unless $notok;
  }
}
else {
  print "skipped 9\n";
  print "skipped 10\n";
  print "skipped 11\n";
}


# Make sure the objects really are independent of each other

my $hash1 = $r1->generate;
my @hash1_keys = keys %$hash1;
if (exists $hash1->{Alpha} && exists $hash1->{Numeric} && @hash1_keys == 2) {
  print "ok 12\n";
}
else {
  print "not ok 12\n";
}


# Finally, do a little Retry_If stuff.

$main::old_ab = 'B';
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => ['A','B'],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not ' unless defined $r;
print "ok 13\n";
print $Randomize::errmsg;

if (defined $r) {
  my @ab;
  for (1..10) {
    my $thing = $r->generate();
    push @ab, $thing->{AB};
    $main::old_ab = $thing->{AB};
  }
  if ("@ab" eq 'A B A B A B A B A B') {
    print "ok 14\n";
  }
  else {
    print "not ok 14\n";
  }

  my $thing = eval {$r->generate(AB => 'B')};
  if (defined $thing || $@ !~ /violates the Retry_If/) {
    print "not ok 15\n";
  }
  else {
    print "ok 15\n";
  }
}


$r = Randomize->new(
  [{Field    => 'AB',
    Values   => ['A','B'],
    Retry_If => ['<<AB>> eq $main::old_ab']}]);

print 'not ' unless defined $r;
print "ok 16\n";
print $Randomize::errmsg;

if (defined $r) {
  my @ab;
  for (1..10) {
    my $thing = $r->generate();
    push @ab, $thing->{AB};
    $main::old_ab = $thing->{AB};
  }
  if ("@ab" eq 'A B A B A B A B A B') {
    print "ok 17\n";
  }
  else {
    print "not ok 17\n";
  }

  my $thing = eval {$r->generate(AB => 'B')};
  if (defined $thing || $@ !~ /violates the Retry_If/) {
    print "not ok 18\n";
  }
  else {
    print "ok 18\n";
  }
}


$r = Randomize->new(
  [{Field    => 'AB',
    Values   => [{Data => ['A'], Weight => 1},
                 {Data => ['B'], Weight => 2}],
    Retry_If => ['<<AB>> eq $main::old_ab']}]);

print 'not ' unless defined $r;
print "ok 19\n";
print $Randomize::errmsg;

if (defined $r) {
  my @ab;
  for (1..10) {
    my $thing = $r->generate();
    push @ab, $thing->{AB};
    $main::old_ab = $thing->{AB};
  }
  if ("@ab" eq 'A B A B A B A B A B') {
    print "ok 20\n";
  }
  else {
    print "not ok 20\n";
  }

  my $thing = eval {$r->generate(AB => 'B')};
  if (defined $thing || $@ !~ /violates the Retry_If/) {
    print "not ok 21\n";
  }
  else {
    print "ok 21\n";
  }
}


$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Ab'],
                                  Weight => 3},
                                 {Data => ['Ac'],
                                  Weight => 1}],
                Retry_If     => ["<<Conditional>> eq 'Aa'"]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}],
    Retry_If => ["<<ABCD>> eq 'A' && <<Conditional>> eq 'Ab'"]
   }]);

print 'not ' unless defined $r;
print "ok 22\n";
print $Randomize::errmsg;

if (defined $r) {
  my $failed = 0;
  for (1..20) {
    my $thing = $r->generate(ABCD => 'A');
    if ($thing->{Conditional} ne 'Ac') {
      $failed = 1;
      last;
    }
  }
  print 'not ' if $failed;
  print "ok 23\n";

  my $thing = eval {$r->generate(ABCD => 'A', Conditional => 'Aa')};
  if (defined $thing || $@ !~ /violates the Retry_If/) {
    print "not ok 24\n";
  }
  else {
    print "ok 24\n";
  }

  $thing = eval {$r->generate(ABCD => 'A', Conditional => 'Ab')};
  if (defined $thing || $@ !~ /violates the Retry_If/) {
    print "not ok 25\n";
  }
  else {
    print "ok 25\n";
  }
}


# Now, a few error cases to make sure I get the right error messages

# Missing "Field"
$r = Randomize->new(
  [{Values   => [{Data => ['A'], Weight => 1},
                 {Data => ['B'], Weight => 2}],
    Retry_If => ['<<AB>> eq $main::old_ab']}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't contain a field name/;
print "ok 26\n";

# Missing "Values"
$r = Randomize->new(
  [{Field    => 'AB',
    Retry_If => ['<<AB>> eq $main::old_ab']}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't have a Values field/;
print "ok 27\n";

# Missing "Data" in "Values"
$r = Randomize->new(
  [{Field    => 'AB',
    Values   => [{Data => ['A'], Weight => 1},
                 {Weight => 2}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't contain a Data element/;
print "ok 28\n";

# Missing "Weight" in "Values"
$r = Randomize->new(
  [{Field    => 'AB',
    Values   => [{Data => ['A'], Weight => 1},
                 {Data => ['B']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't contain a Weight element/;
print "ok 29\n";

# Bogus "Data" in "Values"
$r = Randomize->new(
  [{Field    => 'AB',
    Values   => [{Data => 'A', Weight => 1},
                 {Data => ['B'], Weight => 2}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /Data element isn't an array ref/;
print "ok 30\n";

# Bogus "Weight" in "Values"
$r = Randomize->new(
  [{Field    => 'AB',
    Values   => [{Data => ['A'], Weight => 'a'},
                 {Data => ['B'], Weight => 2}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /Weight element isn't a positive integer/;
print "ok 31\n";


# No Precondition
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Alternatives => ['A','B'],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /No precondition/;
print "ok 32\n";


# No Alternatives
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /contain a Data element/;
print "ok 33\n";


# No Data in alternative
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A'], Weight => 1},
                                 {Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't contain a Data element/;
print "ok 34\n";


# No Weight in alternative
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A']},
                                 {Data => ['B'], Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /doesn't contain a Weight element/;
print "ok 35\n";


# Bogus Data in alternative
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => 'A', Weight => 1},
                                 {Data => ['B'], Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /isn't an array ref/;
print "ok 36\n";


# Bogus Weight in alternative
$r = Randomize->new(
  [{Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A'], Weight => 1},
                                 {Data => ['B'], Weight => -2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not '
  if defined $r || $Randomize::errmsg !~ /isn't a positive integer/;
print "ok 37\n";


# Gonna test out the debug directive a bit
$r = Randomize->new(
  ['DEBUG ON test.pl.code',
   'DEBUG OFF',
   {Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A'], Weight => 1},
                                 {Data => ['B'], Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not ' unless defined $r && -e 'test.pl.code';
print "ok 38\n";
unlink 'test.pl.code';


$r = Randomize->new(
  ['DEBUG ON',
   'DEBUG OFF',
   {Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A'], Weight => 1},
                                 {Data => ['B'], Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not ' unless defined $r && -e 'Randomize.code';
print "ok 39\n";


$r = Randomize->new(
  ['DEBUG BLABLABLA',
   {Field => 'AB',
    Values => [{Precondition => 'DEFAULT',
                Alternatives => [{Data => ['A'], Weight => 1},
                                 {Data => ['B'], Weight => 2}],
                Retry_If     => ['<<AB>> eq $main::old_ab']}]}]);

print 'not ' if defined $r || $Randomize::errmsg !~ /Syntax error/;
print "ok 40\n";



# Now, test the permutations counter

my $testno;


$testno = 41;
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}]
   }]);
if ($r) {
  my $p = $r->permutations();
  if ($p == 16) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno ($p)\n";
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 42;
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}],
                Retry_If     => ["<<Conditional>> eq 'Al'"]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}]
   }]);
if ($r) {
  my $p = $r->permutations();
  if ($p == 15) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno ($p)\n";
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 43;
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}],
    Retry_If => ["<<ABCD>> eq 'A' && <<Conditional>> eq 'Ak'"]
   }]);
if ($r) {
  my $p = $r->permutations();
  if ($p == 15) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno ($p)\n";
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 44;
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}],
                Retry_If     => ["<<Conditional>> eq 'Al'"]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}],
    Retry_If => ["<<ABCD>> eq 'A' && <<Conditional>> eq 'Ak'"]
   }]);
if ($r) {
  my $p = $r->permutations();
  if ($p == 14) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno ($p)\n";
  }

  $testno = 45;
  # See if it generates the right number of permutations when I specify
  # a value for one of the fields.
  $p = $r->permutations(ABCD => 'B');
  if ($p == 2) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno ($p)\n";
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
  $testno++;
  print "not ok $testno (not run)\n";
}



# This part tests the generate_all method

$testno = 46;
unlink "expected_$testno";
unlink "got_$testno";
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}]
   }]);
if ($r) {
  my @x = $r->generate_all();
  my $expected = <<'EOT';
$VAR1 = [
          {
            'Conditional' => 'Aa',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ab',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ac',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ad',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ae',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Af',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ag',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ah',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ai',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Aj',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ak',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Al',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ba',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'Bb',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'C'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'D'
          }
        ];
EOT
  my $got = Dumper(\@x);
  if ($got eq $expected) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno (look in expected_$testno and got_$testno)\n";
    open EXPECTED, ">expected_$testno" 
      or die "Couldn't open expected_$testno: $!";
    print EXPECTED $expected;
    close EXPECTED;
    open GOT, ">got_$testno" 
      or die "Couldn't open got_$testno: $!";
    print GOT $got;
    close GOT;
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 47;
unlink "expected_$testno";
unlink "got_$testno";
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}],
                Retry_If     => ["<<Conditional>> eq 'Al'"]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}]
   }]);
if ($r) {
  my @x = $r->generate_all();
  my $expected = <<'EOT';
$VAR1 = [
          {
            'Conditional' => 'Aa',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ab',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ac',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ad',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ae',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Af',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ag',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ah',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ai',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Aj',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ak',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ba',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'Bb',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'C'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'D'
          }
        ];
EOT
  my $got = Dumper(\@x);
  if ($got eq $expected) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno (look in expected_$testno and got_$testno)\n";
    open EXPECTED, ">expected_$testno" 
      or die "Couldn't open expected_$testno: $!";
    print EXPECTED $expected;
    close EXPECTED;
    open GOT, ">got_$testno" 
      or die "Couldn't open got_$testno: $!";
    print GOT $got;
    close GOT;
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 48;
unlink "expected_$testno";
unlink "got_$testno";
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}],
    Retry_If => ["<<ABCD>> eq 'A' && <<Conditional>> eq 'Ak'"]
   }]);
if ($r) {
  my @x = $r->generate_all();
  my $expected = <<'EOT';
$VAR1 = [
          {
            'Conditional' => 'Aa',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ab',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ac',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ad',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ae',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Af',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ag',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ah',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ai',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Aj',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Al',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ba',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'Bb',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'C'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'D'
          }
        ];
EOT
  my $got = Dumper(\@x);
  if ($got eq $expected) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno (look in expected_$testno and got_$testno)\n";
    open EXPECTED, ">expected_$testno" 
      or die "Couldn't open expected_$testno: $!";
    print EXPECTED $expected;
    close EXPECTED;
    open GOT, ">got_$testno" 
      or die "Couldn't open got_$testno: $!";
    print GOT $got;
    close GOT;
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
}


$testno = 49;
unlink "expected_$testno";
unlink "got_$testno";
$r = Randomize->new(
  [{Field => 'ABCD',
    Values => ['A'..'D']},
   {Field => 'Conditional',
    Values => [{Precondition => "<<ABCD>> eq 'A'",
                Alternatives => [{Data => ['Aa'..'Aj'],
                                  Weight => 1},
                                 {Data => ['Ak','Al'],
                                  Weight => 10}],
                Retry_If     => ["<<Conditional>> eq 'Al'"]},
               {Precondition => "<<ABCD>> eq 'B'",
                Alternatives => ['Ba','Bb']},
               {Precondition => 'DEFAULT',
                Alternatives => ['CD']}],
    Retry_If => ["<<ABCD>> eq 'A' && <<Conditional>> eq 'Ak'"]
   }]);
if ($r) {
  my @x = $r->generate_all();
  my $expected = <<'EOT';
$VAR1 = [
          {
            'Conditional' => 'Aa',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ab',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ac',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ad',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ae',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Af',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ag',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ah',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ai',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Aj',
            'ABCD' => 'A'
          },
          {
            'Conditional' => 'Ba',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'Bb',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'C'
          },
          {
            'Conditional' => 'CD',
            'ABCD' => 'D'
          }
        ];
EOT
  my $got = Dumper(\@x);
  if ($got eq $expected) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno (look in expected_$testno and got_$testno)\n";
    open EXPECTED, ">expected_$testno" 
      or die "Couldn't open expected_$testno: $!";
    print EXPECTED $expected;
    close EXPECTED;
    open GOT, ">got_$testno" 
      or die "Couldn't open got_$testno: $!";
    print GOT $got;
    close GOT;
  }

  $testno++;
  # See if it generates the right number of permutations when I specify
  # a value for one of the fields.
  @x = $r->generate_all(ABCD => 'B');
  $expected = <<'EOT';
$VAR1 = [
          {
            'Conditional' => 'Ba',
            'ABCD' => 'B'
          },
          {
            'Conditional' => 'Bb',
            'ABCD' => 'B'
          }
        ];
EOT
  $got = Dumper(\@x);
  if ($got eq $expected) {
    print "ok $testno\n";
  }
  else {
    print "not ok $testno (look in expected_$testno and got_$testno)\n";
    open EXPECTED, ">expected_$testno" 
      or die "Couldn't open expected_$testno: $!";
    print EXPECTED $expected;
    close EXPECTED;
    open GOT, ">got_$testno" 
      or die "Couldn't open got_$testno: $!";
    print GOT $got;
    close GOT;
  }
}
else {
  print "not ok $testno ($Randomize::errmsg)\n";
  $testno++;
  print "not ok $testno (not run)\n";
}








if (@slop_failures) {
  my $tcs = 'testcase';
  $tcs .= 's' if @slop_failures > 1;
  my $tc_list;
  my $that_error_goes;
  if (@slop_failures == 1) {
    $tc_list = $slop_failures[0];
    $that_error_goes = 'that error goes';
  }
  else {
    my $last = pop @slop_failures;
    local $" = ', ';
    $tc_list = "@slop_failures and $last";
    $that_error_goes = 'those errors go';
  }
  print "\nThe failure of $tcs $tc_list may have been due to \n",
        "the vagaries of random number generation.  Run make\n",
        "test again and see if $that_error_goes away.\n";
}
