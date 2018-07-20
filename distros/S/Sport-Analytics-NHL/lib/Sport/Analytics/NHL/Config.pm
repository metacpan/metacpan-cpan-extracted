package Sport::Analytics::NHL::Config;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

=head1 NAME

Sport::Analytics::NHL::Config - NHL-related configuration settings

=head1 SYNOPSYS

NHL-related configuration settings

Provides NHL-related settings such as first and last season, teams, available reports, and so on.

This list shall expand as the release grows.

    use Sport::Analytics::NHL::Config;
    print "The first active NHL season is $FIRST_SEASON\n";

=cut

our $FIRST_SEASON = 1917;
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
		full    => [('Montreal Wanderers')],
	},
	MMR => {
		defunct => 1,
		long    => [],
		short   => [],
		full    => [('Montreal Maroons')],
	},
	BRK => {
		defunct => 1,
		long => [],
		short => ['NYA'],
		full => [('Brooklyn Americans', 'New York Americans')],
	},
	PIR => {
		long => [],
		defunct => 1,
		short => ['QUA'],
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
		short => ['SEA'],
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
		short => ['QBD'],
		full => [('Hamilton Tigers', 'Quebec Bulldogs')],
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
		long => [],
		short => ['SLE'],
		full => [('Ottawa Senators (1917)', 'St. Louis Eagles')],
	},
	VGK => {
		long => [qw(Vegas Golden Knights)],
		short => [],
		full => [('Vegas Golden Knights', 'Las Vegas Golden Knights')],
	},
	MIN => {
		long => [qw(Minnesota Wild)],
		short => [],
		full => [('Minnesota Wild')],
	},
	WPG => {
		long => [qw(Winnipeg Jets Thrashers)],
		short => [qw(ATL)],
		full => [('Winnipeg Jets', 'Atlanta Thrashers')],
	},
	NJD => {
		long => [qw(Devils Rockies Scouts), 'New Jersey'],
		short => [qw(CLR KCS NJD NJ N.J)],
		full => [('New Jersey Devils', 'Colorado Rockies', 'Kansas City Scouts')],
	},
	ARI => {
		long => [qw(Arizona Phoenix Coyotes), 'Jets (1979)'],
		short => [qw(WIN PHX)],
		full => [('Arizona Coyotes', 'Phoenix Coyotes', 'Winnipeg Jets (1979)')]
	},
	PIT => {
		long => [qw(Pittsburgh Penguins)],
		short => [qw()],
		full => [('Pittsburgh Penguins')],
	},
	VAN => {
		long => [qw(Vancouver Canucks)],
		short => [qw()],
		full => [('Vancouver Canucks')],
	},
	NYI => {
		long => [qw(Islanders), 'NY Islanders'],
		short => [qw()],
		full => [('New York Islanders')],
	},
	CBJ => {
		long => [qw(Columbus Blue Jackets), 'Blue Jackets'],
		short => [qw(CBS)],
		full => [('Columbus Blue Jackets')],
	},
	ANA => {
		long => [qw(Anaheim Ducks)],
		short => [qw()],
		full => [('Anaheim Ducks', 'Mighty Ducks Of Anaheim')],
	},
	PHI => {
		long => [qw(Philadelphia Flyers)],
		short => [qw()],
		full => [('Philadelphia Flyers')],
	},
	CAR => {
		long => [qw(Carolina Hurricanes Whalers)],
		short => [qw(HFD)],
		full => [('Carolina Hurricanes', 'Hartford Whalers')],
	},
	NYR => {
		long => [qw(Rangers), 'NY Rangers'],
		short => [qw()],
		full => [('New York Rangers')],
	},
	CGY => {
		long => [qw(Calgary Flames)],
		short => [qw(AFM)],
		full => [('Calgary Flames', 'Atlanta Flames')],
	},
	BOS => {
		long => [qw(Boston Bruins)],
		short => [qw()],
		full => [('Boston Bruins')],
	},
	CLE => {
		defunct => 1,
		long => [qw(Barons Seals)],
		short => [qw(CSE OAK CGS CBN)],
		full => [('Cleveland Barons', 'California Golden Seals', 'Oakland Seals')],
	},
	EDM => {
		long => [qw(Edmonton Oilers)],
		short => [qw()],
		full => [('Edmonton Oilers')],
	},
	MTL => {
		long => [qw(Canadiens Montreal)],
		short => [qw(MON)],
		full => [('Montreal Canadiens', 'Montréal Canadiens', 'Canadiens de Montreal', 'Canadiens Montreal', 'Canadien De Montreal')],
	},
	STL => {
		long => [qw(Blues)],
		short => [qw()],
		full => [('St. Louis Blues', 'St.Louis Blues', 'St Louis', 'ST Louis Blues')],
	},
	TOR => {
		long => [qw(Toronto Maple Leafs), 'Maple Leafs'],
		short => [qw(TOR TAN TSP)],
		full => [('Toronto Maple Leafs', 'Toronto Arenas', 'Toronto St. Patricks')],
	},
	FLA => {
		long => [qw(Florida Panthers)],
		short => [qw(FLO)],
		full => [('Florida Panthers')],
	},
	BUF => {
		long => [qw(Buffalo Sabres)],
		short => [qw()],
		full => [('Buffalo Sabres')],
	},
	NSH => {
		long => [qw(Nashville Predators)],
		short => [qw()],
		full => [('Nashville Predators')],
	},
	SJS => {
		long => [qw(San Jose Sharks), 'San Jose'],
		short => [qw(SJS S.J SJ)],
		full => [('San Jose Sharks')],
	},
	COL => {
		long => [qw(Nordiques Colorado Avalanche)],
		short => [qw(QUE)],
		full => [('Colorado Avalanche', 'Quebec Nordiques')],
	},
	DAL => {
		long => ['North Stars', qw(Dallas Stars)],
		short => [qw(MNS MINS)],
		full => [('Dallas Stars', 'Minnesota North Stars')],
	},
	OTT => {
		long => [qw(Senators)],
		short => [qw()],
		full => [('Ottawa Senators')],
	},
	LAK => {
		long => [qw(Kings), 'Los Angeles'],
		short => [qw(LAK L.A LA)],
		full => [('Los Angeles Kings')],
	},
	TBL => {
		long => [qw(Lightning), 'Tampa Bay'],
		short => [qw(TBL T.B TB)],
		full => [('Tampa Bay Lightning')],
	},
	DET => {
		long => [qw(Detroit Red Wings)],
		short => [qw(DCG DFL)],
		full => [('Detroit Red Wings', 'Detroit Cougars', 'Detroit Falcons')],
	},
	CHI => {
		long => [('Blackhawks', 'Black Hawks', 'Chicago')],
		short => [qw()],
		full => [('Chicago Blackhawks', 'Chicago Black Hawks')],
	},
	WSH => {
		long => [qw(Washington Capitals)],
		short => [qw(WAS)],
		full => [('Washington Capitals')],
	},
);

