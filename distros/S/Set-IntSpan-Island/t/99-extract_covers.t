
use strict;
use Test::More tests=>115; # qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (

	    [ {
		a=>"10",
		},
	      [ 
		[10,10,"a"],
		],
	      ],

	    [ {
		a=>"10",
		b=>"12",
		},
	      [ 
		[10,10,"a"],
		[11,11,""],
		[12,12,"b"],
		],
	      ],

	    [ {
		a=>"10-12",
		b=>"10",
		c=>"12",
		},
	      [ 
		[10,10,"ab"],
		[11,11,"a"],
		[12,12,"ac"],
		],
	      ],

	    [ {
		a=>"10-12",
		b=>"10",
		c=>"12,20-25",
		},
	      [ 
		[10,10,"ab"],
		[11,11,"a"],
		[12,12,"ac"],
		[13,19,""],
		[20,25,"c"],
		],
	      ],

	    [ {
		a=>"10-15,21-22",
		b=>"12,25",
		c=>"14-20",
		d=>"25",
		},
	      [ 
		[10,11,"a"],
		[12,12,"ab"],
		[13,13,"a"],
		[14,15,"ac"],
		[16,20,"c"],
		[21,22,"a"],
		[23,24,""],
		[25,25,"bd"],
		],
	      ],


	    [ {
		a=>"10-13",
		b=>"10",
		c=>"12",
		d=>"15",
		},
	      [ 
		[10,10,"ab"],
		[11,11,"a"],
		[12,12,"ac"],
		[13,13,"a"],
		[14,14,""],
		[15,15,"d"],
		],
	      ],

	    [ {
		a=>"10-13",
		b=>"10",
		c=>"12",
		d=>"15",
		e=>"15",
		},
	      [ 
		[10,10,"ab"],
		[11,11,"a"],
		[12,12,"ac"],
		[13,13,"a"],
		[14,14,""],
		[15,15,"de"],
		],
	      ],

	    [ {
		a=>"10-20",
		b=>"15-25"
		},
	      [ 
		[10,14,"a"],
		[15,20,"ab"],
		[21,25,"b"],
		],
	      ],

	    [ {
		a=>"10-20",
		b=>"15-20",
		c=>"25-30",
		},
	      [ 
		[10,14,"a"],
		[15,20,"ab"],
		[21,24,""],
		[25,30,"c"],
		],
	      ],

	    [ {
		a=>"10-20",
		b=>"22",
		c=>"23-24",
		d=>"25-30",
		},
	      [ 
		[10,20,"a"],
		[21,21,""],
		[22,22,"b"],
		[23,24,"c"],
		[25,30,"d"],
		],
	      ],

	    [ {
		a=>"5-35",
		b=>"10-20",
		c=>"22",
		d=>"23-24",
		e=>"25-30",
		f=>"27-28",
		},
	      [ 
		[5,9,"a"],
		[10,20,"ab"],
		[21,21,"a"],
		[22,22,"ac"],
		[23,24,"ad"],
		[25,26,"ae"],
		[27,28,"aef"],
		[29,30,"ae"],
		[31,35,"a"],
		],
	      ],
	
	    [ {
		a=>"10-15",
		b=>"12",
		c=>"14-20",
		d=>"25",
	    },
	      [ 
		[10,11,"a"],
		[12,12,"ab"],
		[13,13,"a"],
		[14,15,"ac"],
		[16,20,"c"],
		[21,24,""],
		[25,25,"d"],
		],
	      ],

	    [ {
		a=>"0-1,3-5",
		b=>"2-6,8-9",
	    },
	      [ 
		[0,1,"a"],
		[2,2,"b"],
		[3,5,"ab"],
		[6,6,"b"],
		[7,7,""],
		[8,9,"b"],
		],
	      ],

	    [ {
		a=>"0-9",
		b=>"2-6,8-9",
	    },
	      [ 
		[0,1,"a"],
		[2,6,"ab"],
		[7,7,"a"],
		[8,9,"ab"],
		],
	      ],

	    [ {
		a=>"0-9,11-15",
		b=>"2-6,8-9",
	    },
	      [ 
		[0,1,"a"],
		[2,6,"ab"],
		[7,7,"a"],
		[8,9,"ab"],
		[10,10,""],
		[11,15,"a"],
		],
	      ],

	    );

extract_covers();
extract_covers_random(100);

use Data::Dumper;

