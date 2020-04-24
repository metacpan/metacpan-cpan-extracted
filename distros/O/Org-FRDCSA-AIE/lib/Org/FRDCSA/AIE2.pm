package Org::FRDCSA::AIE2;

# this has been modified to allow us to explicitly set the cycles,
# i.e. if we have repeated data from which we wish to extract the
# patterns

# use PerlLib::SwissArmyKnife;

use Algorithm::Diff qw(LCS);
use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /
	Verbose
      /
  ];

sub init {
  my ($self,%args) = @_;
  $self->Verbose(1);
  $self->ExtractMajorPatterns
    (String => $args{Contents});
}

sub ExtractMajorPatterns {
  my ($self,%args) = @_;
  print "Extracting major patterns\n" if $self->Verbose;
  my $occurances = $self->GetAllSubstringsLengthLessThanSize
    (Size => 10,
     String => $args{String});
  my $res = $self->ExtractMostUsefulTerms
    (Occurances => $occurances);
  # now spot a major item, do a spot check and print out repeating lists
  # convert to the list format
  my $order = {};
  foreach my $k1 (keys %$occurances) {
    foreach my $k2 (keys %{$occurances->{$k1}}) {
      $order->{$k2}->{$k1} = 1;
    }
  }
  # now we have the list, so select a random instance of a
  # popular token, and then extract the next instance

  my $token;
  my $counter = 10;
  if (0) {
    do {
      $token = $res->{List}->[int rand $counter];
      ++$counter;
    } while (length($token) < 5 or $token =~ /^\s*$/);
  } else {
    foreach my $token2 (@{$res->{List}}) {
      if ($token2 =~ /DFSJDKFL/) {
	$token = $token2;
	last;
      }
    }
  }
  print "Chose token: ".Dumper($token)."\n" if $self->Verbose;

  my $l = [sort {$a <=> $b} keys %{$occurances->{$token}}];
  my $listsize = scalar @$l;
  my $i = int rand $listsize;
  print "Selected instance $i of $listsize\n" if $self->Verbose;
  # print the remaining cycles
  my $cycles = [];
  for (my $cycle = 0; $cycle < 10; ++$cycle) {
    $cycles->[$cycle] = [];
    for (my $j = $l->[$i+$cycle]; $j < $l->[$i+1+$cycle]; ++$j) {
      if (exists $order->{$j}) {
	my $neworder;
	foreach my $k (keys %{$order->{$j}}) {
	  if (length($k) > 1) {
	    my $tmp = $res->{Ilist}->{$k};
	    if (defined $tmp) { # and $tmp < 450) {
	      $neworder->{$k} = $j;
	    }
	  }
	}
	push @{$cycles->[$cycle]}, $neworder if $neworder;
      }
    }
  }

  # remove tokens that are not common to all three
  my $cyclecount = 0;
  my $seen = {};
  foreach my $cycle (@$cycles) {
    foreach my $hash (@$cycle) {
      foreach my $k (keys %$hash) {
	$seen->{$k}->{$cyclecount} = 1;
      }
    }
    ++$cyclecount;
  }
  my $keep = {};
  foreach my $k (keys %$seen) {
    if (scalar keys %{$seen->{$k}} == $cyclecount) {
      $keep->{$k} = 1;
    }
  }

  # now reconstruct the cycles using the keep predicate
  my $newcycles = [];
  foreach my $cycle (@$cycles) {
    my $newcycle = [];
    foreach my $hash (@$cycle) {
      my $newhash = {};
      foreach my $key (keys %$hash) {
	if (exists $keep->{$key}) {
	  $newhash->{$key} = $hash->{$key};
	}
      }
      if (scalar keys %$newhash) {
	push @$newcycle, $newhash;
      }
    }
    push @$newcycles, $newcycle;
  }

  my $regex = $self->ExtractRegexFromCycles
    (
     Index => $i,
     Cycles => $newcycles,
     TokenList => $l,
    );

  # clean the regular expression
  $regex =~ s/(\(\.\*\))+/(.*)/g;
  $regex =~ s/^(\(\.\*\))//;
  $regex =~ s/(\(\.\*\))$//;
  my @seeks = $regex =~ /(\(\.\*\))/g;
  my $size = scalar @seeks;

  print Dumper($regex)."\n" if $self->Verbose;

  my @elements = $args{String} =~ /$regex/g;

  my @entries;
  while (@elements) {
    push @entries, [splice(@elements,0,$size)];
  }
  print "Extracted ".(scalar @entries)." records\n" if $self->Verbose;
  print Dumper(\@entries);
}

