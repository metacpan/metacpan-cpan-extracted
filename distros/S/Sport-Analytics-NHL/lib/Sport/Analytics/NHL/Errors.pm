package Sport::Analytics::NHL::Errors;

use strict;
use warnings FATAL => 'all';

use Sport::Analytics::NHL::Config qw(:ids);

use parent 'Exporter';

our @EXPORT = qw(
	%BROKEN_FILES %BROKEN_HEADERS
	%BROKEN_COACHES %BROKEN_PLAYERS %BROKEN_EVENTS
	%BROKEN_ROSTERS %BROKEN_PLAYER_IDS
	%BROKEN_TIMES %BROKEN_COORDS %BROKEN_CHALLENGES %BROKEN_PENALTIES
	%NAME_TYPOS %NAME_VARIATIONS %REVERSE_NAME_TYPOS
	%SPECIAL_EVENTS %FORCED_PUSH
	%MISSING_EVENTS %MISSING_COACHES %MISSING_PLAYERS %MISSING_PS_GOALIES
	%MISSING_PLAYER_INFO %BROKEN_SHIFTS
	%MANUAL_FIX %BROKEN_ON_ICE_COUNT %SAME_SO_TWICE
	$INCOMPLETE $REPLICA $NO_EVENTS $UNSYNCHED $BROKEN
);

our %NAME_TYPOS = (
	'BRYCE VAN BRABRANT' => 'BRYCE VAN BRABANT',
	'TOMMY WESTLUND'     => 'TOMMY VESTLUND',
	'MATTIAS JOHANSSON'  => 'MATHIAS JOHANSSON',
	'WESTLUND'           => 'VESTLUND',
	'T. WESTLUND'        => 'T. VESTLUND',
	'N. KRONVALL'        => 'N. KRONWALL',
	'S. KRONVALL'        => 'S. KRONWALL',
	'A. KASTSITSYN'      => 'A. KOSTITSYN',
	'F. MEYER IV'        => 'F. MEYER',
	'P/ BRISEBOIS'       => 'P. BRISEBOIS',
	'K. PUSHKARYOV'      => 'K. PUSHKAREV',
	'M. SATIN'           => 'M. SATAN',
	'B. RADIVOJEVICE'    => 'B. RADIVOJEVIC',
	'J. BULLIS'          => 'J. BULIS',
	'PJ. AXELSSON'       => 'P.J. AXELSSON',
);
our %REVERSE_NAME_TYPOS = (
	'KRONWALL' => 'KRONVALL',
);

our %NAME_VARIATIONS = (
	'CHRIS KENADY'   => 'CHRISTOPHER KENADY',
	'JOHN THOMAS'    => 'S. THOMAS',
	'BILLY TIBBETTS' => 'W. TIBBETTS',
	'WILLIAM BOWLER' => 'B. BOWLER',
	'BOBBY HOLIK'    => 'R. HOLIK',
	'RANDY MCKAY'    => 'H. MCKAY',
	'MATT CARLE'     => 'MATTHEW CARLE',
);

our %BROKEN_COACHES = (
	STICKLE                => 'BOB MURDOCH',
	'CASHMAN/THIFFAULT'    => 'MICHEL BERGERON',
	'LEVER/SMITH'          => 'TED SATOR',
	'WILSON/RAEDER'        => 'TOM WEBSTER',
	'RAEDER/WILSON'        => 'TOM WEBSTER',
	'BAXTER/CHARRON'       => 'DOUG RISEBROUGH',
	'CHARRON/BAXTER'       => 'GUY CHARRON',
	'CHARON,BAXTER,HISLOP' => 'GUY CHARRON',
	'EDDIE OATMAN'         => 'JEREMY COLLITON',
);

our %BROKEN_PLAYERS = (
	BS => {
		192730312 => { 8448095 => { number => 16, }	},
		194330121 => { 8449068 => { assists => 1,} },
		195620210 => {
			8450108 => { shots => 26, saves => 22, goals => 4, },
			8450152 => { shots => 22, saves => 18, goals => 4, },
		},
		195820138 => {
			8450065 => { shots => 39, saves => 32, goals => 7, },
		},
		196030111 => {
			8449988 => { saves => 21, goals => 6, },
			8450066 => { saves => 25, goals => 2, },
		},
		196030121 => {
			8450111 => { shots => 36, saves => 33, goals => 3, },
			8450020 => { shots => 39, saves => 37, goals => 2, },
		},
		196030112 => {
			8449988 => { saves => 25, goals => 3, },
			8450066 => { saves => 19, goals => 4, },
		},
		196030113 => {
			8450066 => { saves => 42, goals => 2, },
		},
		196030125 => {
			8450111 => { shots => 30, saves => 28, goals => 2, },
			8449835 => { shots => 30, saves => 27, goals => 3, },
		},
		196130113 => {
			8449988 => { shots => 30, saves => 29, goals => 1, },
			8450066 => { shots => 30, saves => 26, goals => 4, },
		},
		196130124 => {
			8450152 => { shots => 27, saves => 25, goals => 2, },
			8449835 => { shots => 33, saves => 30, goals => 3, },
		},
		196930141 => {
			8451528 => { saves => 34, goals => 2, },
		},
		197520669 => { 8452574 => { penaltyMinutes => 2 }},
		197720583 => { 8446057 => { penaltyMinutes => 2 }},
		196820129 => { 8449481 => { penaltyMinutes => 2,}},
		197820329 => { 8446940 => { penaltyMinutes => 16,}},
		198020400 => { 8448411 => { penaltyMinutes => 21,}},
		198420013 => { 8451987 => { penaltyMinutes => 2, }},
		198720798 => { 8449535 => { assists => 1, } },
		199120753 => { 8448781 => { penaltyMinutes => 7 }},
		199320074 => { 8455408 => { penaltyMinutes => 4 }},
		199320499 => { 8459363 => { penaltyMinutes => 2 }},
		199320640 => { 8455984 => { penaltyMinutes => 6 }},
		199520048 => { 8458526 => { penaltyMinutes => 2 }},
		199620473 => { 8449545 => { penaltyMinutes => 2 }},
		199620546 => { 8449751 => { penaltyMinutes => 2 }},
		200320009 => {
			8470201 => { number => 22, position => 'L', },
			8467349 => { number => 8,  position => 'D', goals => 1, },
			8468789 => { number => 29, position => 'C', },
			8464960 => { number => 21, position => 'C', },
			8467427 => { number => 37, position => 'L', },
		},
		200320013 => { 8467333 => { number => 9, position => 'R' },},
		200320019 => {
			8466147 => { number => 17, position => 'C',},
		},
		200320021 => { 8467333 => { number => 9, position => 'R' },},
		200320027 => { 8458562 => { number => 29, position => 'G', decision => 'W' }, },
		200320048 => {
			8469656 => { number => 17, position => 'C',},
			8467332 => { number => 5, position => 'D',},
			8470201 => { number => 22, position => 'L', },
		},
		200320059 => {
			8464968 => { number => 10, position => 'L'},
		},
		200320065 => { 8468639 => { position => 'D' }},
#		200320072 => { 8468252 => { } }.
		200320104 => { 8467333 => { goals => 1, },	},
		200320132 => {
			8452578 => { number => 19, position => 'C', goals => 1},
		},
		200320248 => {
			8468003 => {goals => 1,},
		},
		200320331 => { 8467333 => { goals => 1 },},
		200320362 => { 8465059 => { goals => 1 },},
		200320459 => {
			8468083 => { goals => 1, assists => 2, number => 40 },
		},
		200320489 => {
			8467372 => { goals => 1, },
		},
		200320976 => {
			8467899 => {goals => 1, assists => 1 },
		},
		200321074 => { 8467386 => { goals => 1 },},
		200321181 => { 8464960 => { goals => 1 },},
		200320801 => { 8457785 => { goals => 1, }, },
		200320864 => { 8462078 => { goals => 1, assists => 1}, },
		200520009 => { 8471187 => { goals => 1, }},
		200520030 => { 8466147 => { goals => 1, }},
		200520935 => {
			8467913 => {
				_notest => 1,
			},
		},
		200520949 => { 8467323 => { goals => 1, }},
		200521052 => { 8459455 => { goals => 1, assists => 1 }},
		200620046 => { 8466266 => { goals => 1, }},
		200620382 => {
			8470640 => { assists => 1, },
			8470794 => { goals => 1, }
		},
		200620688 => {
			8469477 => { goals => 1, },
		},
		200720076 => { 8462044 => { decision => 'L'} },
		200530152 => { 8468515 => { goals => 1, position => 'C' }},
		200820502 => { 8470201 => { penaltyMinutes => 2, }},
		201520995 => { 8470602 => { penaltyMinutes => 6, }},
#		200621119 => { 8469479 => { position => 'G', number => 30 }},
	},
);

