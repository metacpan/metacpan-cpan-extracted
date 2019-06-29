package Sport::Analytics::NHL::Config;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';
use Sport::Analytics::NHL::Vars qw($CURRENT_SEASON);

=head1 NAME

Sport::Analytics::NHL::Config - NHL-related configuration settings

=head1 SYNOPSYS

NHL-related configuration settings

Provides NHL-related settings such as first and last season, teams, available reports, and so on.

This list shall expand as the release grows.

    use Sport::Analytics::NHL::Config;
    print "The first active NHL season is $FIRST_SEASON\n";

=cut

our $FIRST_SEASON               = 1917;
our $ORIGINAL_SIX_ERA_START     = 1942;
our $FIRST_DETAILED_PENL_SEASON = 1947;
our $EXPANSION_ERA_START        = 1967;
our $FOUR_ROUND_PO_START        = 1974;
our $WHA_MERGER                 = 1979;
our $FIRST_ROUND_IN_SEVEN       = 1986;
our $GOAL_HAS_ON_ICE            = 1999;

our @LOCKOUT_SEASONS = qw(2004);

our %DEFAULTED_GAMES = (
	191720035 => 1,
	191720036 => 1,
);
our %TEAMS = (
	MWN => {
		defunct => 1,
		long    => [],
		short   => [],
		founded => $FIRST_SEASON,
		folded  => $FIRST_SEASON+1,
		full    => [('Montreal Wanderers')],
	},
	MMR => {
		defunct => 1,
		long    => [],
		short   => [],
		founded => 1924,
		folded  => 1938,
		full    => [('Montreal Maroons')],
	},
	BRK => {
		defunct => 1,
		long => [],
		short => ['NYA'],
		timeline => {
			NYA => [1925,1940],
			BRK => [1941,1941],
		},
		founded => 1925,
		folded  => 1942,
		full => [('Brooklyn Americans', 'New York Americans')],
	},
	PIR => {
		long => [],
		defunct => 1,
		founded => 1925,
		folded  => 1931,
		short => ['QUA'],
		timeline => {
			PIR => [1925,1929],
			QUA => [1930,1930],
		},
		full => [('Pittsburgh Pirates', 'Philadelphia Quakers')],
	},
	VMA => {
		defunct => 1,
		long => [],
		short => ['VMI'],
		full => [('Vancouver Maroons', 'Vancouver Millionaires')],
	},
	MET => {
		long => [],
		defunct => 1,
		short => [qw(SEA SMT)],
		full => [('Seattle Metropolitans')],
	},
	VIC => {
		long => [],
		defunct => 1,
		short => [],
		full => [('Victoria Cougars')],
	},
	HAM => {
		defunct => 1,
		long => [],
		short => ['QBD', 'QAL'],
		timeline => {
			QAL => [1919, 1919],
			HAM => [1920, 1924],
		},
		founded => 1919,
		folded => 1925,
		full => [('Hamilton Tigers', 'Quebec Bulldogs', 'Quebec Athletics')],
	},
	CAT => {
		defunct => 1,
		long => [],
		short => [],
		full => [('Calgary Tigers')],
	},
	EDE => {
		defunct => 1,
		long => [],
		short => [],
		full => [('Edmonton Eskimos')],
	},
	SEN => {
		defunct => 1,
		founded => $FIRST_SEASON,
		folded  => 1935,
		long => [],
		short => ['SLE'],
		full => [('Ottawa Senators (1917)', 'St. Louis Eagles')],
	},
	VGK => {
		long => [qw(Vegas Golden Knights)],
		short => [],
		founded => 2017,
		full => [('Vegas Golden Knights')],
		twitter => '@GoldenKnights',
		color => 'darkgoldenrod',
	},
	MIN => {
		long => [qw(Minnesota Wild)],
		short => [],
		founded => 2000,
		full => [('Minnesota Wild')],
		twitter => '@mnwild',
		color => 'darkgreen',
	},
	WPG => {
		long => [qw(Winnipeg Jets Thrashers)],
		short => [qw(ATL)],
		founded => 1999,
		full => [('Winnipeg Jets', 'Atlanta Thrashers')],
		twitter => '@NHLJets',
		color => 'blue3',
	},
	NJD => {
		long => [qw(Devils Rockies Scouts), 'New Jersey'],
		short => [qw(CLR KCS NJD NJ N.J)],
		founded => 1974,
		timeline => {
			CLR => [1976,1981],
			KCS => [1974,1975],
		},
		full => [('New Jersey Devils', 'Colorado Rockies', 'Kansas City Scouts')],
		twitter => '@NJDevils',
		color => 'black',
	},
	ARI => {
		long => [qw(Arizona Phoenix Coyotes), 'Jets (1979)'],
		short => [qw(PHX WIN)],
		founded => 1979,
		timeline => {
			WIN => [1979, 1995],
			PHX => [1995, 2014],
		},
		full => [('Arizona Coyotes', 'Phoenix Coyotes', 'Winnipeg Jets (1979)')],
		twitter => '@ArizonaCoyotes',
		color => 'DebianRed',
	},
	PIT => {
		long => [qw(Pittsburgh Penguins)],
		short => [qw()],
		founded => 1967,
		full => [('Pittsburgh Penguins')],
		twitter => '@penguins',
		color => 'gold2',
	},
	VAN => {
		long => [qw(Vancouver Canucks)],
		short => [qw()],
		founded => 1970,
		full => [('Vancouver Canucks')],
		twitter => '@Canucks',
		color => 'cyan3',
	},
	NYI => {
		long => [qw(Islanders), 'NY Islanders'],
		short => [qw()],
		founded => 1972,
		full => [('New York Islanders')],
		twitter => '@NYIslanders',
		color => 'sandybrown',
	},
	CBJ => {
		long => [qw(Columbus Blue Jackets), 'Blue Jackets'],
		short => [qw(CBS)],
		founded => 2000,
		full => [('Columbus Blue Jackets')],
		twitter => '@BlueJacketsNHL',
		color => 'blueviolet',
	},
	ANA => {
		long => [qw(Anaheim Ducks)],
		short => [qw()],
		founded => 1993,
		full => [('Anaheim Ducks', 'Mighty Ducks Of Anaheim')],
		twitter => '@AnaheimDucks',
		color => 'orange',
	},
	PHI => {
		long => [qw(Philadelphia Flyers)],
		short => [qw()],
		founded => 1967,
		full => [('Philadelphia Flyers')],
		twitter => '@NHLFlyers',
		color => 'chartreuse2',
	},
	CAR => {
		long => [qw(Carolina Hurricanes Whalers)],
		short => [qw(HFD)],
		founded => 1979,
		timeline => {
			HFD => [1979, 1996],
		},
		full => [('Carolina Hurricanes', 'Hartford Whalers')],
		twitter => '@NHLCanes',
		color => 'tomato',
	},
	NYR => {
		long => [qw(Rangers), 'NY Rangers'],
		short => [qw()],
		founded => 1926,
		full => [('New York Rangers')],
		twitter => '@NYRangers',
		color => 'steelblue',
	},
	CGY => {
		long => [qw(Calgary Flames)],
		short => [qw(AFM)],
		founded => 1972,
		full => [('Calgary Flames', 'Atlanta Flames')],
		timeline => {
			AFM => [1972, 1979],
		},
		twitter => '@NHLFlames',
		color => 'coral1',
	},
	BOS => {
		long => [qw(Boston Bruins)],
		short => [qw()],
		founded => 1924,
		full => [('Boston Bruins')],
		twitter => '@NHLBruins',
		color => 'yellow1',
	},
	CLE => {
		defunct => 1,
		founded => 1967,
		folded  => 1978,
		long => [qw(Barons Seals)],
		timeline => {
			CSE => [1966, 1966],
			OAK => [1967, 1969],
			CGS => [1970, 1975],
		},
		short => [qw(CSE OAK CGS CBN)],
		full => [('Cleveland Barons', 'California Golden Seals', 'Oakland Seals')],
	},
	EDM => {
		long => [qw(Edmonton Oilers)],
		short => [qw()],
		founded => 1979,
		full => [('Edmonton Oilers')],
		twitter => '@EdmontonOilers',
		color => 'wheat1',
	},
	MTL => {
		long => [qw(Canadiens Montreal)],
		short => [qw(MON)],
		founded => $FIRST_SEASON,
		full => [('Montreal Canadiens', 'Montréal Canadiens', 'Canadiens de Montreal', 'Canadiens Montreal', 'Canadien De Montreal')],
		twitter => '@CanadiensMTL',
		color => 'maroon',
	},
	STL => {
		long => [qw(Blues)],
		short => [qw()],
		founded => 1967,
		full => [('St. Louis Blues', 'St.Louis Blues', 'St Louis', 'ST Louis Blues')],
		twitter => '@StLouisBlues',
		color => 'moccasin',
	},
	TOR => {
		long => [qw(Toronto Maple Leafs), 'Maple Leafs'],
		short => [qw(TAN TSP)],
		timeline => {
			TAN => [1917, 1918],
			TSP => [1919, 1926],
		},
		founded => $FIRST_SEASON,
		full => [('Toronto Maple Leafs', 'Toronto Arenas', 'Toronto St. Patricks')],
		twitter => '@MapleLeafs',
		color => 'dodgerblue1',
	},
	FLA => {
		long => [qw(Florida Panthers)],
		short => [qw(FLO)],
		founded => 1993,
		full => [('Florida Panthers')],
		twitter => '@FlaPanthers',
		color => 'olivedrab',
	},
	BUF => {
		long => [qw(Buffalo Sabres)],
		short => [qw()],
		founded => 1970,
		full => [('Buffalo Sabres')],
		twitter => '@BuffaloSabres',
		color => 'greenyellow',
	},
	NSH => {
		long => [qw(Nashville Predators)],
		short => [qw()],
		founded => 1998,
		full => [('Nashville Predators')],
		twitter => '@PredsNHL',
		color => 'darkkhaki',
	},
	SJS => {
		long => [qw(San Jose Sharks), 'San Jose'],
		short => [qw(SJS S.J SJ)],
		founded => 1991,
		full => [('San Jose Sharks')],
		twitter => '@SanJoseSharks',
		color => 'teal',
	},
	COL => {
		long => [qw(Nordiques Colorado Avalanche)],
		short => [qw(QUE)],
		founded => 1979,
		timeline => {
			QUE => [1979, 1994],
		},
		full => [('Colorado Avalanche', 'Quebec Nordiques')],
		twitter => '@Avalanche',
		color => 'mediumvioletred',
	},
	DAL => {
		long => ['North Stars', qw(Dallas Stars)],
		founded => 1967,
		short => [qw(MNS MINS)],
		timeline => {
			MNS => [ 1967, 1992],
		},
		full => [('Dallas Stars', 'Minnesota North Stars')],
		twitter => '@DallasStars',
		color => 'mediumseagreen',
	},
	OTT => {
		long => [qw(Senators)],
		short => [qw()],
		founded => 1992,
		full => [('Ottawa Senators')],
		twitter => '@Senators',
		color => 'pink',
	},
	LAK => {
		long => [qw(Kings), 'Los Angeles'],
		short => [qw(LAK L.A LA)],
		founded => 1967,
		full => [('Los Angeles Kings')],
		twitter => '@LAKings',
		color => 'grey',
	},
	TBL => {
		long => [qw(Lightning), 'Tampa Bay'],
		founded => 1992,
		short => [qw(TBL T.B TB)],
		full => [('Tampa Bay Lightning')],
		twitter => '@TBLightning',
		color => 'LightSkyBlue3',
	},
	DET => {
		long => [qw(Detroit Red Wings)],
		short => [qw(DCG DFL)],
		founded => 1926,
		timeline => {
			DCG => [1926, 1929],
			DFL => [1930, 1931],
		},
		full => [('Detroit Red Wings', 'Detroit Cougars', 'Detroit Falcons')],
		twitter => '@DetroitRedWings',
		color => 'red1',
	},
	CHI => {
		long => [('Blackhawks', 'Black Hawks', 'Chicago')],
		short => [qw()],
		founded => 1926,
		full => [('Chicago Blackhawks', 'Chicago Black Hawks')],
		twitter => '@NHLBlackhawks',
		color => 'orangered',
	},
	WSH => {
		long => [qw(Washington Capitals)],
		short => [qw(WAS)],
		founded => 1974,
		full => [('Washington Capitals')],
		twitter => '@Capitals',
		color => 'darkslategray',
	},
);

