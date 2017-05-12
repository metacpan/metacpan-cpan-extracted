
# $storage is defined

# normally, for this sort of thing I'd use YAML
{
my ($members, $syd, $bob, $gilmour, @junk);

my @bands =
    (
     CD::Band->new
     ({ name => "The English Beat",
      popularity => "one hit wonder",
      cds => Set::Object->new
      (
       CD->new({  title => "Beat This: The Best of the English Beat",
		publishdate => iso("2001-09-11"), # (!)
		songs => [ map { CD::Song->new({ name => $_}) }
"Mirror In The Bathroom",
"Best Friend",
"Hands Off She's Mine",
"Too Nice To Talk To",
"Doors Of Your Heart",
"I Confess",
"Twist And Crawl",
"Rankin Full Stop",
"Drowning",
"Save It For Later",
"Sole Salvation",
"Click Click",
"Tears Of A Clown",
"Can't Get Used To Losing You",
"Stand Down Margaret",
			 ]
	      }),
       CD->new({ title => "Special Meat Service",
		publishdate => iso("1999-10-26"),
		songs => [ map { CD::Song->new({name => $_}) }
			   "I Confess",
			   "Jeannette",
			   "Sorry",
			   "Sole Salvation",
			   "Spar Wid Me",
			   "Rotating Heads",
			   "Save It For Later",
			   "She's Going",
			   "Pato and Roger A Go Talk",
			   "Sugar and Stress",
			   "End of the Party",
			 ],
	      })
      ),
      members => Set::Object->new
      ( map { CD::Person->new({ name => $_ }) }
	"David Steele",
	"Saxa",
	"Everett Morton",
	"Wesley Magoogan",
	"Andy Cox",
	"Ranking Roger",
	"Dave Wakeling",
      ),
     }),
     CD::Band->new
     ({ name => "The Pink Floyd",
       popularity => "fledgling",
       creationdate => iso("1964"),
       enddate => iso("1968"),
       cds => Set::Object->new
       (
	CD->new({ title => "The Piper At the Gates of Dawn",
		 publishdate => iso("1967"),
		 songs => [ map { CD::Song->new({name => $_}) }
"Astronomy Domine",
"Lucifer Sam",
"Matilda Mother",
"Flaming",
"Pow R. Toc H.",
"Take Up Thy Stethoscope and Walk",
"Interstellar Overdrive",
"The Gnome",
"Chapter 24",
"Scarecrow",
"Bike",
			 ]
	      }),
       ),
      members => $members=Set::Object->new
      ( ($syd, $bob, @junk) = map { CD::Person->new({ name => $_ }) }
	"Syd Barrett",
	"Bob Klose",
	"Richard Wright",
	"Roger Waters",
	"Nick Mason (drums)",
      ),
     }),

     CD::Band->new
     ({ name => "The Pink Floyd",
       popularity => "increasing",
       creationdate => iso("1968"),
       enddate => iso("1969"),
       cds => Set::Object->new
       (
	CD->new({ title => "A Saucerful of Secrets",
		 publishdate => iso("1968"),
		 songs => [ map { CD::Song->new({name => $_}) }
"Let There Be More Light",
"Remember A Day",
"Set The Controls For The Heart Of The Sun",
"Corporal Clegg",
"A Saucerful of Secrets",
"See-Saw",
"Jugband Blues",
			  ]
	       }),
       ),
      members => Set::Object->new
       ( $members->members,
	 ($gilmour = CD::Person->new({ name => "David Gilmour" }))
       ),
     }),

     CD::Band->new
     ({ name => "Pink Floyd",
       popularity => "great",
       creationdate => iso("1969"),
       cds => Set::Object->new
       (
	CD->new({ title => "Ummagumma (disc 1 - live disc)",
		 publishdate => iso("1969-10-25"),
		 songs => [ map { CD::Song->new({name => $_}) }
"Astronomy Domine",
"Careful With That Axe, Eugene",
"Set The Controls For The Heart of The Sun",
"A Saucerful of Secrets",
			  ]
	       }),
	CD->new({ title => "Ummagumma (disc 2 - studio disc)",
		 publishdate => iso("1969-10-25"),
		 songs => [ map { CD::Song->new({name => $_}) }
"Sysyphus Part 1",
"Sysyphus Part 2",
"Sysyphus Part 3",
"Sysyphus Part 4",
"Grantchester Meadows",
"Several Species Of Small Furry Animals Gathered In A Cave And Grooving With A Pict",
"The Narrow Way Part 1",
"The Narrow Way Part 2",
"The Narrow Way Part 3",
"The Grand Vizier's Garden Party Part 1\u2014Entrance",
"The Grand Vizier's Garden Party Part 2\u2014Entertainment",
"The Grand Vizier's Garden Party Part 3\u2014Exit",
			  ]
	       }),
       ),
       members => Set::Object->new
       ( ( ($members - Set::Object->new($syd, $bob))->members,
	  $gilmour,
	 ),
       )
      }),

     CD::Band->new
     ({ name => "Damnwells",
       popularity => "fringe",
       cds => Set::Object->new
       (
	CD->new({ title => "Bastards of the Beat",
		 publishdate => iso("2004-04-06"),
		 songs => [ map { CD::Song->new({name => $_}) }
"A******s",
"What You Get",
"Kiss Catastrophe",
"I'll Be Around",
"Newborn History",
"I Will Keep The Bad Things From You",
"Sleepsinging",
"The Sound",
"The Lost Complaint",
"Electrric Harmony",
"New Delhi",
"Star / Fool",
			  ],
	       }),
       ),
	members => Set::Object->new
	( map { CD::Person->new({ name => $_ }) }
	  "Alex Dezen",
	  "David Chernis",
	  "Ted Hudson",
	  "Steven Terry"
	)
      })
    );

$storage->insert(@bands);

}

1;