our %SAME_SO_TWICE = (
	200720811 => 1,
);
our %FORCED_PUSH = (
	PL => {
		200820009 => { 82  => 1, 83 => 1, },
		201020989 => { 346 => 1 },
		201120094 => { 198 => 1 },
		201420921 => { 354 => 1 },
		201520057 => { 150 => 1, 158 => 1, 197 => 1 },
		201520064 => { 316 => 1 },
		201520436 => { 176 => 1 },
		201520518 => { 152 => 1 },
		201520593 => { 273 => 1 },
		201520741 => { 343 => 1, 344 => 1 },
		201521035 => { 172 => 1 },
		201530122 => { 347 => 1 },
		201620161 => { 286 => 1 },
		201620177 => { 197 => 1 },
		201620321 => {  64 => 1 },
		201620920 => { 296 => 1, 297 => 1 },
		201621081 => { 101 => 1 },
		201720176 => { 303 => 1, 304 => 1, 305 => 1, 306 => 1},
	},
);
our %BROKEN_EVENTS = (
	BS => {
		195520195 => { 18 => { time => '10:06' },},
		197820401 => { 4 => { en => 1 }, },
		199920239 => { 22 => { en => 1 }, },
		198320770 => {
			20 => { time => '1:29' },
			21 => { time => '1:29' },
		},
		198520010 => { 16 => { time =>  '7:48' }, },
		198520611 => { 32 => { time => '10:09' }, },
		198720025 => {  0 => { player2 => 8447303 } },
		198820689 => {  5 => { player2 => 8446637 }, 6 => { player2 => 8446637 }, },
		198920567 => { 26 => { player1 => 8450167 }},
		199920756 => {  9 => { time => '5:34' }, },
		200320898 => { 13 => { time => '2:15' }, },
		200520067 => { 40 => { description => 'ANDY SUTTON ATTEMPT TO INJURE AGAINST JASON ALLISON', secondaryType => 'ATTEMPT TO INJURE'}},
		200520692 => { 40 => { description => 'SHELDON SOURAY ATTEMPT TO INJURE AGAINST DARREN MCCARTY', secondaryType => 'ATTEMPT TO INJURE'}},
		200520999 => { 30 => { description => 'CHRIS SIMON ATTEMPT TO INJURE AGAINST DARCY HORDICHUK', secondaryType => 'ATTEMPT TO INJURE'}},
		200621099 => { 16 => { description => 'CHRIS SIMON ATTEMPT TO INJURE AGAINST DARCY HORDICHUK', secondaryType => 'ATTEMPT TO INJURE'}},
		201021015 => { 345 => {en => 1}},
		201321046 => { 302 => -1 },
		201520416 => { 131 => { description => 'Offside' }},
		201520476 => { 291 => { en => 1 }},
		201521100 => { 58 => { description => 'OFFSIDE', } },
		201620665 => { 62 => { description => 'REFEREE OR LINESMAN,HOME TIMEOUT', } },
		201620693 => { 357 => {	description => 'REFEREE OR LINESMAN,HOME TIMEOUT', } },
		201630411 => { 47 => { description => 'OFFSIDE',}, },
		201621152 => { 9 => { assist2 => 8475209, assists => [8474141,8475209] }},
		201621165 => { 43 => { player1 => 8465009, assists => [ 8478443, 8476374]}},
		201720432 => { 304 => { description => '',}, },
		201720608 => { 125 => {	description => 'OFFSIDE', }, },
		201720929 => { 250 => {	description => 'OFFSIDE', }, },
		201720948 => { 330 => {	description => 'REFEREE OR LINESMAN,VISITOR TIMEOUT', }, },
		201820151 => { 338 => { player1  => 8471707 } },
		201821133 => { 56 => { team1 => 'TBL' } },
	},
	PL => {
		200220255 => { 122 => { player2 => 29 } },
		200220266 => {
			81 => { player1 => 54 },
			146 => { on_ice2 => [1, 54,21, 18, 11, 4, ] }
		},
		200320898 => { 110 => { time => '2:15' }, },
		200321115 => { 10 =>  { player2 => 38 } },
        200520084 => { 54  => { player1 => 35 } },
		200520307 => { 176 => { player1 => 20 } },
		200520312 => {
			1 => {
				id => 1, period => 1, time => '0:00', team => 'NSH',
				strength => 'EV', shot_type   => 'Snap',
				distance => 18, type => 'GOAL', location => 'Off',
				description => '22 JOHNSON, A: 20 SUTER, 7 UPSHALL, Snap, 18 ft',
				old         => 1, team1 => 'NSH', player1 => 22, assist1 => 20,
				on_ice      => [ [], [], ], special => 1, stage => 2, season => 2005,
			},
		},
		200520314 => {  47 => { player1 => 20 } },
		200520472 => { 107 => { player1 => 23 }},
        200520473 => { 254 => 0, },
        200520511 => { 247 => 0 },
        200520873 => { 143 => 0 },
		200520946 => { 211 => { player1 => 35 } },
        200521044 => { 313 => { player1 => 19, }, },
        200521114 => {   2 => 0 },
		200620061 => { 311 => { period => 3, }, 312 => {period => 3 }},
		200620433 => { 132 => { player1 => 31 } },
        200620597 => {  76 => 0, },
        200620637 => { 123 => 0, 217 => 0 },
        200620672 => { 131 => 0 },
        200620681 => { 305 => 0, },
		200620698 => { 234 => { player1 => 27 }},
        200620765 => { 266 => 0, },
        200621005 => { 180 => 0, },
        200621019 => {  66 => 0, },
		200621024 => { 139 => 0, 219 => { on_ice2 => [ 55, 47, 39, 3, 27, 94, ], }, 188 => 0, 194 => 0 },
		200621062 => { 220 => 0, },
        200621107 => { 151 => 0, },
        200621145 => { 194 => 0, },
		200720003 => { 275 => { description => 'CAR Team Too many men/ice - bench(2 min) Served By: #18 BAYDA, Neu. Zone', },
					   120 => {     on_ice => [ [14,6,84,44,71,39], [17,11,13,2,5,30] ], }, },
        200720014 => { 226 => { team1 => 'ARI', }, },
        200720019 => { 203 => { team1 => 'DAL', }, },
        200720026 => { 195 => { team1 => 'FLA', }, },
		200720028 => { 269 => 0, },
        200720039 => {  21 => { team1 => 'CAR', }, },
		200720162 => { 281 => 0, },
		200720199 => { 260 => 0, },
		200720811 => { 344 => { on_ice2 => [ 35 ] }},
		200730174 => {
			221 => { on_ice => [ [15,25,6,33,41,29], [94,39,8,24,44,60] ]},
			222 => { on_ice => [ [15,25,6,33,41,29], [94,39,8,24,44,60] ]},
			223 => { on_ice => [ [15,25,6,33,41,29], [94,39,8,24,44,60] ]}
		} ,
        200820118 => { 4   => { winning_team => 'EDM', } },
        200820332 => { 263 => { winning_team => 'DET', } },
		200820444 => { 190 => { player1 => $UNKNOWN_PLAYER_ID } },
        200820650 => { 37  => { winning_team => 'MIN', } },
        200820749 => { 207 => { winning_team => 'TBL', } },
        200820774 => { 92  => 0, 93 => {player1 => 17, }},
		200820868 => { 299 => { length => 2, penalty => 'Instigator', description => 'EDM #18 MOREAU Instigator(2 min) Drawn By: DAL #29 OTT'}, },
		200820900 => { 284 => { on_ice => [[],[]] }},
        200820987 => { 284 => 0, },
        200821191 => { 289 => { player1 => 20, team1 => 'NSH', player2 => 2, team2 => 'CHI' } },
		200921066 => {
			21 => { on_ice => [ [33,43,20,23,52,35], [17,38,40,3,29,1] ]},
		},
        200921217 => { 138 => 0, },
        201020146 => { 311 => { player1 => 39, servedby => 26, }, },
		201020596 => { 275 => 0, },
		201020989 => { 346 => { reason => 'GOALIE STOPPED', description => 'GOALIE STOPPED', }, },
        201120094 => { 198 => { reason => 'GOALIE STOPPED', description => 'GOALIE STOPPED', }, },
		201120110 => {
			89 => { on_ice => [ [81,84,19,2,51,50], [27,48,17,41,35] ]},
		},
		201120553 => { 294 => {
			length => 10, penalty => 'Misconduct', misconduct => 1,
			description => 'FLA #21 BARCH Game misconduct(10 min)',
		} },
		201220341 => { 301 => 0, },
		201220018 => { 164 => {
			description => 'VAN #9 KASSIAN BLOCKED BY EDM #15 SCHULTZ, Wrist, Def. Zone', team1 => 'EDM', team2 => 'VAN',
		} },
		201320971 => {   1 => {
			id => 1, period => 1,
			time => '0:00',
			team => 'CBJ',
			strength => 'EV',
			shot_type => 'Snap',
			distance => 18,
			type => 'GOAL',
			location => 'Off',
			old => 1,
			description => 'CBJ #8 HORTON(5), A: 11 CALVERT(4); 21 WISNIEWSKI(43), Snap, 18 ft',
			team1 => 'NSH',
			player1 => 8470596,
			assist1 => 8476485,
			assist2 => 8470222,
			on_ice => [ [], [], ],
			special => 1, en => 0, gwg => 0,
		} },
		201321046 => { 295 => 0 },
		201321139 => {
			13 => { on_ice => [ [51,89,57,19,84,30], [8,19,88,7,61,31] ]},
		},
        201420600 => { 328 => 0 },
        201420921 => { 354 => { reason => 'GOALIE STOPPED', description => 'GOALIE STOPPED', }, },
		201521197 => {
			27 => { on_ice => [ [ 21,10,15,5,6,1 ], [18,57,52,3,33,37] ] },
		},
		201621127 => { 311 => { description => 'BOS #55 ACCIARI Misconduct(10 min), Def. Zone' }},
		201621229 => {
			178 => { on_ice => [[15,21,73,6,53,32], [50,10,2,53,1]]},
		},
		201820009 => {
			231 => { servedby => 12 },
		},
		201820151 => {
			332 => { player1 => 18 },
		},
		201820296 => {
			123 => { on_ice => [[27,90,22,13,3,1], [90,13,17,42,77,30]]},
		},
		201821133 => { 58 => { team1 => 'TBL' } },

	},
);

