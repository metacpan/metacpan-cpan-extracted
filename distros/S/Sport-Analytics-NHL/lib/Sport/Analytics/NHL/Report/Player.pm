package Sport::Analytics::NHL::Report::Player;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Encode;
use Storable qw(dclone);

use Date::Parse;
use JSON;
use Try::Tiny;
use Text::Unidecode;

use Sport::Analytics::NHL::Util qw(:format :utils :times);
use Sport::Analytics::NHL::Tools qw(:db);
use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;

use parent qw(Sport::Analytics::NHL::Report Exporter);

=head1 NAME

Sport::Analytics::NHL::Report::Player - Class for the Player JSON report

=head1 SYNOPSYS

Class for the Boxscore JSON report.

    use Sport::Analytics::NHL::Report::Player;
    my $report = Sport::Analytics::NHL::Report::Player->new($json)
    $report->process();

=head1 METHODS

=over 2

=item C<new>

Create the Player object with the JSON.

=item C<process>

Process the Player into the object compatible with further processing, etc.

=item C<get_career_phase_index>

Get the index of a career phase - regular or playoffs

 Argument: the phase substructure of th eobject
 Returns: 0 for regular, 1 playoffs, dies otherwise

=item C<normalize_bio>

Normalize and standardize the bio parts of the NHL player report.

 Arguments: none, works on the object itself
 Returns: void, the object is modified.

=item C<normalize_career>

Normalize and standardize the career parts of the NHL player report.

 Arguments: none, works on the object itself
 Returns: void, the object is modified.

=item C<parse_bio>

Parse the bio parts of the NHL player report.

 Arguments: none, works on the object itself
 Returns: void, the object is modified.

=item C<parse_career>

Parse the career parts of the NHL player report.

 Arguments: none, works on the object itself
 Returns: void, the object is modified.

=back

=cut

our @EXPORT = qw();

our @PLAYER_FIELDS = qw(
	number birthdate height city weight draftyear shoots
	draftteam round pick name position team active rookie
);
our @COUNTRIES = (qw(
	Canada Slovakia Slovenia Yugoslavia Germany Sweden Finland Japan
	Switzerland Russia Ukraine Belarus Lithuania Romania Latvia
	Haiti Kazakhstan Poland
), "Czech Republic", "United States");

use Data::Dumper;

sub new ($$$) {

	my $class = shift;
	my $json  = shift;

	my $code = JSON->new();
	$code->utf8(1);
	my $self;
	return undef unless $json;
	try { $self = {json => $code->decode(decode "UTF-8", $json)} }
	catch { $self = {json => $code->decode($json)} };
	#	$self->{json} = $self->{json}{people}[0];
	return undef unless $self->{json}{id};
	bless $self, $class;
	$self;
}

sub parse_bio ($) {

	my $self = shift;
	my $bio  = $self->{json};

	my $player = {
		_id       => $bio->{id},
		name      => $bio->{fullName},
		position  => $bio->{primaryPosition}{code},
		number    => $bio->{primaryNumber},
		shoots    => $bio->{shootsCatches} || 'R',
		birthdate => $bio->{birthDate},
		city      => $bio->{birthCity},
		state     => $bio->{birthStateProvince} || 'NA',
		country   => $bio->{birthCountry},
		team      => $bio->{currentTeam}{name},
	};
	for my $key (
		qw(active rookie height weight pick round draftteam draftyear undrafted),
		keys %{$player},
	) {
		$self->{$key}  = $player->{$key} || $bio->{$key};
	}
	if ($MISSING_PLAYER_INFO{$bio->{id}}) {
		for my $k (keys %{$MISSING_PLAYER_INFO{$bio->{id}}}) {
			$self->{$k} ||= $MISSING_PLAYER_INFO{$bio->{id}}->{$k};
		}
	}
	$self->{name} = normalize_string($player->{name});
}

sub get_career_phase_index ($) {

	my $phase = shift;

	my $index;

	if ($phase->{type}{displayName} eq 'yearByYear') {
		$index = 0;
	}
	elsif ($phase->{type}{displayName} eq 'yearByYearPlayoffs') {
		$index = 1;
	}
	else {
		die "Strange phase $phase->{type}{displayName}";
	}
	$index;
}

sub parse_career ($) {

	my $self = shift;

	my $j_career = $self->{json}{stats};
	my $position = $self->{position};

	my $career = [];
	my $c;
	for my $phase (@{$j_career}) {
		my $c = get_career_phase_index($phase);
		$career->[$c] = [];
		for my $season (@{$phase->{splits}}) {
			next unless $season->{season};
			my $start = substr($season->{season}, 0, 4);
			my $end   = substr($season->{season}, 4, 4);
			my $career_year = {};
			$career_year->{season} = "$start-$end";
			$career_year->{team}   =
				$season->{team}{abbreviation} || $season->{team}{name} || $season->{team}{id};
			$career_year->{league} = $season->{league}{name};
			$career_year->{gp}     = $season->{stat}{games};
			$career_year->{pim}    = $season->{stat}{pim};
			$career_year->{toi}    = $season->{stat}{timeOnIce};
			if ($position eq 'G') {
				$career_year->{w}     = $season->{stat}{wins};
				$career_year->{l}     = $season->{stat}{losses};
				$career_year->{t}     = $season->{stat}{ties};
				$career_year->{ot}    = $season->{stat}{ot};
				$career_year->{so}    = $season->{stat}{shutouts};
				$career_year->{ga}    = $season->{stat}{goalsAgainst};
				$career_year->{sa}    = $season->{stat}{saves};
				$career_year->{'sv%'} = $season->{stat}{savePercentage} || 0;
				$career_year->{gaa}   = $season->{stat}{goalAgainstAverage};
				$career_year->{min}   = sprintf("%.0f", get_seconds($season->{stat}{timeOnIce} || '0:00')/60);
				$career_year->{gs}    = $season->{stat}{gamesStarted};
			}
			else {
				$career_year->{g}      = $season->{stat}{goals};
				$career_year->{a}      = $season->{stat}{assists};
				$career_year->{pts}    = $season->{stat}{points};
				$career_year->{'+/-'}  = $season->{stat}{plusMinus};
				$career_year->{ppg}    = $season->{stat}{powerPlayGoals};
				$career_year->{shg}    = $season->{stat}{shortHandedGoals};
				$career_year->{s}      = $season->{stat}{shots};
				$career_year->{'s%'}   = $season->{stat}{shotPct};
				$career_year->{gwg}    = $season->{stat}{gameWinningGoals};
				$career_year->{shifts} = $season->{stat}{shifts};
				$career_year->{'fo%'}  = $season->{stat}{faceOffPct};
				$career_year->{otg}    = $season->{stat}{overTimeGoals};
			}
			push(@{$career->[$c]}, $career_year);
		}
	}
	$self->{career} = $career;
}

