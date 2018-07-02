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

our %TEAMS = (
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
		short => [],
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
	CBN => {
		defunct => 1,
		long => [qw(Barons Seals)],
		short => [qw(CSE OAK CGS)],
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

our @EXPORT = qw(
	$REGULAR $PLAYOFF
	$FIRST_SEASON @LOCKOUT_SEASONS %FIRST_REPORT_SEASONS
	$MAIN_GAME_FILE $SECONDARY_GAME_FILE
	%TEAMS
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