our %MISSING_PLAYER_INFO = (
	8452484 => {
		height => q{5' 11"},
		weight => 175,
	},
	8462118 => {
		number => 10,
	},
	8452019 => {
		number => 18,
	},
	8459424 => {
		number => 44,
	},
	8470615 => {
		city => q{Quebec City},
	},
);

our %MISSING_PS_GOALIES = (
	200920081 => [ 8475094, 8470320 ],
	200920583 => [ 8468254, 8460705 ],
	201321202 => [ 8473434, 8474636 ],
	201620785 => [ 8475660, 8471219 ],
);

our %BROKEN_TIMES = (

);

our %BROKEN_COORDS = (

);

our %BROKEN_PENALTIES = (
#	2005206450108 => {
#		time => '00:24', ts => 1224,
#	},
);
our %BROKEN_CHALLENGES = (
	2017209570302 => {
		team => 'NHL', coach_name => 'NHL', type => 'i', result => 1,
		source => 'CHL', winner => 'EDM', loser => 'LAK', ignore_stop => 1,
	},
	2018200850336 => {
		team => 'NHL', coach_name => 'NHL', type => 'i', result => 0,
		source => 'STOP', winner => 'BUF', loser => 'VGK',
	},
	2015210190291 => {
		team => 'NHL', coach_name => 'NHL', type => 'i', result => 0,
		source => 'STOP', winner => 'DET', loser => 'NYR',
	},
	2015210160299 => {
		team => 'NHL', coach_name => 'NHL', type => 'i', result => 0,
		source => 'STOP', winner => 'CHI', loser => 'DAL',
	},
	2015210070307 => {
		team => 'NHL', coach_name => 'NHL', type => 'i', result => 0,
		source => 'STOP', winner => 'CAR', loser => 'BOS',
	},
	2015205350262 => {
		team => 'BUF', coach_name => 'DAN BYLSMA', type => 'i', result => 0,
		source => 'CHL', winner => 'WSH', loser => 'BUF', ignore_stop => 1,
	},
	2017211900271 => {
		team => 'TBL', coach_name => 'JON COOPER', type => 'i', result => 0,
		source => 'STOP', winner => 'BOS', loser => 'TBL',
	},
	2017208360170 => {
		team => 'CGY', coach_name => 'GLEN GULUTZAN', type => 'i', result => 0,
		source => 'CHL', winner => 'NYR', loser => 'CGY', ignore_stop => 1,
	},
	2017201890230 => {
		team => 'TBL', coach_name => 'JON COOPER', type => 'i', result => 0,
		source => 'CHL', winner => 'NYR', loser => 'TBL', ignore_stop => 1,
	},
	2017201230277 => {
		team => 'TOR', coach_name => 'MIKE BABCOCK', type => 'i', result => 0,
		source => 'CHL', winner => 'LAK', loser => 'TOR', ignore_stop => 1,
	},
	2017200600114 => {
		team => 'COL', coach_name => 'JARED BEDNAR', type => 'i', result => 0,
		source => 'STOP', winner => 'ANA', loser => 'COL',
	},
	2016210320070 => {
		team => 'SJS', coach_name => 'PETER DEBOER', type => 'i', result => 0,
		source => 'CHL', winner => 'BUF', loser => 'SJS',
	},
	2016209780128 => {
		team => 'CAR', coach_name => 'BILL PETERS', type => 'i', result => 0,
		source => 'STOP', winner => 'COL', loser => 'CAR',
	},
	2016208930139 => {
		team => 'BOS', coach_name => 'BRUCE CASSIDY', type => 'i', result => 0,
		source => 'STOP', winner => 'ANA', loser => 'BOS',
	},
	2016207730057 => {
		team => 'WPG', coach_name => 'PAUL MAURICE', type => 'i', result => 0,
		source => 'STOP', winner => 'COL', loser => 'WPG',
	},
	2015210500012 => {
		team => 'WPG', coach_name => 'PAUL MAURICE', type => 'i', result => 0,
		source => 'STOP', winner => 'CGY', loser => 'WPG',
	},
	2015210350172 => {
		team => 'STL', coach_name => 'KEN HITCHCOCK', type => 'i', result => 0,
		source => 'STOP', winner => 'CGY', loser => 'STL',
	},
	2015208820256 => {
		team => 'EDM', coach_name => 'TODD MCLELLAN', type => 'i', result => 0,
		source => 'STOP', winner => 'COL', loser => 'EDM',
	},
	2015203720197 => {
		team => 'TBL', coach_name => 'JON COOPER', type => 'i', result => 0,
		source => 'STOP', winner => 'ANA', loser => 'TBL',
	},
	2015203540004 => {
		team => 'FLA', coach_name => 'GERARD GALLANT', type => 'i', result => 0,
		source => 'STOP', winner => 'DET', loser => 'FLA',
	},
	2015201750084 => {
		team => 'MTL', coach_name => 'MICHEL THERRIEN', type => 'i', result => 9,
		source => 'STOP', winner => 'OTT', loser => 'MTL',
	},
	2015201630254 => {
		team => 'CGY', coach_name => 'BOB HARTLEY', type => 'i', result => 0,
		source => 'STOP', winner => 'EDM', loser => 'CGY',
	},
	2015201460188 => {
		team => 'TOR', coach_name => 'MIKE BABCOCK', type => 'i', result => 0,
		source => 'STOP', winner => 'NYR', loser => 'TOR',
	},
	2015200490219 => {
		team => 'ARI', coach_name => 'DAVE TIPPETT', type => 'i', result => 0,
		source => 'STOP', winner => 'ANA', loser => 'ARI',
	},
	2015200180152 => {
		team => 'BOS', coach_name => 'CLAUDE JULIEN', type => 'i', result => 0,
		source => 'STOP', winner => 'MTL', loser => 'BOS',
	},
	2017209700056 => {
		team => 'NJD', coach_name => 'JOHN HYNES', type => 'i', result => 0,
		source => 'CHL', winner => 'PIT', loser => 'NJD',
	},
	2017205810111 => {
		team => 'MIN', coach_name => 'BRUCE BOUDREAU', type => 'i', result => 1,
		source => 'CHL', winner => 'MIN', loser => 'NSH',
	},
	2016210080010 => {
		team => 'NJD', coach_name => 'JOHN HYNES', type => 'o', result => 0,
		source => 'CHL', winner => 'ARI', loser => 'NJD',
	},
	2015205870239 => {
		team => 'VAN', coach_name => 'WILLIE DESJARDINS', type => 'o', result => 1,
		source => 'CHL', winner => 'VAN', loser => 'ARI',
	},
	2015204600156 => {
		team => 'VAN', coach_name => 'WILLIE DESJARDINS', type => 'o', result => 0,
		source => 'CHL', winner => 'MIN', loser => 'VAN',
	},
	2015205189999 => {
		team => 'CBJ', coach_name => 'JOHN TORTORELLA', type => 'o', result => 0,
		source => 'CHL', winner => 'TBL', loser => 'CBJ', ts => 1613, t => 1,
	},
	2015204030041 => {
		team => 'PIT', coach_name => 'MIKE SULLIVAN', type => 'o', result => 1,
		source => 'STOP', winner => 'PIT', loser => 'ANA',
	},
	2015201180025 => {
		team => 'MIN', coach_name => 'MIKE YEO', type => 'o', result => 0,
		source => 'STOP', winner => 'WPG', loser => 'MIN',
	},
	2015206730339 => {
		team   => 'NHL', coach_name => 'NHL', type => 'o', result => 1,
		source => 'CHL', winner => 'NYR', loser => 'WSH', ts => 3545
	},
	2016204380148 => 0,
	2016200680065 => 0,
);

our %BROKEN_ON_ICE_COUNT = (
	1999200430025 => 5151, # 0 ps
	1999202030010 => 5141,
	1999202640020 => 5141, # 1 ps
	1999203020003 => 5151, # 1 ps
	1999203500015 => 5151, # 1 ps
	1999205530026 => 5151, # 0 ps
	1999205720021 => 5141,
	1999205790003 => 5151, # 1 ps
	1999205870022 => 5151, # 1 ps
	1999205920026 => 5151, # 1 ps
	1999206340012 => 5151, # 1 ps
	2000202490017 => 3151,
	2000204390010 => 4151,
	2000207070031 => 4151,
	2000209770018 => 4141,
	2000210580023 => 5131,
	2001201190026 => 4151,
	2001202120026 => 4151,
	2001206490021 => 4151,
	2001207200017 => 5131,
	2001209520037 => 4151,
	2002202980106 => 5131,
	2002204380161 => 4151,
	2002207010143 => 4141,
	2002212210120 => 5141,
	2003200660145 => 4151,
	2003200730133 => 5151,
	2003203170200 => 3151,
	2003206080071 => 5151,
	2003209730123 => 5131,
	2005200250170 => 5151,
	2005200290266 => 3151,
	2005205930091 => 5141,
	2005206180118 => 5131,
	2005206450116 => 5141,
	2005208410100 => 4151,
	2005208480072 => 4151,
	2005209240121 => 5141,
	2005210840086 => 3151,
	2005211810098 => 5151,
	2006201500036 => 4151,
	2006202970214 => 5141,
	2006206270025 => 5151,
	2006207940313 => 3151,
	2006208190182 => 5141,
	2006303140144 => 5131,
	2007200240089 => 5151,
	2007200920284 => 5131,
	2007201810192 => 4141, # strange
	2007210880075 => 3141, # strange
	2007207420158 => 3151,
	2007207780111 => 5141,
	2007209690292 => 5151,
	2007209770132 => 5141,
	2008200640220 => 4141, #
	2008203010286 => 5151,
	2008203570228 => 5151,
	2008204300331 => 5151,
	2008208220193 => 3141,
	2008208580256 => 5141,
	2008208810268 => 5151, # clarkson penalty timing
	2009201110037 => 4151,
	2009203150076 => 5141,
	2009212060253 => 4141,
	2010200150075 => 5151,
	2010201210293 => 5151,
	2010203290047 => 3151,
	2010203550281 => 5151,
	2011201610154 => 5151,
	2011201870306 => 5151,
	2011201930112 => 5141,
	2012201720366 => 4141,
	2012206160272 => 5150,
	2013200330275 => 5151,
	2013202500273 => 6051,
	2013202790185 => 4141,
	2013206020299 => 5141,
	2013208960196 => 5151,
	2013210260126 => 3151,
	2013211190119 => 5151,
	2013301750181 => 5151,
	2013303150305 => 5141,
	2014203310323 => 5141,
	2014205450305 => 5141,
	2015206250044 => 5151,
	2015207430252 => 5141,
	2015208290238 => 5131,
	2015208990183 => 5141,
	2015211780282 => 5151,
	2016201390301 => 5151,
	2016203420313 => 5151,
	2016211690127 => 5151,
	2018201690267 => 5141,
	2018206330221 => 5151,
	2018210740203 => 5151,
);

our $INCOMPLETE = -1;
our $REPLICA    = -2;
our $BROKEN     = -3;
our $NO_EVENTS  = -4;
our $UNSYNCHED  = -5;

our %BROKEN_FILES = (
	191730211 => { BS => $UNSYNCHED},
	191730212 => { BS => $UNSYNCHED},
	191730213 => { BS => $UNSYNCHED},
	191730214 => { BS => $UNSYNCHED},
	191730215 => { BS => $UNSYNCHED},
	191830211 => { BS => $UNSYNCHED},
	191830212 => { BS => $UNSYNCHED},
	191830213 => { BS => $UNSYNCHED},
	191830214 => { BS => $UNSYNCHED},
	191830215 => { BS => $UNSYNCHED},
	191930211 => { BS => $UNSYNCHED},
	191930212 => { BS => $UNSYNCHED},
	191930213 => { BS => $UNSYNCHED},
	191930214 => { BS => $UNSYNCHED},
	191930215 => { BS => $UNSYNCHED},
	192130211 => { BS => $UNSYNCHED},
	192130212 => { BS => $UNSYNCHED},
	192130213 => { BS => $UNSYNCHED},
	192130214 => { BS => $UNSYNCHED},
	192130215 => { BS => $UNSYNCHED},
	192430311 => { BS => $UNSYNCHED},
	192430312 => { BS => $UNSYNCHED},
	192430313 => { BS => $UNSYNCHED},
	192430314 => { BS => $UNSYNCHED},
	192530311 => { BS => $UNSYNCHED},
	192530312 => { BS => $UNSYNCHED},
	192530313 => { BS => $UNSYNCHED},
	192530314 => { BS => $UNSYNCHED},
	195220105 => { BS => $NO_EVENTS },
	195320012 => { BS => $NO_EVENTS },
	196320003 => { BS => $NO_EVENTS },
	196720356 => { BS => $NO_EVENTS },
	197320520 => { BS => $NO_EVENTS },
	197520138 => { BS => $NO_EVENTS },
	197520379 => { BS => $NO_EVENTS },
	197620012 => { BS => $NO_EVENTS },
	197720070 => { BS => $NO_EVENTS },
	197720469 => { BS => $NO_EVENTS },
	197820577 => { BS => $NO_EVENTS },
	197920370 => { BS => $NO_EVENTS },
	197920492 => { BS => $NO_EVENTS },
	198220019 => { BS => $NO_EVENTS },
	198520534 => { BS => $NO_EVENTS },
	198520592 => { BS => $NO_EVENTS },
	198620125 => { BS => $NO_EVENTS },
	198620163 => { BS => $NO_EVENTS },
	198630152 => { BS => $NO_EVENTS },
	199020225 => { BS => $NO_EVENTS },
	199020623 => { BS => $NO_EVENTS },
	199120627 => { BS => $NO_EVENTS },
	199220004 => { BS => $NO_EVENTS },
	199220082 => { BS => $NO_EVENTS },
	199220242 => { BS => $NO_EVENTS },
	199320538 => { BS => $NO_EVENTS },
	199520135 => { BS => $NO_EVENTS },
	199720946 => { BS => $NO_EVENTS },
	199920029 => { ES => $REPLICA, GS => $REPLICA },
	199920045 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920050 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920058 => { ES => $REPLICA, GS => $REPLICA },
	199920071 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920072 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920081 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920109 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920130 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920323 => { ES => $REPLICA, GS => $REPLICA },
	199920619 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920689 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199920690 => { ES => $BROKEN, GS => $INCOMPLETE },
	199920836 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	199921034 => { BH => $INCOMPLETE, ES => $INCOMPLETE, GS => $INCOMPLETE },
	199930325 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020029 => { ES => $REPLICA, GS => $REPLICA },
	200020038 => { ES => $REPLICA, GS => $REPLICA },
	200020039 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020041 => { ES => $REPLICA, GS => $REPLICA },
	200020042 => { ES => $REPLICA, GS => $REPLICA },
	200020043 => { ES => $REPLICA, GS => $REPLICA },
	200020044 => { ES => $REPLICA, GS => $REPLICA },
	200020045 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020049 => { ES => $REPLICA, GS => $REPLICA },
	200020067 => { ES => $REPLICA, GS => $REPLICA },
	200020072 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020073 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020077 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020080 => { ES => $REPLICA, GS => $REPLICA },
	200020081 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020083 => { ES => $REPLICA, GS => $REPLICA },
	200020085 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020095 => { ES => $REPLICA, GS => $REPLICA },
	200020096 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020102 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020112 => { ES => $REPLICA, GS => $REPLICA },
	200020186 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020187 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020189 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020920 => { ES => $REPLICA, GS => $REPLICA },
	200020916 => { PL => $INCOMPLETE },
	200020921 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020924 => { ES => $REPLICA, GS => $REPLICA },
	200020925 => { ES => $REPLICA, GS => $REPLICA },
	200020926 => { ES => $REPLICA, GS => $REPLICA },
	200020928 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020964 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200020983 => { ES => $BROKEN },
	200021165 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200021166 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200021167 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200021171 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200120012 => { BS => $NO_EVENTS },
	200120974 => { BS => $NO_EVENTS },
	200220396 => { BS => $NO_EVENTS },
	200220414 => { BS => $NO_EVENTS },
	200220645 => { BS => $NO_EVENTS },
	200220916 => { PL => $INCOMPLETE },
	200320191 => { GS => $INCOMPLETE },
	200320257 => { BS => $NO_EVENTS },
	200321205 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $INCOMPLETE },
	200330134 => { PL => $BROKEN },
	200520298 => { ES => $REPLICA },
	200520458 => { ES => $BROKEN },
	200520677 => { RO => $BROKEN },
	200520679 => { RO => $BROKEN },
	200520681 => { RO => $BROKEN },
	200621024 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, },
	200621024 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, },
	200720262 => { BS => $NO_EVENTS, },
	200720470 => { GS => $INCOMPLETE, },
	200720483 => { GS => $INCOMPLETE, },
	200721178 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, RO => $INCOMPLETE, TV => $INCOMPLETE, TH => $INCOMPLETE },
	200820259 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, RO => $INCOMPLETE },
	200820409 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, RO => $INCOMPLETE },
	200821077 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, RO => $INCOMPLETE },
	200920081 => { ES => $INCOMPLETE, GS => $INCOMPLETE, PL => $BROKEN, RO => $INCOMPLETE },
	200920827 => { GS => $INCOMPLETE },
	200920836 => { GS => $INCOMPLETE },
	200920857 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200920863 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	200920874 => { ES => $INCOMPLETE, GS => $INCOMPLETE, RO => $INCOMPLETE },
	200920885 => { ES => $INCOMPLETE, RO => $INCOMPLETE },
	201020429 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	201020575 => { BS => $NO_EVENTS },
	201020704 => { BS => $NO_EVENTS },
	201120259 => { ES => $INCOMPLETE, GS => $INCOMPLETE },
	201320338 => { BS => $NO_EVENTS },
	201320971 => { GS => $BROKEN },