our %TEAM_FULL_NAMES = (
	TAN => 'Toronto Arenas',
	TSP => 'Toronto St. Patricks',
	QAL => 'Quebec Athletics',
	MWN => 'Montreal Wanderers',
	MMR => 'Montreal Maroons',
	BRK => 'Brooklyn Americans',
	NYA => 'New York Americans',
	PIR => 'Pittsburgh Pirates',
	QUA => 'Philadelphia Quakers',
	VMA => 'Vancouver Maroons',
	VMI => 'Vancouver Millionaires',
	MET => 'Seattle Metropolitans',
	SEA => 'Seattle Metropolitans',
	VIC => 'Victoria Cougars',
	HAM => 'Hamilton Tigers',
	QBD => 'Quebec Bulldogs',
	CAT => 'Calgary Tigers',
	EDE => 'Edmonton Eskimos',
	DCG => 'Detroit Cougars',
	DFL => 'Detroit Falcons',
	CLR => 'Colorado Rockies',
	SEN => 'Ottawa Senators (1917))',
	SLE => 'St. Louis Eagles',
	MIN => 'Minnesota Wild',
	WPG => 'Winnipeg Jets',
	ATL => 'Atlanta Thrashers',
	NJD => 'New Jersey Devils',
	CLR => 'Colorado Rockies',
	KCS => 'Kansas City Scouts',
	WIN => 'Winnipeg Jets (1979)',
	PHX => 'Phoenix Coyotes',
	ARI => 'Arizona Coyotes',
	PIT => 'Pittsburgh Penguins',
	VAN => 'Vancouver Canucks',
	NYI => 'New York Islanders',
	CBJ => 'Columbus Blue Jackets',
	ANA => {
		2005    => 'Mighty Ducks Of Anaheim',
		default => 'Anaheim Ducks',
	},
	PHI => 'Philadelphia Flyers',
	CAR => 'Carolina Hurricanes',
	HFD => 'Hartford Whalers',
	NYR => 'New York Rangers',
	CGY => 'Calgary Flames',
	AFM => 'Atlanta Flames',
	BOS => 'Boston Bruins',
	CBN => 'Cleveland Barons',
	CSE => 'California Golden Seals',
	CGS => 'California Golden Seals',
	OAK => 'Oakland Seals',
	EDM => 'Edmonton Oilers',
	MTL => 'Montreal Canadiens',
	STL => 'St. Louis Blues',
	TOR => 'Toronto Maple Leafs',
	FLA => 'Florida Panthers',
	BUF => 'Buffalo Sabres',
	NSH => 'Nashville Predators',
	SJS => 'San Jose Sharks',
	COL => 'Colorado Avalanche',
	QUE => 'Quebec Nordiques',
	DAL => 'Dallas Stars',
	MNS => 'Minnesota North Stars',
	OTT => 'Ottawa Senators',
	LAK => 'Los Angeles Kings',
	TBL => 'Tampa Bay Lightning',
	CHI => {
		1984 => 'Chicago Black Hawks',
		default => 'Chicago Blackhawks',
	},
	DET => 'Detroit Red Wings',
	WSH => 'Washington Capitals',
	VGK => 'Vegas Golden Knights',
);

