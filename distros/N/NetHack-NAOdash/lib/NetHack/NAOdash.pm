package NetHack::NAOdash;

use 5.014000;
use strict;
use warnings;
use re '/saa';
use parent qw/Exporter/;

our $VERSION = '0.003';
our @EXPORT_OK = qw/naodash_xlog naodash_user/;
our @EXPORT = @EXPORT_OK;

use File::Slurp;
use File::Spec::Functions qw/tmpdir catdir catfile/;
use HTTP::Tiny;
use List::Util qw/max min sum/;
use List::MoreUtils qw/uniq/;
use Text::XLogfile qw/parse_xlogline/;

sub won_game {
	my %game = @_;
	$game{death} eq 'ascended'
}

our @check_subs = (
	sub { # Combos
		my %game = @_;
		return unless won_game %game;
		$game{align0} //= $game{align};
		"combo_$game{role}_$game{race}_$game{align0}"
	},

	sub { # Achievements
		my %game = @_;
		my @achieves = qw/bell gehennom candelabrum book invocation amulet endgame astral ascended luckstone sokoban medusa/;
		map { $game{achieve} & (1 << $_) ? "achieve_$achieves[$_]" : () } 0 .. $#achieves
	},

	sub { # Conducts
		my %game = @_;
		return unless won_game %game;
		my @conducts = qw/foodless vegan vegetarian atheist weaponless pacifist illiterate polypileless polyselfless wishless artiwishless genocideless/;
		map { $game{conduct} & (1 << $_) ? "conduct_$conducts[$_]" : () } 0 .. $#conducts
	},

	sub { # Unofficial conducts
		my %game = @_;
		return unless won_game %game;
		my @uconducts;
		push @uconducts, 'survivor' if $game{deaths} == 0;
		push @uconducts, 'boneless' unless $game{flags} & 32;
		push @uconducts, 'minscore' if $game{points} - 100 * ($game{maxlvl} - 45) == 24_400;
		map { "uconduct_$_" } @uconducts
	},
);

our %sum_subs = (
	games => sub { 1 },
	ascensions => sub {
		my %game = @_;
		!!won_game %game
	},
	totalrealtime => sub {
		my %game = @_;
		$game{realtime} // 0
	},
);

sub make_attr_sub ($) { ## no critic (ProhibitSubroutinePrototypes)
	my ($attr) = @_;
	sub {
		my %game = @_;
		return unless won_game %game;
		$game{$attr} // ()
	},
}

our %max_subs = (
	maxhp => make_attr_sub 'maxhp',
	maxpoints => make_attr_sub 'points',
	maxconducts => make_attr_sub 'nconducts',
);

our %min_subs = (
	minturns => make_attr_sub 'turns',
	minrealtime => make_attr_sub 'realtime',
);