#	201520079 => {BH => $INCOMPLETE},
#	201520120 => {BH => $INCOMPLETE},
#	201520168 => {BH => $INCOMPLETE},
#	201520214 => {BH => $INCOMPLETE},
#	201520307 => {BH => $INCOMPLETE},
	201520476 => { BS => $NO_EVENTS },
	201720639 => { BS => $NO_EVENTS },
	201830312 => { TV => $INCOMPLETE, TH => $INCOMPLETE },
);

our %MANUAL_FIX = (
	200120123 => { GS => 'Remove "2" throughout the file' },
	200120059 => { ES => 'Remove invalid html tags' },
	200520094 => {
		GS => 'Insert missing period for 15:35 penalty',
		PL => 'Edited string with 00:28 penalty',
	},
	200520305 => { GS => 'Insert missing period for 5:13 penalty' },
	200520233 => { GS => 'Add missing TBODY closing tag' },
	200520264 => { GS => 'Fixed bogus on ice' },
	200620071 => { PL => 'Aligned period for event #1' },
	200620892 => { GS => 'Add missing TBODY closing tag' },
	201320331 => { PL => 'Remove invalid tag at the 7:50 event' },
	201720463 => { PL => 'Fixed time -16:0-1' },
);
our %BROKEN_HEADERS = (
	200720295 => {
		location => 'Scottrade Center',
	},
);