our %FIRST_REPORT_SEASONS = (
	BS => $FIRST_SEASON,
	#PB => 2010,
	GS => 1999,
	ES => 1999,
	TV => 2007,
	TH => 2007,
	PL => 2002,
	RO => 2005,
);

our $MAIN_GAME_FILE      = 'BS.json';
our $SECONDARY_GAME_FILE = 'BS.html';

our $REGULAR = 2;
our $PLAYOFF = 3;

our $UNKNOWN_PLAYER_ID = 8000000;
our $BENCH_PLAYER_ID   = 8000001;
our $COACH_PLAYER_ID   = 8000002;
our $EMPTY_NET_ID      = 8000003;
our $UNKNOWN_SERVEDBY  = 8010000;

our %VOCABULARY = (
	penalty     => {
		'3 MINUTE MINOR'                               => [],
		'ABUSE OF OFFICIALS'                           => [
			'ABUSE OF OFFICIASL',
		],
		'ABUSIVE LANGUAGE'                             => [],
		'ABUSIVE LANGUAGE - GAME'                      => [],
		'AGGRESSOR'                                    => [],
		'ATTEMPT TO/DELIBERATE INJURY - MATCH PENALTY' => [
			'ATTEMPT TO/DELIBERATE INJURY',
			'ATTEMPT TO INJURE',
			'MATCH - ATTEMPT TO INJURE',
			'ATTEMPT TO/DELIBERATE INJURY (MAT)',
			'MATCH PENALTY',
		],
		'BENCH'                                        => [],
		'BOARDING'                                     => [ 'BOARD CHECK' ],
		'BUTT ENDING'                                  => [],
		'CHARGING'                                     => [],
		'CHECKING FROM BEHIND'                         => [],
		'CLIPPING'                                     => [],
		'CLOSING HAND ON PUCK'                         => [ 'DELAYING GAME - SMOTHERING PUCK' ],
		'COACH/MGR ON ICE'                             => [
			'COACG OR MANAGER ON THE ICE',
			'COACH OR MANAGER ON THE ICE',
		],
		'CONCEALING PUCK'                              => [],
		'COVERING PUCK IN CREASE'                      => [ 'COVERING PACK IN CREASE' ],
		'CROSS CHECKING',                              => [ 'CROSS CHECK' ],
		'DELAYING GAME - FACE - OFF VIOLATION'         => [
			'DELAYING THE GAME - FACE - OFF VIOLATION',
			'DELAY GM - FACE-OFF VIOLATION',
			'FACE-OFF VIOLATION',
		],
		'DELAYING GAME - ILL. PLAY GOALIE'             => [
			'DELAYING GAME - ILLEGAL PLAY BY GOALIE',
			'DELAYING GAME - ILLEGAL PLAY BY GOALKEEPER',
			'DELAY GAME - ILLEGAL PLAY GOAL',
			'DELAYING GAME-ILL. PLAY GOALIE',
		],
		'DELAYING GAME - PUCK OVER GLASS'              => [
			'DELAY GAME - PUCK OVER GLASS',
			'DELAYING GAME-PUCK OVER GLASS',
		],
		'DELAYING THE GAME'                            => [ 'DELAYING GAME', 'DELAY OF GAME' ],
		'DIVING'                                       => [
			'UNSPORTSMANLIKE CONDUCT DIVING',
			'EMBELLISHMENT',
		],
		'ELBOWING'                                     => [],
		'FIGHTING'                                     => [ 'FIGHTING (MAJ)' ],
		'GAME MISCONDUCT'                              => [],
		'GAME MISCONDUCT - TEAM STAFF'                 => [],
		'GAME MISCONDUCT - HEAD COACH'                 => [ 'GAME MISCONDUCT - HEAD' ],
		'GOALIE LEAVE CREASE'                          => [],
		"GOALIE PARTICIPAT'N BYD CENTER"               => [
			'GOALIE PARTICIPATION BEYOND CENTER',
			'GOALKEEPER PARTICIPATION BEYOND CENTER',
		],
		'GOALKEEPER DISPLACED NET'                     => [],
		'GROSS MISCONDUCT'                             => [
			'20 MINUTE MATCH',
		],
		'HEAD BUTTING'                                 => [],
		'HEAD BUTTING - GAME'                          => [],
		'HI-STICKING'                                  => [
			'HI STICK',
		],
		'HOLDING'                                      => [],
		'HOLDING ON BREAKAWAY'                         => [],
		'HOLDING THE STICK'                            => [ 'HOLDING STICK' ],
		'HOLDING STICK ON BREAKAWAY'                   => [],
		HOOKING                                        => [],
		'HOOKING ON BREAKAWAY'                         => [],
		'ILLEGAL EQUIPMENT'                            => [],
		'ILLEGAL STICK'                                => [ 'BROKEN STICK' ],
		'ILLEGAL SUBSTITUTION'                         => [],
		'ILLEGAL CHECK TO HEAD'                        => [],
		'INELIGIBLE PLAYER'                            => [],
		'INSTIGATOR'                                   => [],
		'INSTIGATOR - FACE SHIELD'                     => [],
		'INSTIGATOR - MISCONDUCT'                      => [],
		'INTERFERENCE'                                 => [],
		'INTERFERENCE ON GOALKEEPER'                   => [
			'INTERFERENCE - GOALKEEPER',
			'INTERFERENCE - GOALTENDER',
			'INTERFERENCE-ON THE GOALTENDER'
		],
		'INTERFERE W/ OFFICIAL'                        => [ 'INTERFERENCE WITH OFFICIAL' ],
		'KICKING'                                      => [],
		'KNEEING'                                      => [],
		'LATE ON ICE'                                  => [],
		'LEAVING PENALTY BOX'                          => [],
		'LEAVING PLAYER\'S/PENALTY BENCH'              => [
			'PLAYER LEAVES BENCH',
			'PLAYERS LEAVING BENCH',
		],
		'MATCH - DELIBERATE INJURY'                    => [ 'DELIBERATE INJURY' ],
		'MISCONDUCT'                                   => [ 'MISCONDUCT (10 MIN)' ],
		'NET DISPLACED'                                => [],
		'NOT PROC. TO DRESS.RM.'                       => [
			'NOT PROCEDING TO DRESSING ROOM',
			'NOT PROCEEDING TO DRESSING ROOM',
		],
		'NOT PROCEEDING DIR PEN/BOX'                   => [ 'NOT PROCEEDING DIRECTLY TO PENALTY BOX' ],
		'OBJECTS ON ICE'                               => [],
		'PICKING UP PUCK IN CREASE'                    => [],
		'PUCK THROWN FWD - GOALKEEPER'                 => [ 'PUCK THROWN FORWARD - GOALKEEPER' ],
		'REFUSAL TO PLAY'                              => [],
		'REMOVING SWEATER'                             => [],
		ROUGHING                                       => [],
		SLASHING                                       => [],
		'SLASH ON BREAKAWAY'                           => [],
		'SPEARING'                                     => [],
		'THROWING OBJECT ON ICE'                       => [],
		'THROW OBJECT AT PUCK'                         => [
			'THOW OBJECT AT PU{',
			'THOW OBJECT AT PUCK',
		],
		'THROWING STICK'                               => [],
		'TOO MANY MEN/ICE'                             => [ 'TOO MANY MEN/ICE - BENCH', 'TOO MANY MEN ON THE ICE' ],
		TRIPPING                                       => [],
		'TRIPPING ON BREAKAWAY'                        => [],
		'UNNECESSARY ROUGHNESS'                        => [],
		'UNSPORTSMANLIKE CONDUCT'                      => [],
		'UNSPORTSMANLIKE CONDUCT - COACH'              => [],
		'UNKNOWN'                                      => [
			'PENALTY SHOT',
			'MAJOR',
			'MINOR',
		],
		'ABUSIVE LANGUAGE - MISCONDUCT'                => [],
	},
	stopreason => {
		'CHALLENGE AWAY: OFF-SIDE'              => [ 'CHLG VIS - OFF-SIDE' ],
		'CHALLENGE HOME: OFF-SIDE'              => [ 'CHLG HM - OFF-SIDE' ],
		'CHALLENGE LEAGUE: OFF-SIDE'            => [ 'CHLG LEAGUE - OFF-SIDE' ],
		'CHALLENGE LEAGUE: GOALIE INTERFERENCE' => [ 'CHLG LEAGUE- GOAL INTERFERENCE' ],
		'CHALLENGE HOME: GOALIE INTERFERENCE'   => [ 'CHLG HM - GOAL INTERFERENCE', ],
		'CHALLENGE AWAY: GOALIE INTERFERENCE'   => [ 'CHLG VIS - GOAL INTERFERENCE' ],
		'GOALIE STOPPED'                        => [],
		'HIGH STICK'                            => [],
		'HOME TIMEOUT'                          => [ 'TIME OUT - HOME' ],
		ICING                                   => [],
		OFFSIDE                                 => [],
		'OFFSIDES PASS'                         => [],
		'PUCK IN NETTING'                       => [],
		'PUCK IN CROWD'                         => [],
		'REFEREE OR LINESMAN'                   => [
			'OFFICIAL INJURY',
			'REFEREE',
			'LINESMAN',
		],
		'TV TIMEOUT'                            => [],
		'PUCK FROZEN'                           => [],
		'NET OFF POST'                          => [ 'NET OFF' ],
		'VISITOR TIMEOUT'                       => [ 'TIME OUT - VISITOR' ],
		'HAND PASS'                             => [],
		'PREMATURE SUBSTITUTION'                => [],
		'INJURY'                                => [ 'PLAYER INJURY' ],
		'RINK REPAIR'                           => [ 'ICE PROBLEM' ],
		'OBJECTS ON ICE'                        => [],
		'CLOCK PROBLEM'                         => [],
		UNKNOWN                                 => [],
		'PUCK IN BENCHES'                       => [],
		'INVALID SHOOTOUT EVENT: ICING'         => [],
		'NET OFF'                               => [],
		'VIDEO REVIEW'                          => [],
		'PLAYER EQUIPMENT'                      => [],
		'SWITCH SIDES'                          => [],
	},
	miss        => {
		WIDE     => [ 'WIDE OF NET' ],
		CROSSBAR => [ 'HIT CROSSBAR' ],
		OVER     => [ 'OVER NET' ],
		GOALPOST => [],
		UNKNOWN  => [ '' ],
	},
	shot_type   => {
		SLAP          => [ 'SLAP SHOT' ],
		SNAP          => [ 'SNAP SHOT' ],
		WRIST         => [ 'WRIST SHOT' ],
		BACKHAND      => [],
		'TIP-IN'      => [],
		UNKNOWN       => [ '', ' ' ],
		'WRAP-AROUND' => [],
		DEFLECTED     => [],
	},
	strength    => {
		'EV' => [ 'EVEN' ],
		'PP' => [ 'PPG' ],
		'SH' => [ 'SHG' ],
		'PS' => [],
		'XX' => [ '', ' ' ],
	},
	events      => {
		BLOCK => [ 'BLOCKED_SHOT' ],
		CHL   => [ 'CHALLENGE' ],
		FAC   => [ 'FACEOFF' ],
		GEND  => [ 'GAME_END' ],
		GIVE  => [ 'GIVEAWAY' ],
		GOAL  => [],
		HIT   => [],
		MISS  => [ 'MISSED_SHOT' ],
		PEND  => [ 'PERIOD_END' ],
		PENL  => [ 'PENALTY', 'FIGHT' ],
		PSTR  => [ 'PERIOD_START' ],
		SHOT  => [],
		STOP  => [],
		TAKE  => [ 'TAKEAWAY' ],
	},
);