our %FIRST_REPORT_SEASONS = (
	BS => $FIRST_SEASON,
	#PB => 2010,
	GS => 1999,
	ES => 1999,
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
		'FIGHTING'                                     => [],
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
			'MATCH PENALTY',
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
		'MISCONDUCT'                                   => [],
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
		'NET OFF POST'                          => [],
		'TIME OUT - VISITOR'                    => [ 'VISITOR TIMEOUT' ],
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
	attendance  => 2010,
	coordinates => 2010,
	location    => 1997,
	officials   => 2011,
	on_ice      => 2007,
	pb_list     => 2018,
	periods     => 2010,
	severity    => 2010,
	shot_types  => 2008,
	stars       => 1998,
	strength    => 1998,
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

our %PENALTY_POSSIBLE_NO_OFFENDER = (
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

our $LAST_PLAYOFF_GAME_INDEX = 417;
our $LATE_START_IN_2012      = 1367330000;

our @EXPORT = qw(
	$REGULAR $PLAYOFF $LAST_PLAYOFF_GAME_INDEX $LATE_START_IN_2012 %DEFAULTED_GAMES
	$FIRST_SEASON @LOCKOUT_SEASONS %FIRST_REPORT_SEASONS
	$MAIN_GAME_FILE $SECONDARY_GAME_FILE
	%TEAMS
	$UNKNOWN_PLAYER_ID $BENCH_PLAYER_ID $COACH_PLAYER_ID $EMPTY_NET_ID
	%VOCABULARY
	%DATA_BY_SEASON %STAT_RECORD_FROM %REASONABLE_EVENTS
	%PENALTY_POSSIBLE_NO_OFFENDER
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