our %SPECIAL_EVENTS = (
	200520312 => { 0  => 1 },
	201320971 => { 0  => 1 },
);

our %MISSING_EVENTS = (
	198930176 => [
		{
			type => 'GOAL',
			period => 5,
			time => '03:14',
			team1 => 'LAK',
			assist1 => 8446494,
			player1 => 8448566,
			strength => 'EV',
			shot_type => 'Unknown',
			distance => 999,
			location => 'Off',
		},
	],
	199020456 => [
		{
			type => 'PENL',
			period => 4,
			time => '03:41',
			player1 => 8448449,
			team1 => 'BUF',
			length => 2,
			penalty => 'Holding',
			strength => 'EV',
			location => 'Unk',
		},
	],
	199030242 => [
		{
			type => 'GOAL',
			period => 5,
			time => '04:48',
			team1 => 'EDM',
			player1 => 8448490,
			assist1 => 8451905,
			assist2 => 8449020,
			shot_type => 'Unknown',
			distance => 999,
			location => 'Off',
			strength => 'EV',
		},
	],
	199030243 => [
		{
			type => 'GOAL',
			period => 5,
			time => '00:48',
			team1 => 'EDM',
			player1 => 8451905,
			assist1 => 8448490,
			assist2 => 8448641,
			shot_type => 'Unknown',
			distance => 999,
			location => 'Off',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '00:48',
			player1 => 8450941,
			team1 => 'LAK',
			length => 10,
			penalty => 'Misconduct',
			misconduct => 1,
			strength => 'EV',
			location => 'Unk',
		},
	],
	199130002 => [
		{
			type => 'PENL',
			period => 5,
			time => '00:48',
			player1 => 8450941,
			team1 => 'LAK',
			length => 10,
			penalty => 'Misconduct',
			misconduct => 1,
			strength => 'EV',
			location => 'Unk',
		},
	],
	199130117 => [
		{
			type => 'GOAL',
			time => '05:26',
			period => 5,
			team1 => 'MTL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8446208,
			assist1 => 8446167,
			assist2 => 8446415,
		},
	],
	199130163 => [
		{
			type => 'GOAL',
			time => '03:33',
			period => 5,
			team1 => 'STL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8448091,
			assist1 => 8445281,
			assist2 => 8451793,
		},
	],
	199230142 => [
		{
			type => 'GOAL',
			time => '14:50',
			period => 5,
			team1 => 'NYI',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449742,
			assist1 => 8446823,
			assist2 => 8446838,
		},
	],
	199230144 => [
		{
			type => 'GOAL',
			time => '05:40',
			period => 5,
			team1 => 'NYI',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8446823,
			assist1 => 8448870,
			assist2 => 8446830,
		},
	],
	199230231 => [
		{
			type => 'GOAL',
			time => '03:16',
			period => 5,
			team1 => 'TOR',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8447206,
			assist1 => 8447187,
			assist2 => 8449009,
		},
	],
	199230232 => [
		{
			type => 'GOAL',
			time => '03:03',
			period => 5,
			team1 => 'STL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8445700,
			assist1 => 8446675,
			assist2 => 8448222,
		},
	],
	199230245 => [
		{
			type => 'GOAL',
			time => '06:31',
			period => 5,
			team1 => 'LAK',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8458020,
			assist1 => 8450941,
			assist2 => 8448569,
		},
	],
	199230312 => [
		{
			type => 'GOAL',
			time => '06:21',
			period => 5,
			team1 => 'MTL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8448719,
			assist1 => 8446303,
			assist2 => 8445739,
		},
	],
	199330136 => [
		{
			type => 'GOAL',
			time => '05:43',
			period => 7,
			team1 => 'BUF',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8447515,
			assist1 => 8458549,
			assist2 => 8450523,
		},
		{
			type => 'PENL',
			period => 6,
			time => '00:00',
			player1 => 8450678,
			team1 => 'BUF',
			length => 10,
			penalty => 'Misconduct',
			misconduct => 1,
			strength => 'EV',
			location => 'Unk',
		},
		{
			type => 'PENL',
			period => 6,
			time => '12:10',
			player1 => $BENCH_PLAYER_ID,
			team1 => 'NJD',
			length => 2,
			penalty => 'Too many men/ice',
			strength => 'EV',
			location => 'Unk',
			servedby => 8450825,
		},
	],
	199330167 => [
		{
			type => 'GOAL',
			time => '02:20',
			period => 5,
			team1 => 'VAN',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8455738,
			assist1 => 8445700,
			assist2 => 8445208,
		},
	],
	199330311 => [
		{
			type => 'GOAL',
			time => '15:23',
			period => 5,
			team1 => 'NJD',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8450825,
			assist1 => 8445977,
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:14',
			player1 => 8451905,
			team1 => 'NYR',
			length => 2,
			penalty => 'Unsportsmanlike conduct',
			strength => 'EV',
			location => 'Unk',
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:14',
			player1 => 8445461,
			team1 => 'NYR',
			length => 2,
			penalty => 'Roughing',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:14',
			player1 => 8448772,
			team1 => 'NJD',
			length => 2,
			penalty => 'Unsportsmanlike conduct',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:14',
			player1 => 8450825,
			team1 => 'NJD',
			length => 2,
			penalty => 'Roughing',
			location => 'Unk',
			strength => 'EV',
		},
	],
	199330313 => [
		{
			type => 'GOAL',
			time => '06:13',
			period => 5,
			team1 => 'NYR',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449295,
		},
	],
	199330317 => [
		{
			type => 'GOAL',
			time => '04:24',
			period => 5,
			team1 => 'NYR',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449295,
			assist1 => 8451905,
		},
	],
	199330325 => [
		{
			type => 'GOAL',
			time => '00:14',
			period => 5,
			team1 => 'VAN',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8444894,
			assist1 => 8445208,
			assist2 => 8448825,
		},
	],
	199430167 => [
		{
			type => 'GOAL',
			time => '01:54',
			period => 5,
			team1 => 'SJS',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8458537,
			assist1 => 8448669,
			assist2 => 8449163,
		},
	],
	199430323 => [
		{
			type => 'GOAL',
			time => '09:25',
			period => 5,
			team1 => 'DET',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8456870,
			assist1 => 8446789,
		},
	],
	199430325 => [
		{
			type => 'GOAL',
			time => '02:25',
			period => 5,
			team1 => 'DET',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8456887,
			assist1 => 8446788,
			assist2 => 8445730,
		},
	],
	199530124 => [
		{
			type => 'GOAL',
			time => '19:15',
			period => 7,
			team1 => 'PIT',
			strength => 'PP',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449807,
			assist1 => 8458494,
			assist2 => 8448208,
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:33',
			player1 => 8458179,
			team1 => 'PIT',
			length => 2,
			penalty => 'Roughing',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '04:33',
			player1 => 8445575,
			team1 => 'WSH',
			length => 2,
			penalty => 'Roughing',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 6,
			time => '03:24',
			player1 => 8448380,
			team1 => 'PIT',
			length => 2,
			penalty => 'Slashing',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 6,
			time => '04:36',
			player1 => 8446181,
			team1 => 'WSH',
			length => 2,
			location => 'Unk',
			penalty => 'Tripping - Obstruction',
			strength => 'PP',
		},
		{
			type => 'PENL',
			period => 6,
			time => '19:17',
			player1 => 8456150,
			team1 => 'PIT',
			length => 2,
			penalty => 'Slashing',
			location => 'Unk',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 7,
			time => '17:21',
			player1 => 8448303,
			team1 => 'WSH',
			length => 2,
			penalty => 'Hooking',
			location => 'Unk',
			strength => 'EV',
		},
	],
	199530174 => [
		{
			type => 'GOAL',
			time => '10:02',
			period => 6,
			team1 => 'CHI',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449751,
			assist1 => 8446217,
		},
	],
	199530215 => [
		{
			type => 'GOAL',
			time => '08:05',
			period => 5,
			team1 => 'FLA',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8447985,
			assist1 => 8451427,
			assist2 => 8448092,
		},
	],
	199530237 => [
		{
			type => 'GOAL',
			time => '01:15',
			period => 5,
			team1 => 'DET',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8452578,
			assist1 => 8456870,
		},
	],
	199530244 => [
		{
			type => 'GOAL',
			time => '04:33',
			period => 6,
			team1 => 'COL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8451101,
			assist1 => 8447363,
			assist2 => 8450817,
		},
		{
			type => 'PENL',
			period => 5,
			time => '19:38',
			player1 => 8448772,
			location => 'Unk',
			team1 => 'COL',
			length => 2,
			penalty => 'Roughing',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '19:38',
			player1 => 8450561,
			location => 'Unk',
			team1 => 'CHI',
			length => 2,
			penalty => 'Cross checking',
			strength => 'PP',
		},
	],
	199530246 => [
		{
			type => 'GOAL',
			time => '05:18',
			period => 5,
			team1 => 'COL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8458544,
			assist1 => 8456770,
			assist2 => 8451101,
		},
	],
	199530414 => [
		{
			type => 'GOAL',
			time => '04:31',
			period => 6,
			team1 => 'COL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8448554,
		},
		{
			type => 'PENL',
			period => 5,
			time => '09:57',
			player1 => 8448772,
			team1 => 'COL',
			location => 'Unk',
			length => 2,
			penalty => 'Roughing',
			strength => 'EV',
		},
		{
			type => 'PENL',
			period => 5,
			time => '09:57',
			player1 => 8451427,
			team1 => 'FLA',
			length => 2,
			location => 'Unk',
			penalty => 'Slashing',
			strength => 'EV',
		},
	],
	199630114 => [
		{
			type => 'GOAL',
			time => '07:37',
			period => 6,
			team1 => 'MTL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8445739,
			assist1 => 8459442,
			assist2 => 8445734,
		},
	],
	199630153 => [
		{
			type => 'GOAL',
			time => '11:03',
			period => 5,
			team1 => 'CHI',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8458949,
			assist1 => 8446295,
		},
		{
			type => 'PENL',
			location => 'Unk',
			period => 5,
			time => '06:09',
			player1 => 8452353,
			team1 => 'CHI',
			length => 2,
			penalty => 'Holding',
			strength => 'EV',
		},
		{
			type => 'PENL',
			location => 'Unk',
			period => 5,
			time => '06:09',
			player1 => 8450561,
			team1 => 'CHI',
			length => 10,
			penalty => 'Misconduct',
			misconduct => 1,
			strength => 'EV',
		},
	],
	199630165 => [
		{
			type => 'GOAL',
			time => '00:22',
			period => 5,
			team1 => 'EDM',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8460496,
			assist1 => 8459429,
			assist2 => 8458963,
		},
	],
	199630242 => [
		{
			type => 'GOAL',
			time => '01:31',
			period => 6,
			team1 => 'DET',
			strength => 'PP',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8456887,
			assist1 => 8456870,
			assist2 => 8446789,
		},
		{
			type => 'PENL',
			period => 6,
			time => '01:03',
			player1 => 8446286,
			location => 'Unk',
			team1 => 'ANA',
			length => 2,
			penalty => 'Hooking',
			strength => 'EV',
		},
	],
	199630244 => [
		{
			type => 'GOAL',
			time => '17:03',
			period => 5,
			team1 => 'DET',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8451302,
			assist1 => 8458524,
			assist2 => 8452578,
		},
		{
			type => 'PENL',
			period => 5,
			time => '10:52',
			player1 => 8446789,
			location => 'Unk',
			team1 => 'DET',
			length => 2,
			penalty => 'Hi-sticking',
			strength => 'EV',
		},
	],
	199720894 => [
		{
			id => 999,
			type => 'GOAL',
			period => 4,
			time => '04:39',
			location => 'Off',
			team1 => 'PHI',
			shot_type => 'Unknown',
			strength => 'EV',
			player1 => 8457704,
			assist1 => 8456849,
			assist2 => 8459458,
		},
	],
	199730142 => [
		{
			type => 'GOAL',
			time => '00:54',
			period => 5,
			team1 => 'BOS',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8459249,
			assist1 => 8459439,
			assist2 => 8448484,
		},
	],
	199730143 => [
		{
			type => 'GOAL',
			time => '06:31',
			period => 5,
			team1 => 'WSH',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8456760,
			assist1 => 8449951,
			assist2 => 8445417,
		},
	],
	199730223 => [
		{
			type => 'GOAL',
			time => '01:24',
			period => 5,
			team1 => 'BUF',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8458976,
			assist1 => 8458347,
			assist2 => 8460579,
		},
	],
	199730243 => [
		{
			type => 'GOAL',
			time => '11:12',
			period => 5,
			team1 => 'DET',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8451302,
			assist1 => 8448669,
			assist2 => 8457063,
		},
	],
	199830122 => [
		{
			type => 'GOAL',
			time => '10:35',
			period => 5,
			team1 => 'BUF',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8459534,
			assist1 => 8458454,
			assist2 => 8456760,
		},
	],
	199830135 => [
		{
			type => 'GOAL',
			time => '14:45',
			period => 5,
			team1 => 'BOS',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8459156,
			assist1 => 8466138,
			assist2 => 8445621,
		},
	],
	199830154 => [
		{
			type => 'GOAL',
			time => '17:34',
			period => 6,
			team1 => 'DAL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8449893,
			assist1 => 8458494,
			assist2 => 8445423,
		},
		{
			type => 'PENL',
			period => 6,
			time => '07:46',
			player1 => 8459640,
			team1 => 'EDM',
			location => 'Unk',
			length => 2,
			penalty => 'Boarding',
			strength => 'EV',
		},
	],
	199830416 => [
		{
			type => 'GOAL',
			time => '14:51',
			period => 6,
			team1 => 'DAL',
			strength => 'EV',
			location => 'Off',
			shot_type => 'Unknown',
			distance => 999,
			player1 => 8448091,
			assist1 => 8459024,
			assist2 => 8449645,
		},
	],
	200210427 => [
		{
			'period' => 3,
			'team' => 'PHI',
			'str' => 'EV',
			'player2' => 8465200,
			'penalty' => 'Game Misconduct',
			'length' => '10',
			'id' => 143,
			'location' => 'Unk',
			'type' => 'PENL',
			'description' => '97 ROENICK, Charging (maj), 5 min, Served By 29 FEDORUK',
			'old' => 1,
			'team2' => 'TOR',
			'team1' => 'PHI',
			'time' => '07:33',
			'player1' => 8459078,
			servedby => 8462292,
			misconduct => 1,
		},
	],
);