our %DATA_BY_SEASON = (
	attendance  => {season => 1999, source => 'html', descr => 'Game Attendance' },
	coordinates => {season => 2010, source => 'json', descr => 'Event Coordinates' },
	location    => {season => 1997, source => 'json', descr => 'Game Venue' },
	officials   => {season => 1923, source => 'json', descr => 'Game Officials' },
	on_ice      => {season => 2007, source => 'html', descr => 'On-Ice data (goals - 1999 in GS)' },
	pb_list     => {season => 0, source => 'json', descr => 'Penalty Box'},
	periods     => {season => 2010, source => 'json', descr => 'Period data, inconsistent before that' },
	severity    => { season => 2010, source => 'json', descr => 'Explicit penalty severity' },
	shot_types  => { season => 2002, source => 'html', descr => 'Shot Types' },
	stars       => { season => 1998, source => 'html', descr => 'Stars of the game'},
	strength    => { season => 1998, source => 'html', descr => 'Event Team Strength' },
);

our %STAT_RECORD_FROM = (
	assists                 => $FIRST_SEASON,
	goals                   => $FIRST_SEASON,
	number                  => $FIRST_SEASON,
	penaltyMinutes          => $FIRST_SEASON,
	pim                     => $FIRST_SEASON,
	timeOnIce               => $FIRST_SEASON,
	shots                   => 1959,
	plusMinus               => 1959,
	powerPlayGoals          => 1933,
	powerPlayAssists        => 1933,
	saves                   => 1955,
	sa                      => 1955,
	shortHandedGoals        => 1933,
	shortHandedAssists      => 1933,
	evenSaves               => 1997,
	evenShotsAgainst        => 1997,
	evenTimeOnIce           => 1997,
	faceoffTaken            => 1997,
	faceOffWins             => 1997,
	powerPlaySaves          => 1997,
	powerPlayShotsAgainst   => 1997,
	powerPlayTimeOnIce      => 1997,
	shortHandedSaves        => 1997,
	shortHandedShotsAgainst => 1997,
	shortHandedTimeOnIce    => 1997,
	start                   => 2003,
	blocked                 => 2010, # 1998 in html
	giveaways               => 2010, # 1998 not in html
	hits                    => 2010, # 1998 in html
	takeaways               => 2010, # 1998 in html
);