sub extract_covers_random {
  my $iterations = shift;
  
  my $num_sets       = 50;
  my $max_value      = 200;
  my $num_covers     = 50;
  my $max_cover_size = 15;
  my $min_cover_size = 1;

  my $range          = Set::IntSpan::Island->new("1-$max_value");
  
  for my $iter (1..$iterations) {
    my $coverage = Set::IntSpan::Island->new();
    my $sets;
    my $true_covers_by_id;
    my $true_covers;
    for my $c (1..$num_covers) {
      # construct a cover that does not overlap with existing coverage
      my $cstart = int(rand($range->max));
      my $cset = Set::IntSpan::Island->new($cstart,$cstart+int(rand($max_cover_size)));
      $cset = $cset->intersect($range);
      $cset = $cset->diff($coverage);
      last if $coverage->cardinality == $range->cardinality;
      redo if ! $cset->cardinality;
      redo if $cset->sets > 1;
      # add the cover to the coverage
      $coverage = $coverage->union($cset);
      my %ids;
      # generate random set names, up to 15 sets
      map { $ids{chr(97 + rand($num_sets))}++ } (1..int(1+rand($num_sets)));
      # add this cover to each of the random sets
      for my $id (keys %ids) {
	$sets->{$id} ||= Set::IntSpan::Island->new();
	$sets->{$id} = $sets->{$id}->union($cset);
      }
      # create a digest of set names that contain this cover
      my $id_digest = join("",sort keys %ids);
      # update the coverage set for this digest
      $true_covers_by_id->{$id_digest} ||= Set::IntSpan::Island->new();
      $true_covers_by_id->{$id_digest} = $true_covers_by_id->{$id_digest}->union($cset);
    }
    for my $id_digest (keys %$true_covers_by_id) {
      for my $set ($true_covers_by_id->{$id_digest}->sets) {
	push @$true_covers, [$set, [split("",$id_digest)]];
      }
    }
    for my $span ($range->diff($coverage)->sets) {
      next if ! $span->overlap($coverage->cover);
      push @$true_covers, [$span, []];
    }
    for my $id (keys %$sets) {
      #print $id," ",$sets->{$id}->run_list,"\n";
    }
    my $test_covers = Set::IntSpan::Island->extract_covers($sets);
    
    for my $cover (sort {$a->[0]->min <=> $b->[0]->min} @$true_covers) {
      my ($cset,$ids) = @$cover;
      #print "true ", $cset->run_list," ",@$ids,"\n";
    }
    for my $cover (@$test_covers) {
      my ($cset,$ids) = @$cover;
      #print "test ", $cset->run_list," ",@$ids,"\n";
    }
    if(@$test_covers != @$true_covers) {
      fail("fail num covers ".int(@$test_covers)." ".int(@$true_covers));
    } else {
      $true_covers = [ sort {$a->[0]->min <=> $b->[0]->min} @$true_covers ];
      for my $i (0..@$test_covers-1) {
	if($test_covers->[$i][0]->run_list ne $true_covers->[$i][0]->run_list) {
	  fail(join(" ","fail run list".$i,$test_covers->[$i][0]->run_list,
		    $true_covers->[$i][0]->run_list));
	} elsif (join("",sort split("",@{$test_covers->[$i][1]})) ne join("",sort split("",@{$true_covers->[$i][1]}))) {
	  fail(join(" ","fail content ",$i,
		    join("",sort split("",@{$test_covers->[$i][1]})),
		    join("",sort split("",@{$true_covers->[$i][1]}))));
	} else {
	  # ok
	}
      }
    }
    ok("covers ok");
  }
}

sub extract_covers {
  for my $setdata (@sets) {
    my $h;
    for my $id (keys %{$setdata->[0]}) {
      $h->{$id} = Set::IntSpan::Island->new( $setdata->[0]{$id} );
    }
    my $covers = Set::IntSpan::Island->extract_covers( $h );
    my $results = $setdata->[1];
    if(@$results != @$covers) {
      fail("wrong number of covers");
    } else {
      for my $i (0..@$results-1) {
	my $result = $results->[$i];
	my $cover  = $covers->[$i];
	if($cover) {
	  printf("#%3d %3d %5s %3d %3d %5s\n",
		 $cover->[0]->min,
		 $cover->[0]->max,
		 join("",@{$cover->[1]}),
		 @$result);
	  if($result->[0] == $cover->[0]->min &&
	     $result->[1] == $cover->[0]->max &&
	     join("",sort split("",$result->[2])) eq join("",sort @{$cover->[1]})) {
	    # ok
	  } else {
	    fail("cover failure");
	    last;
	  }
	} else {
	  fail("cover failure");
	  last;
	}
      }
    }
    ok("covers ok");
  }
}