our %MISSING_COACHES = (
	198720094 => [
		'Terry Simpson',
		'John Brophy',
	],
	198720190 => [
		"Terry O'Reilly",
		'Dan Maloney',
	],
	198820044 => [
		"Terry O'Reilly",
		'Pierre Page',
	],
	198820695 => [
		'George Armstrong',
		'Larry Pleau',
	],
	199220021 => [
		'John Muckler',
		'Paul Holmgren',
	],
	200220148 => [
		'Andy Murray',
		'Brian Sutter',
	],
	200320732 => [
		'Peter Laviolette',
		'Bob Hartley',
	],
);

our %MISSING_PLAYERS = (
	192330311 => [
		[
			{
				_id       => 8400001,
				position  => 'G',
				decision  => 'L',
				timeOnIce => '60:00',
				name      => 'CHARLIE REID',
				number    => 1,
				pim       => 0,
				goals     => 0,
				assists   => 0,
			},
		],
		[],
	],
	192330312 => [
		[
			{
				_id       => 8400001,
				position  => 'G',
				decision  => 'L',
				timeOnIce => '60:00',
				name      => 'CHARLIE REID',
				number    => 1,
				pim       => 0,
				goals     => 0,
				assists   => 0,
			},
		],
		[],
	],
	199920450 => [
		[
			{
				_id => 8459457,
				number => 15,
				position  => 'L',
				timeOnIce => '00:27',
				name      => 'JAMIE LANGENBRUNNER',
				penaltyMinutes       => 0,
				goals     => 0,
				assists   => 0,
				missing => 1,
			}
		],
		[],
	],
);