our %REASONABLE_EVENTS = (
	old => 1, new => 150,
);

our %PENALTY_POSSIBLE_NO_OFFENDED = (
	'TOO MANY MEN/ICE'                => 1,
	'DELAYING THE GAME'               => 1,
	'ABUSE OF OFFICIALS'              => 1,
	'ABUSIVE LANGUAGE'                => 1,
	'NOT PROCEEDING DIR PEN/BOX'      => 1,
	'UNSPORTSMANLIKE CONDUCT'         => 1,
	'UNKNOWN'                         => 1,
	'LATE ON ICE'                     => 1,
	'ILLEGAL SUBSTITUTION'            => 1,
	'LEAVING PLAYER\'S/PENALTY BENCH' => 1,
	'OBJECTS ON ICE'                  => 1,
	'UNSPORTSMANLIKE CONDUCT - COACH' => 1,
	'GROSS MISCONDUCT'                => 1,
);

our %REVERSE_STAT = (
	HIT   => 'received_hit',
	BLOCK => 'shot_blocked',
	PENL  => 'drew_penalty',
	GOAL  => 'goals_against',
);

our $LAST_PLAYOFF_GAME_INDEX = 417;

our $UNDRAFTED_PICK = 300;
our %CONFIG;

our @EXPORT = qw(
);

