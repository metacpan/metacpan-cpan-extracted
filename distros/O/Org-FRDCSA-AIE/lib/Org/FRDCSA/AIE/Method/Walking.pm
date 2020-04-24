package Org::FRDCSA::AIE::Method::Walking;

# use PerlLib::SwissArmyKnife;

use Algorithm::Diff qw(LCS);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (AIE);

my @regex;

sub AIE {
  my %args = @_;
  my $entries = $args{Entries};

  @regex = ();
  my @all;
  foreach my $entry (@$entries) {
    push @all, [split //, $entry];
  }

  my $loud = 0;
  my $finished = 0;
  my $synced = 1;
  my $indicies = {};
  my $size = {};
  my $i = 0;
  foreach my $i (0.. ((scalar @all) - 1)) {
    $indicies->{$i} = 0;
    $size->{$i} = scalar @{$all[$i]};
  }
  while (! $finished) {
    if ($synced) {
      # see if the next character is the same
      my $nextchars = {};
      foreach my $key (keys %$indicies) {
	$nextchars->{$all[$key]->[$indicies->{$key}]} = 1;
      }
      if ((scalar keys %$nextchars) == 1) {
	AddToRegex(Char => [keys %$nextchars]->[0]);
	foreach my $key (keys %$indicies) {
	  $indicies->{$key}++;
	  if ($indicies->{$key} >= $size->{$key}) {
	    # this string is ended
	    # what to do?

	    # more or less we have a few options, we could just add
	    # everything that follows on every string as one last input

	    # or we could continue without this

	    # but for now, in development, let's just quit
	    $finished = 1;
	  }
	}
      } else {
	$synced = 0;
	AddToRegex
	  (
	   Control => "(.*?)",
	  );
	# need to resync the lists

	# do a thing where we iterate and get the LCS

	my $finishedsyncing = 0;
	my $window = 1;
	my $lcs;
	while (! $finishedsyncing) {
	  # take a window and make the window larger and larger
	  my @candidates;
	  my $overages = 0;
	  foreach my $key (keys %$indicies) {
	    my $last = $indicies->{$key} + $window;
	    if ($last >= ($size->{$key} - 1)) {
	      $last = ($size->{$key} - 1);
	      $overages++;
	    }
	    print "THING<".$indicies->{$key}."><$last>\n" if $loud;
	    my @entry;
	    foreach my $i ($indicies->{$key}..$last) {
	      push @entry, $all[$key]->[$i];
	    }
	    push @candidates, \@entry;
	  }
	  if ($overages == scalar keys %$indicies) {
	    $finishedsyncing = 1;
	    $finished = 1;
	  }

	  print Dumper(\@candidates) if $loud;
	  # print Dumper({Candidates => \@candidates}) if $loud;
	  $lcs = nLCSList2
	    (
	     Entries => \@candidates,
	    );
	  my $string = join("",@$lcs);
	  print "$string\n" if $loud;
	  print Dumper({LCS0 => $lcs}) if $loud;
	  if ((scalar @$lcs) > 4) {
	    # go ahead and find the rest there
	    print Dumper({LCS1 => $lcs}) if $loud;
	    $finishedsyncing = 1;
	  }
	  ++$window;
	  print "\n" if $loud;
	}

	print Dumper({LCS2 => $lcs}) if $loud;

	# okay now we have to sync everything
	my $cant = 0;
	foreach my $key (keys %$indicies) {
	  my $idx = $indicies->{$key};
	  my @copy = @$lcs;
	  print Dumper(\@copy) if $loud;
	  my $char = shift @copy;
	  my $first;
	  while (scalar @copy) {
	    if ($all[$key]->[$idx] ne $char) {
	      ++$idx;
	    } else {
	      if (! $first) {
		$first = $idx;
	      }
	      $char = shift @copy;
	    }
	  }
	  ++$idx;
	  if (! defined $first) {
	    $first = $indicies->{$key};
	  }
	  # update the index
	  print "KeyIDX<$key><$idx>\n" if $loud;
	  my $diff = $idx - $first;
	  if ($diff != 4) {
	    print "<DIFF: $diff>\n" if $loud;
	    $cant = 1;
	  }
	  $indicies->{$key} = $idx + 1;
	}
	if ($cant) {
	  foreach my $item (@$lcs) {
	    AddToRegex
	    (
	     Char => $item,
	    );
	    AddToRegex
	    (
	     Control => "(.*?)",
	    );
	  }
	} else {
	  AddToRegex
	    (
	     Char => join("", @$lcs),
	    );
	}
	$synced = 1;
      }
    } else {
      # Hrm, don't we already handle this above?
    }
  }

  my $regex = join("",@regex);
  print "REGEX: ".$regex."\n\n\n";

  my @final;
  foreach my $entry (@$entries) {
    my @results;
    my @matches = $entry =~ /$regex/;
    foreach my $match (@matches) {
      if ($match ne "") {
	push @results, $match;
      }
    }
    push @final,\@results;
  }
  return \@final;
}

sub nLCSString {
  my %args = @_;
  my $entries = $args{Entries};
  my $size = scalar @$entries;
  my @intermediate = split //, $entries->[0];
  foreach my $i (0 .. ($size - 2)) {
    @intermediate = LCS(\@intermediate,[split //, $entries->[$i + 1]]);
  }
  return join("",@intermediate);
}

sub nLCSList {
  my %args = @_;
  my $entries = $args{Entries};
  my $size = scalar @$entries;
  my @intermediate = @{$entries->[0]};
  foreach my $i (0 .. ($size - 2)) {
    @intermediate = LCS(\@intermediate,$entries->[$i + 1]);
  }
  return \@intermediate;
}

sub nLCSList2 {
  my %args = @_;
  my $entries = $args{Entries};
  my $width = 5;
  my $entryid = 0;
  my $hash = {};
  foreach my $entry (@$entries) {
    my $size = scalar @$entry;
    if ($size >= $width) {
      foreach my $i (0..($size-$width)) {
	my @copy;
	foreach my $j (0..($width - 1)) {
	  push @copy, $entry->[$i+$j];
	}
	$hash->{join("",@copy)}->{$entryid} = 1;
      }
    } else {
      return [];
    }
    ++$entryid;
  }

  foreach my $key (keys %$hash) {
    if (scalar keys %{$hash->{$key}} == scalar @$entries) {
      # print "HOLYCOW: <$key>\n".length($key)."\n";
      return [split //,$key];
    }
  }
}

sub AddToRegex {
  my %args = @_;
  if ($args{Char}) {
    my $char = $args{Char};
    $char =~ s/([^a-zA-Z0-9])/\\$1/g;
    push @regex, $char;
  } elsif ($args{Control}) {
    push @regex, $args{Control};
  }
}

1;