our %BROKEN_ROSTERS = (
	198720509 => [ [], [ { 'No.' => 0, number => 30 } ], ],
	199020353 => [ [], [ { 'No.' => 0, number => 30 } ], ],
	199020696 => [ [], [ { 'No.' => 0, number => 35 } ], ],
	199120656 => [ [], [ { 'No.' => 16, penaltyMinutes => 4 }, ], ],
	199120753 => [ [ { 'No.' => 26, penaltyMinutes => 7 }, ], [], ],
	199120809 => [ [ { 'No.' => 5, penaltyMinutes => 2 }, ], [], ],
	199120839 => [ [ { 'No.' => 11, penaltyMinutes => 12 }, ], [], ],
	199120877 => [ [ { 'No.' => 27, penaltyMinutes => 18 }, ], [], ],
	199220449 => [ [ { 'No.' => 29, penaltyMinutes => 18 }, ], [], ],
	199220585 => [ [], [ { 'No.' => 39, penaltyMinutes => 17 }, ], ],
	199320044 => [ [ { 'No.' => 26, penaltyMinutes => 4 }, ], [], ],
	199320074 => [ [ { 'No.' => 27, penaltyMinutes => 4 }, ], [], ],
	199320404 => [ [ { 'No.' => 29, penaltyMinutes => 19 }, ], [], ],
	199320499 => [ [], [ { 'No.' => 32, penaltyMinutes => 2 }, ], ],
	199320640 => [ [], [ { 'No.' => 12, penaltyMinutes => 6 }, ], ],
	199520048 => [ [ { 'No.' => 12, penaltyMinutes => 2, }, ], [], ],
	199520790 => [ [ { 'No.' => 12, penaltyMinutes => 6, }, ], [], ],
	199530123 => [ [], [ { 'No.' => 23, penaltyMinutes => 14, }, ], ],
	199620473 => [ [ { 'No.' => 27, penaltyMinutes => 2, }, ], [], ],
	199620546 => [ [ { 'No.' => 17, penaltyMinutes => 2, }, ], [], ],
	199620548 => [ [ { 'No.' => 33, penaltyMinutes => 23 }, ], [], ],
	199620927 => [ [
		{ 'No.' => 20, penaltyMinutes => 2, },
		{ 'No.' => 77, penaltyMinutes => 2, },
	], [], ],
	199630222 => [ [], [ { 'No.' => 18, penaltyMinutes => 2, }, ], ],
	199720830 => [ [], [ { 'No.' => 35, 'EV' => '10 - 12' }, ], ],
	199720876 => [ [], [ { 'No.' => 27, 'EV' => '11 - 14' }, ], ],
	199720997 => [ [ { 'No.' => 31, 'SH' => '3 - 3' }, ], [], ],
	199820004 => [ [], [ { 'No.' => 34, 'EV' => '26 - 28' }, ], ],
	199820061 => [ [], [ { 'No.' => 35, 'EV' => '19 - 20' }, ], ],
	200320027 => [ [], [ { 'No.' => 29, 'name' => 'JAMIE MCLENNAN' }, ], ],
	200520312 => [ [ { 'No.' => 7, error => 1 } ], [] ],
);

our %BROKEN_PLAYER_IDS = (8445204 => 8445202);

our %BROKEN_SHIFTS = (
	200820160 => { MIN => {  8 => 1 } },
	200920439 => { MTL => { 36 => 1 } },
	201520508 => { ANA => {  5 => 1 } },
);

=head1 NAME

Sport::Analytics::NHL::Errors - Hard fixes to errors in the NHL reports

=head1 SYNOPSYS

Hard fixes to errors in the NHL reports

Provides hard-coded corrections to the errors in the NHL reports or marks certain files as broken and unoperatable

This list shall expand as the release grows.

    use Sport::Analytics::NHL::Errors;
    # TBA

=cut

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Errors>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Errors


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Errors>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Errors>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Errors>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Errors>

=back