our @basic = qw($LEAGUE_NAME @STAGES $REGULAR $PLAYOFF $LAST_PLAYOFF_GAME_INDEX);
our @files =
	qw($MAIN_GAME_FILE $SECONDARY_GAME_FILE);
our @icing =
	qw($ICING_GOOD $ICING_NEUTRAL $ICING_BAD $ICING_DISASTER $ICING_TIMEOUT);
our @ids = qw(
	$UNKNOWN_PLAYER_ID $BENCH_PLAYER_ID $COACH_PLAYER_ID $EMPTY_NET_ID
	$UNKNOWN_SERVEDBY
);
our @vocabularies = qw(
	%VOCABULARY %LOCATION_ALIAS %PENALTY_POSSIBLE_NO_OFFENDED %REVERSE_STAT
);
our @seasons = qw(
	$FIRST_SEASON @LOCKOUT_SEASONS %FIRST_REPORT_SEASONS $GOAL_HAS_ON_ICE
	$ORIGINAL_SIX_ERA_START $EXPANSION_ERA_START $WHA_MERGER
	$FOUR_ROUND_PO_START $FIRST_ROUND_IN_SEVEN $FIRST_DETAILED_PENL_SEASON
	%DATA_BY_SEASON %STAT_RECORD_FROM get_games_per_season
	$LATE_START_IN_2012
);

our @league = qw(
	%DEFAULTED_GAMES %ZERO_EVENT_GAMES %TEAMS @PO_SCHEME %SEASONS
	%TEAM_FULL_NAMES $UNDRAFTED_PICK %REASONABLE_EVENTS
);

our @EXPORT_OK = (
	@basic, @files, @icing, @ids, @seasons, @league, @vocabularies
);
our %EXPORT_TAGS = (
	basic        => [ @basic        ],
	files        => [ @files        ],
	icing        => [ @icing        ],
	ids          => [ @ids          ],
	league       => [ @league       ],
	seasons      => [ @seasons      ],
	vocabularies => [ @vocabularies ],
	all          => [   @EXPORT_OK  ],
);

our @STAGES       = ($REGULAR, $PLAYOFF);

our $ICING_GOOD     =  1;
our $ICING_NEUTRAL  =  0;
our $ICING_BAD      = -1;
our $ICING_DISASTER = -2;
our $ICING_TIMEOUT  = 30;

our $LATE_START_IN_2012 = 1367330000;
our %LOCATION_ALIAS = (
	'HP PAVILION AT SAN JOSE' => 'SAP CENTER AT SAN JOSE',
	'WACHOVIA CENTER'         => 'WELLS FARGO CENTER',
	'MCI CENTER'              => 'CAPITAL ONE CENTER',
	'GENERAL MOTORS PLACE'    => 'ROGERS ARENA',
	'TAMPA BAY TIMES FORUM'   => 'AMALIE ARENA',
	'ST. PETE TIMES FORUM'    => 'AMALIE ARENA',
	'O2'                      => 0,
	'SAVVIS CENTER'           => 'SCOTTRADE CENTER',
	"LEVI'S STADIUM"          => 0,
	'CITIZENS BANK PARK'      => 0,
	'HEINZ FIELD'             => 0,
	'COREL CENTRE'            => 'CANADIAN TIRE CENTRE',
	'SCOTIABANK PLACE'        => 'CANADIAN TIRE CENTRE',
	'GLOBE'                   => 0,
	'GAYLORD ENTERTAINMENT CENTER' => 'BRIDGESTONE ARENA',
	'SOMMET CENTER'           => 'BRIDGESTONE ARENA',
	'TCF BANK STADIUM'        => 0,
	'YANKEE STADIUM'          => 0,
	'DODGER STADIUM'          => 0,
	'OFFICE DEPOT CENTER'     => 'BB&T CENTER',
	'BANKATLANTIC CENTER'     => 'BB&T CENTER',
	'SKYREACH CENTRE'         => 'REXALL PLACE',
	'COMMONWEALTH STADIUM'    => 0,
	'GLOBE ARENA'             => 0,
	'COORS FIELD'             => 0,
	'WRIGLEY FIELD'           => 0,
	'SOLDIER FIELD'           => 0,
	'MCMAHON STADIUM'         => 0,
	'PENGROWTH SADDLEDOME'    => 'SCOTIABANK SADDLEDOME',
	'ERICSSON GLOBE'          => 0,
	'RBC CENTER'              => 'PNC ARENA',
	'RALPH WILSON STADIUM'    => 0,
	'BLUE CROSS ARENA, ROCH. N.Y.' => 0,
	'HSBC ARENA'              => 'KEYBANK CENTER',
	'FIRST NIAGARA CENTER'    => 'KEYBANK CENTER',
	'O2 ARENA'                => 0,
	'FLEETCENTER'             => 'TD GARDEN',
	'TD BANKNORTH GARDEN'     => 'TD GARDEN',
	'FENWAY PARK'             => 0,
	'JOBING.COM ARENA'        => 'GILA RIVER ARENA',
	'ARROWHEAD POND'          => 'HONDA CENTER',
	'ARROWHEAD POND OF ANAHEIM' => 'HONDA CENTER',
	'NAVY-MARINE CORPS MEMORIAL STADIUM' => 0,
	'BUSCH STADIUM' => 0,
	'CITI FIELD' => 0,
	'LANDSDOWNE PARK' => 0,
	'MTS CENTRE' => 'BELL MTS PLACE',
	'CONTINENTAL AIRLINES ARENA' => 'MEADOWLANDS ARENA',
	'IZOD CENTER' => 'MEADOWLANDS ARENA',
	'CONSOL ENERGY CENTER' => 'PPG PAINTS ARENA',
	'VERIZON CENTER' => 'CAPITAL ONE ARENA',
	'CAPITAL ONE CENTER' => 'CAPITAL ONE ARENA',
);

our %ZERO_EVENT_GAMES = (
	194320118 => 1,
);

our $LEAGUE_NAME = 'NHL';