sub normalize_bio ($) {

	my $self  = shift;

	for my $field (@PLAYER_FIELDS) {
		if (defined $self->{$field}) {
			$self->{$field} =~ s/^\s//;
			$self->{$field} =~ s/\s$//;
			for ($field) {
				when ('name')      { $self->{$field} = uc $self->{$field} }
				when ('number')    { $self->{$field} =~ s/\D//g; }
				when ('weight')    { $self->{$field} =~ s/\D//g; }
				when ('shoots')    {
					$self->{$field} = substr($self->{$field}, 0, 1)
				}
				when ('position')  {
					$self->{$field} = substr($self->{$field}, 0, 1)
				}
				when ('birthdate') {
					$self->{$field} = str3time($self->{$field});
				}
				when (['draftteam', 'team']) {
					$self->{$field} = resolve_team($self->{$field});
				}
				when ('height')    {
					$self->{$field} =~ /(\d)\'\s*(\d+)\"/;
					$self->{$field} = $1 * 12 + $2 if defined $1 && defined $2;
				}
				when ('draftyear') {
					if ($self->{draftyear} =~ /^\s*(\S\S\S)\s+.*?(\d{4})/) {
						$self->{draftteam} = $1;
						$self->{draftyear} = $2;
					}
				}
				when ('draftposition') {
					if($self->{draftposition} =~ /(\d+)\D+(\d+)/) {
						$self->{round} = $1;
						$self->{pick} = $2;
					}
				}
			}
			$self->{$field} += 0
				if defined $self->{$field} && $self->{$field} =~ /^\-?\d*\.?\d+$/;
		}
		else {
			delete $self->{$field};
		}
	}
}

sub normalize_career ($) {

	my $self = shift;

	my $career = $self->{career};

	for my $stage (@{$career}) {
		for my $season (@{$stage}) {
			my @fields = keys %{$season};
			for my $field (@fields) {
				unless (defined $season->{$field}) {
					delete $season->{$field};
					next;
				}
				$season->{$field} =~ s/^\s+//;
				$season->{$field} =~ s/\s+$//;
				$season->{$field} =~ s/\,//g;
				$season->{$field} = '' if $season->{$field} eq '-';
				$season->{lc $field} = delete $season->{$field} if $field =~ /[A-Z]/;
			}
			# NHL data error fix
			$season->{ga} = 117 if $season->{ga} && $season->{ga} == 871;
			$season->{ga} = 94  if $season->{ga} && $season->{ga} == 1465;
			$season->{ga} = 13  if $season->{ga} && $season->{ga} == 1380;
			$season->{gp} = 9   if $season->{gp} && $season->{gp} == 119;
			$season->{gp} = 47  if $season->{gp} && $season->{gp} == 487;
			$season->{so} = 1   if $season->{so} && $season->{so} == 149;
			if ($season->{season} =~ /(\d+)\-(\d+)/) {
				$season->{start}    = $1;
				$season->{end}      = $2;
				$season->{team}   ||= 'Unknown-UNKHL';
				$season->{league} ||= 'UNKHL';
				$season->{league} = $LEAGUE_NAME if $season->{league} eq 'National Hockey League' && $season->{start} >= 1942;
				if ($season->{team} =~ /(.*?)\-(\S+)\s*$/ ||
					$season->{team} =~ /(.*?)\-(\S+\s*Ten)$/ ||
					$season->{team} =~ /(.*?)\-(\S+\s*Midget)$/ ||
					$season->{team} =~ /(.*?)\-(\S+)\s*Italy\s*$/ ||
					$season->{team} =~ /(.*?)\s+(U18-20 Elit)/ ||
					$season->{team} =~ /(.*?)\-(\S+\s*Jr.)/ ||
					$season->{team} =~ /(.*?)\-(\S+\s*Sr.)$/) {
					$season->{team}   = $1;
					$season->{league} = $2;
				}
				else {
					$season->{league} ||= 'NHL';
				}
				if ($season->{league} eq 'NHL') {
					$stage->[-1]{career_start} ||= $season->{start};
					$stage->[-1]{career_end} = $season->{end}
						if $season->{end} > ($season->{career_end} || 0);
				}
			}
			else {
				if ($season->{team} =~ /total/i && $season->{gp}) {
					$season->{season} = 'total';
					$season->{league} = 'NHL';
				}
				else {
					$season->{league} = 'bogus';
				}
			}
		}
	}
	$career;
}

sub process ($) {

	my $self   = shift;

	$self->parse_bio();
	$self->normalize_bio();
	$self->parse_career();
	$self->normalize_career();

	delete $self->{json};
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::Player>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::Player

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::Player>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::Player>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::Player>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::Player>

=back