sub naodash_xlog { ## no critic (RequireArgUnpacking)
	my (%args, %exclude, %include);
	%args = %{shift()} if ref $_[0] eq 'HASH'; ## no critic (Builtin)
	%exclude = map { $_ => 1 } @{$args{exclude_versions} // []};
	%include = map { $_ => 1 } @{$args{include_versions} // []};
	my ($xlog) = join '', @_;
	my %number_subs = (%sum_subs, %max_subs, %min_subs);

	my @checks;
	my %numbers = map { $_ => [] } keys %number_subs;

	for my $logline (split /\n/, $xlog) {
		my %game = %{parse_xlogline $logline};
		for (keys %game) {
			delete $game{$_} if $game{$_} eq ''
		}
		next if $exclude{$game{version}} || %include && !$include{$game{version}};
		next if $game{flags} & 3; # flag 0x01 is wizard mode, 0x02 is explore mode
		push @checks, $_->(%game) for @check_subs;
		push @{$numbers{$_}}, $number_subs{$_}->(%game) for keys %number_subs;
	}

	$numbers{$_} = sum @{$numbers{$_}} for keys %sum_subs;
	$numbers{$_} = max @{$numbers{$_}} for keys %max_subs;
	$numbers{$_} = min @{$numbers{$_}} for keys %min_subs;
	@checks = uniq map { lc } @checks;

	{checks => [sort @checks], numbers => \%numbers}
}

my $ht = HTTP::Tiny->new(agent => "NetHack-NAOdash/$VERSION ");

sub _get_xlog_from_server {
	my ($name) = @_;
	my $ret = $ht->get("http://alt.org/nethack/player-all-xlog.php?player=$name");
	die 'Error while retrieving xlogfile from alt.org: ' . $ret->{status} . ' ' . $ret->{reason} . "\n" unless $ret->{success};
	$ret->{content} =~ m{<pre>(.*)</pre>}i;
}

sub _get_xlog {
	my ($name) = @_;
	return _get_xlog_from_server $name if $ENV{NAODASH_CACHE} && lc $ENV{NAODASH_CACHE} eq 'none';
	my $dir = $ENV{NAODASH_CACHE} || catdir tmpdir, 'naodash';
	mkdir $dir or die "Cannot create cache directory: $!\n" unless -d $dir;
	my $file = catfile $dir, $name;
	write_file $file, _get_xlog_from_server $name if ! -f $file || time - (stat $file)[9] >= 86_400;
	scalar read_file $file
}

sub naodash_user { ## no critic (RequireArgUnpacking)
	my $args = {};
	$args = shift if ref $_[0] eq 'HASH';
	my ($name) = @_;
	my $xlog = _get_xlog $name;
	die "No xlogfile found for user $name\n" unless defined $xlog;
	naodash_xlog $args, $xlog;
}

1;
__END__

=encoding utf-8

=head1 NAME

NetHack::NAOdash - Analyze NetHack xlogfiles and extract statistics

=head1 SYNOPSIS

  use NetHack::NAOdash;
  my $stats = naodash_user 'mgv'; # Retrieve and analyze mgv's xlogfile from alt.org
  my @checks = @{$stats->{checks}}; # List of 'achievements' obtained by mgv
  my %checks = map { $_ => 1 } @checks;
  say 'mgv has ascended an orcish rogue' if $checks{combo_rog_orc_cha};
  say 'mgv has ascended an atheist character' if $checks{conduct_atheist};
  my %numbers = %{$stats->{numbers}};
  say "mgv has ascended $numbers{ascensions} out of $numbers{games} games";
  say "mgv has spent $numbers{totalrealtime} seconds playing NetHack on NAO";

  $stats = naodash_user {include_versions => ['3.6.0']}, 'mgv';
  say 'mgv has ascended an orcish rogue in 3.6.0' if $checks{combo_rog_orc_cha};
  $stats = naodash_user {exclude_versions => ['3.6.0']}, 'mgv';
  say 'mgv has ascended an atheist character pre-3.6.0' if $checks{conduct_atheist};

  use File::Slurp;
  $stats = naodash_xlog read_file 'path/to/my/xlogfile';
  %checks = map { $_ => 1 } @{$stats->{checks}};
  say 'I have ascended a survivor' if $checks{uconduct_survivor};

=head1 DESCRIPTION

NetHack::NAOdash analyzes a NetHack xlogfile and reports statistics.
There are two types of statistics: B<checks>, which are flags
(booleans) and B<numbers> which are integers.

The B<checks> are tracked across all games. That is, a B<check> will
be true in the statistics if it is true in at least one game. Except
for B<checks> in the I<Achievements> category, only games that end in
an ascension are considered for awarding a B<check>.

The B<checks>, sorted by category, are:

=over

=item B<Achievements>

These start with C<achieve_> and represent significant milestones in a
game. They are usually relevant only for users who never ascended, as
a game that ends in an ascension generally meets all of them.

  achieve_sokoban  achieve_luckstone   achieve_medusa achieve_bell
  achieve_gehennom achieve_candelabrum achieve_book   achieve_invocation
  achieve_amulet   achieve_endgame     achieve_astral achieve_ascended

=item B<Starting Combos>

These look like C<combo_role_race_alignment> and represent
role/race/alignment combinations in ascended games. The starting
alignment, not the alignment at the end of the game is considered. For
example, C<cav_gno_neu> is true if the user ascended at least one
gnomish caveman.

=item B<Conducts>

These start with C<conduct_> and represent the 12 officially tracked
conducts.

  conduct_foodless     conduct_vegan        conduct_vegetarian
  conduct_atheist      conduct_weaponless   conduct_pacifist
  conduct_illiterate   conduct_genocideless conduct_polypileless
  conduct_polyselfless conduct_wishless     conduct_artiwishless

=item B<Unofficial Conducts>

These start with C<uconduct_> and represent conducts that are not
officially tracked by the game.

  uconduct_survivor uconduct_bones uconduct_minscore

=back

The numbers are:

=over

=item B<totalrealtime>

The total time spent playing NetHack on NAO, in seconds.

=item B<games>

The number of games played.

=item B<ascensions>

The number of games played that ended in an ascension.

=item B<maxhp>

The highest maxHP at the end of an ascension.

=item B<maxpoints>

The highest score obtained at the end of an ascension.

=item B<maxconducts>

The maximum number of conducts at the end of an ascension.

=item B<minturns>

The minimum turns across ascended games.

=item B<minrealtime>

The minimum realtime across ascended games, in seconds.

=back

This module exports two functions:

=over

=item B<naodash_xlog>([\%args], I<@lines>)

=item B<naodash_xlog>([\%args], I<$xlog>)

Takes an optional hashref followed by the contents of an xlogfile and
returns the results of the analysis. The contents are joined together
then split by the newline character, so they can be specified as a
single string, as a list of lines, or as a combination thereof.

The following keys are recognised in the optional hashref:

=over

=item include_versions

The associated value is an arrayref of NetHack versions that should be
considered. Any game that was played on a version that is not in this
arrayref will be ignored. If this key is not present or the value is
an empty arrayref, all versions are considered.

=item exclude_versions

The associated value is an arrayref of NetHack versions that should
not be considered. Any game that was played on a version that is in
this arrayref will be ignored. If a version is both included and
excluded at the same time, it will not be considered (in other words,
exclude_versions overrides include_versions).

=back

The return value is of the following form:

  { checks => ['achieve_sokoban', 'achieve_luckstone', ...],
    numbers => {totalrealtime => 12345, games => 2, ...} }

In other words, C<< @{$result->{checks}} >> is an array of B<checks>
that are true and C<< %{$result->{numbers}} >> is a hash of
B<numbers>.

=item B<naodash_user>([I<\%args>], I<$nao_username>)

Retrieves the xlogfile of a user from NAO and gives it to
B<naodash_xlog>. Dies if no xlogfile is found or if the server cannot
be contacted.

An optional hashref can be passed as a first argument. In this case it
will be supplied as a first argument to B<naodash_xlog>, see that
function's documentation for an explanation of useful keys.

This method caches the downloaded xlogfiles for one day in the
directory named by the NAODASH_CACHE environment variable.

=back

=head1 ENVIRONMENT

=over

=item NAODASH_CACHE

Path to a directory that should be used to cache xlogfiles downloaded
from NAO, or the special value 'none' (case-insensitive) to disable
caching.

By default a directory named 'naodash' in the default temporary
directory (C<< File::Spec->tmpdir >>) is used.

=back

=head1 SEE ALSO

L<App::NAOdash>, L<App::Web::NAOdash>, L<http://alt.org/nethack/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