our @PO_SCHEME = (
	{
		first => 1942,
		last => 1966,
		style => 'L',
		cutoff => 4,
	}, {
		first => 1967,
		last  => 1973,
		style => 'D',
		cutoff => 4,
	}, {
		first => 1974,
		last  => 1976,
		style => 'D',
		cutoff => 3,
	}, {
		first => 1977,
		last  => 1978,
		style => 'C',
		cutoff => 6,
	}, {
		first => 1979,
		last  => 1980,
		style => 'L',
		cutoff => 16,
	}, {
		first  => 1981,
		last   => 1993,
		style  => 'D',
		cutoff => 4,
	}, {
		first => 1994,
		last  => $CURRENT_SEASON,
		style => 'C',
		cutoff => 8,
	}
);

our $DEFAULT_ROUNDS_PER_SEASON = 82;

=head1 FUNCTIONS (avoid)

A couple of utility functions are defined and run.

=over 2

=item get_cache_games_per_season

Not for consumption. RTFSC.

=item get_games_per_season

Not for consumption. RTFSC.

=back

=cut

sub get_cache_games_per_season ($) {

	my $s = shift;

	return 22 if $s == 1917;
	return 18 if $s == 1918;
	return 24 if $s <= 1923;
	return 30 if $s == 1924;
	return 36 if $s == 1925;
	return 44 if $s <= 1930;
	return 48 if $s <= 1941;
	return 50 if $s <= 1945;
	return 60 if $s <= 1948;
	return 70 if $s <= 1966;
	return 74 if $s <= 1967;
	return 76 if $s <= 1969;
	return 78 if $s <= 1973;
	return 80 if $s <= 1991;
	return 84 if $s <= 1993;
	return 48 if $s == 1994;
	return  0 if $s == 2004;
	return 48 if $s == 2012;
	return $DEFAULT_ROUNDS_PER_SEASON;
}

sub get_games_per_season ($) {

	my $s = shift;
	$CONFIG{games_per_season}->{$s} ||= get_cache_games_per_season($s);
	$CONFIG{games_per_season}->{$s};
}