sub GetAllSubstringsLengthLessThanSize {
  my ($self,%args) = @_;
  my $occurances = {};
  # now we want to efficiently generate this

  # hash H->{STRING}->{OFFSET} = 1;

  # then repetition frequency is just counting the scalar keys of H->{STRING}

  # to efficiently compute this list we can do simple iteration
  my @l = split //, $args{String};
  print "Length: ".(scalar @l)."\n" if $self->Verbose;
  for (my $i = 0; $i < scalar @l; ++$i) {
    if (!($i % 1000)) {
      print "." if $self->Verbose;
    }
    if (!($i % 50000)) {
      print "\n" if $self->Verbose;
    }
    for (my $j = $i + 1; $j <= Min(Items => [$i + $args{Size},scalar @l]); ++$j) {
      $occurances->{substr($args{String},$i,$j-$i)}->{$i} = 1;
    }
  }
  print "\n" if $self->Verbose;
  return $occurances;
}

sub ExtractMostUsefulTerms {
  my ($self,%args) = @_;
  print "Extracting most useful terms\n" if $self->Verbose;
  my $occurances = $args{Occurances};
  my $res;
  my $usefulness = {};
  my @list;
  foreach my $k1 (keys %$occurances) {
    if (scalar keys %{$occurances->{$k1}} > 1) {
      $res->{$k1} = $occurances->{$k1};
    }
  }
  my $count = 0;
  my $ilist = {};
  foreach my $k1 (sort {
    (scalar keys %{$res->{$b}}) * length($b) <=>
      (scalar keys %{$res->{$a}}) * length($a)}
		  keys %$res) {
    my $x = (scalar keys %{$res->{$k1}})*length($k1);
    # print $x."\t{{{".$k1."}}}\n";
    push @list, $k1;
    $ilist->{$k1} = $count++;
    $usefulness->{$k1} = $x;
  }
  return {List => \@list,
	  Ilist => $ilist,
	  Usefulness => $usefulness};
}

sub ExtractRegexFromCycles {
  my ($self,%args) = @_;
  # take the cycles, extract longest common subsequences check rest of the sequences
  # take 3 random cycles

  my $size = scalar @{$args{Cycles}};
  my @l = 0..($size - 1);
  my @n;
  for (my $i = 0; $i < 8; ++$i) {
    my $index = int rand scalar @l;
    push @n, $l[$index];
    $l[$index] = $l[scalar @l - 1];
    pop @l;
  }

  # now for each of these cycles
  # compute the lengths of the cycles and exit
  my @regexes;
  foreach my $index (@n) {
    # print $index."\n";
    my $newhash = {};
    foreach my $hash (@{$args{Cycles}->[$index]}) {
      foreach my $key (keys %$hash) {
	$newhash->{$key} = $hash->{$key};
      }
    }
    my $length = (scalar keys %$newhash);
    my $regex = $self->GenerateRegexFromCycle
      (
       Cycle => $args{Cycles}->[$index],
       TokenList => $args{TokenList},
       Index => $args{Index},
      );
    # print $regex."\n\n\n";
    push @regexes, $regex;
  }

  # print Dumper(\@regexes);

  my $regex = shift @regexes;
  while (@regexes) {
    my $r2 = shift @regexes;
    $regex = join("",LCS([split //,$regex], [split //,$r2]));
  }

  $regex =~ s/\\{1}//g;		# IS THIS REALLY NECESSARY?
  return $regex;
}

sub GenerateRegexFromCycle {
  my ($self,%args) = @_;
  # print Dumper(\%args);
  # exit(0);
  my @string;
  my $last;
  foreach my $hash (@{$args{Cycle}}) {
    foreach my $string (keys %$hash) {
      my $x = 0;
      foreach my $char (split //,$string) {
	$string[$hash->{$string} - $args{TokenList}->[$args{Index}] + $x++] = $char;
	$last = $hash->{$string};
      }
    }
  }

  # splice off anything after last
  splice(@string,$last - $args{TokenList}->[$args{Index}] + 1);

  # print Dumper(\@string);

  my @constant;
  my $r = [];
  my $undefperiod = 0;

  # See({String => \@string});

  foreach my $element (@string) {
    if (! defined $element) {
      if ($undefperiod) {
	# just move along
      } else {
	$undefperiod = 1;
	if (@constant) {
	  my @cp = @constant;
	  push @$r,\@cp;
	  @constant = ();
	}
	push @$r,undef;
      }
    } else {
      $undefperiod = 0;
      push @constant, $element;
    }
  }
  if (@constant) {
    my @cp = @constant;
    push @$r, \@cp;
  }

  # now print this structure
  # print Dumper($r);

  my $regex;
  foreach my $list (@$r) {
    if (defined $list) {
      my $constant = join("",@$list);
      $constant =~ s//\r/g;
      $constant =~ s/([^\w\s\n])/\\$1/g;
      # $constant =~ s/\n/\\n/g;
      $regex .= $constant;
    } else {
      $regex .= "(.*)";
    }
  }
  return $regex;
}

# how to extract valid patterns

# the longer the pattern in terms of numbers of entries the better
# the more often the pattern repeats

# we can search over pattern space, pruning by the various factors

# a pattern consists of a repeating sequence of tokens

# first search by the largest and most useful tokens


# detecting repeating subsequences optimized over sequence value

# frequency window (prune by frequency for starters)

# lower bound
# upper bound
# sequence

# detect all repeating subsequences of 2 items,
# merge

1;
