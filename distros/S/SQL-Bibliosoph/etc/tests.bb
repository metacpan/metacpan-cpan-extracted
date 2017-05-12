--[ TITo ]
    { a=>1, b=>2 }

--[ rowh_RANDy ]    
    {name => join "", rand_chars( set=> "alpha", min=>5, max=>7) } 

--[ rowh_RAND2y ]
     {name => join "", rand_chars( set=> "numeric", min=>5, max=>7) }

--[ h_RAND3 ]
    [ { id => (join '',rand_chars(set=>"numeric")), name => join ('', rand_chars(set=>"alpha")), role_code => 1 }, ],


--[ h_MEEK_FOR_MOVIE ]
    [ 
    { id => rand_chars(set=>"numeric"), name => rand_chars(set=>"alpha"), role_code => 1 }, 
    { id => rand_chars(set=>'numeric'), name => rand_chars(set=>'alpha'), role_code => 1 },
    { id => rand_chars(set=>'numeric'), name => rand_chars(set=>'alpha'), role_code => 1 },
    { id => rand_chars(set=>'numeric'), name => rand_chars(set=>'alpha'), role_code => 2 },
    { id => rand_chars(set=>'numeric'), name => rand_chars(set=>'alpha'), role_code => 2 },
    ],

--[ h_GET_LOCATIONS ]
    [ { id=>1, label => 'tucuman1'},
      { id=>2,label => 'tucuman2'},
      { id=>3,label => 'tucuman3'},
      { id=>4,label => 'tucuman4'},
      { id=>5, label=> 'tucuman5'},
      { id=>6,label => 'tucuman6'},
      { id=>7,label => 'tucuman7'},
      { id=>8,label => 'tucuman8'},
      { id=>9,label => 'tucuman9'},
      { id=>10,label=> 'tucuman10'}, 
    ],

--[ BAD ]
    i'm a syntax error