our %SEASONS = (
	'1917_1917' => {
		NHL => {
			NHL => [
				qw(MTL TOR SEN MWN)
			],
		},
	},
	'1918_1918' => {
        NHL => {
			NHL => [
				qw(MTL TOR SEN)
			],
        },
	},
	'1919_1923' => {
		NHL => {
			NHL => [
				qw(MTL TOR SEN HAM),
			],
		}
	},
	'1924_1924' => {
        NHL => {
			NHL => [
				qw(MTL TOR SEN MMR HAM BOS)
			],
        },
	},
	'1925_1925' => {
        NHL => {
			NHL => [
				qw(MTL TOR SEN MMR BRK PIR BOS)
			],
        },
	},
	'1926_1930' => {
		NHL => {
			'Canadian' => [
				qw(MTL TOR SEN BRK MMR),
			],
			'American' => [
				qw(NYR BOS CHI PIR DET),
			],
		}
	},
	'1931_1931' => {
        NHL => {
			'Canadian' => [
				qw(MTL TOR BRK MMR),
			],
			'American' => [
				qw(NYR BOS CHI PIR DET),
			],
        }
	},
	'1932_1935' => {
        NHL => {
			'Canadian' => [
				qw(MTL TOR BRK MMR SEN),
			],
			'American' => [
				qw(NYR BOS CHI DET),
			],
        }
	},
	'1936_1937' => {
        NHL => {
			'Canadian' => [
				qw(MTL TOR BRK MMR),
			],
			'American' => [
				qw(NYR BOS CHI DET),
			],
        }
	},
	'1938_1941' => {
        NHL => {
			NHL => [
				qw(MTL TOR CHI DET BRK NYR BOS)
			],
        },
	},
	'1942_1966' => {
        NHL => {
			NHL => [
				qw(MTL TOR CHI DET NYR BOS)
			],
        },
	},
	'1967_1969' => {
		NHL => {
			West => [
				qw(MTL TOR CHI DET NYR BOS)
			],
			East => [
				qw(STL LAK PHI DAL PIT CLE),
			],
		},
	},
	'1970_1971' => {
        NHL => {
			East => [
				qw(MTL TOR CHI DET NYR BOS BUF)
			],
			West => [
				qw(STL LAK PHI DAL PIT CLE VAN),
			],
        },
	},
	'1972_1973' => {
        NHL => {
			East => [
				qw(MTL TOR CHI DET NYR BOS BUF NYI)
			],
			West => [
				qw(STL LAK PHI DAL PIT CLE VAN CGY),
			],
        },
	},
	'1974_1977' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF TOR CBN)
			],
			Norris => [
				qw(DET LAK MTL PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Patrick => [
				qw(AFM NYI NYR PHI)
			],
			Smythe => [
				qw(CHI CLR MNS STL VAN)
			],
		},
	},
	'1978_1978' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF MNS TOR)
			],
			Norris => [
				qw(DET LAK MTL PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Patrick => [
				qw(AFM NYI NYR PHI)
			],
			Smythe => [
				qw(CHI CLR STL VAN)
			],
		},
	},
	'1979_1979' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF MNS QUE TOR)
			],
			Norris => [
				qw(DET HFD LAK MTL PIT)
			],
		},
		'Clarence Campbell' => {
			Patrick => [
				qw(AFM NYI NYR PHI WSH)
			],
			Smythe => [
				qw(CHI CLR EDM STL VAN WIN)
			],
		},
	},
	'1980_1980' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF MNS QUE TOR)
			],
			Norris => [
				qw(DET HFD LAK MTL PIT)
			],
		},
		'Clarence Campbell' => {
			Patrick => [
				qw(CGY NYI NYR PHI WSH)
			],
			Smythe => [
				qw(CHI CLR EDM STL VAN WIN)
			],
		},
	},
	'1981_1981' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF HFD MTL QUE)
			],
			Patrick => [
				qw(NYI NYR PHI PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Norris => [
				qw(CHI DET MNS STL TOR WIN)
			],
			Smythe => [
				qw(CGY CLR EDM LAK VAN)
			],
		},
	},
	'1982_1990' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF HFD MTL QUE)
			],
			Patrick => [
				qw(NJD NYI NYR PHI PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Norris => [
				qw(CHI DET MNS STL TOR)
			],
			Smythe => [
				qw(CGY EDM LAK VAN WIN)
			],
		},
	},
	'1991_1991' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF HFD MTL QUE)
			],
			Patrick => [
				qw(NJD NYI NYR PHI PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Norris => [
				qw(CHI DET MNS STL TOR)
			],
			Smythe => [
				qw(CGY EDM LAK SJS VAN WIN)
			],
		},
	},
	'1992_1992' => {
		'Prince of Wales' => {
			Adams => [
				qw(BOS BUF HFD MTL OTT QUE)
			],
			Patrick => [
				qw(NJD NYI NYR PHI PIT WSH)
			],
		},
		'Clarence Campbell' => {
			Norris => [
				qw(CHI DET MNS STL TOR TBL)
			],
			Smythe => [
				qw(CGY EDM LAK SJS VAN WIN)
			],
		},
	},
	'1993_1994' => {
		Eastern => {
			Atlantic => [
				qw(FLA NJD NYI NYR PHI TBL WSH)
			],
			Northeast => [
				qw(BOS BUF HFD MTL OTT PIT QUE)
			],
		},
		Western => {
			Central => [
				qw(CHI DAL DET STL TOR WIN)
			],
			Pacific => [
				qw(ANA CGY EDM LAK SJS VAN)
			],
		}
	},
	'1995_1995' => {
		Eastern => {
			Atlantic => [
				qw(FLA NJD NYI NYR PHI TBL WSH)
			],
			Northeast => [
				qw(BOS BUF HFD MTL OTT PIT)
			],
		},
		Western => {
			Central => [
				qw(CHI DAL DET STL TOR WIN)
			],
			Pacific => [
				qw(ANA COL CGY EDM LAK SJS VAN)
			],
		}
	},
	'1996_1996' => {
		Eastern => {
			Atlantic => [
				qw(FLA NJD NYI NYR PHI TBL WSH)
			],
			Northeast => [
				qw(BOS BUF HFD MTL OTT PIT)
			],
		},
		Western => {
			Central => [
				qw(CHI DAL DET STL TOR PHX)
			],
			Pacific => [
				qw(ANA COL CGY EDM LAK SJS VAN)
			],
		},
	},
	'1997_1997' => {
		Eastern => {
			Atlantic => [
				qw(PHI WSH NYR NJD NYI FLA TBL)
			],
			Northeast => [
				qw(BOS BUF CAR MTL OTT PIT)
			],
		},
		Western => {
			Central => [
				qw(CHI DAL DET STL TOR PHX)
			],
			Pacific => [
				qw(ANA COL CGY EDM LAK SJS VAN)
			],
		},
	},
	'1998_1998' => {
		Eastern => {
			Atlantic => [
				qw(PHI PIT NYR NJD NYI)
			],
			Northeast => [
				qw(BOS BUF TOR MTL OTT)
			],
			Southeast => [
				qw(CAR FLA TBL WSH)
			],
		},
		Western => {
			Central => [
				qw(CHI NSH DET STL)
			],
			Pacific => [
				qw(ANA DAL LAK PHX SJS)
			],
			Northwest => [
				qw(CGY COL EDM VAN)
			],
		},
	},
	'1999_1999' => {
		Eastern => {
			Atlantic => [
				qw(PHI PIT NYR NJD NYI)
			],
			Northeast => [
				qw(BOS BUF TOR MTL OTT)
			],
			Southeast => [
				qw(CAR FLA TBL WSH ATL)
			],
		},
		Western => {
			Central => [
				qw(CHI NSH DET STL)
			],
			Pacific => [
				qw(ANA DAL LAK PHX SJS)
			],
			Northwest => [
				qw(CGY COL EDM VAN)
			],
		},
	},
	'2000_2010' => {
		Eastern => {
			Atlantic => [
				qw(PHI PIT NYR NJD NYI)
			],
			Northeast => [
				qw(BOS BUF TOR MTL OTT)
			],
			Southeast => [
				qw(ATL CAR FLA TBL WSH)
			],
		},
		Western => {
			Central => [
				qw(CHI CBJ DET STL NSH)
			],
			Pacific => [
				qw(ANA DAL LAK PHX SJS)
			],
			Northwest => [
				qw(CGY COL EDM VAN MIN)
			],
		},
	},
	'2013_2013' => {
		Western => {
			Pacific => [
				qw(SJS LAK ANA PHX VAN EDM CGY)
			],
			Central => [
				qw(CHI NSH DAL MIN WPG STL COL)
			],
		},
		Eastern => {
			Metropolitan => [
				qw(PHI PIT NYR NJD NYI CBJ WSH CAR)
			],
			Atlantic => [
				qw(BOS OTT MTL TOR BUF DET TBL FLA)
			],
		},
	},
	'2011_2012' => {
		Western => {
			Pacific => [
				qw(SJS LAK ANA PHX DAL)
			],
			Northwest => [
				qw(VAN EDM CGY COL MIN)
			],
			Central => [
				qw(CHI NSH DET STL CBJ)
			],
		},
		Eastern => {
			Atlantic => [
				qw(PHI PIT NYR NJD NYI)
			],
			Northeast => [
				qw(BOS MTL OTT TOR BUF)
			],
			Southeast => [
				qw(WSH CAR TBL FLA WPG)
			],
		},
	},
	'2014_2016' => {
		Western => {
			Pacific => [
				qw(SJS LAK ANA ARI VAN EDM CGY)
			],
			Central => [
				qw(CHI NSH DAL MIN WPG STL COL)
			],
		},
		Eastern => {
			Metropolitan => [
				qw(PHI PIT NYR NJD NYI CBJ WSH CAR)
			],
			Atlantic => [
				qw(BOS OTT MTL TOR BUF DET TBL FLA)
			],
		},
	},
	'2017_2018' => {
		Western => {
			Pacific => [
				qw(SJS LAK ANA ARI VAN EDM CGY VGK)
			],
			Central => [
				qw(CHI NSH DAL MIN WPG STL COL)
			],
		},
		Eastern => {
			Metropolitan => [
				qw(PHI PIT NYR NJD NYI CBJ WSH CAR)
			],
			Atlantic => [
				qw(BOS OTT MTL TOR BUF DET TBL FLA)
			],
		},
	},
);

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Config>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Config


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Config>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Config>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Config>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Config>

=back

