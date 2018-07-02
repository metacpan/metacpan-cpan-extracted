package Sport::Analytics::NHL::Test;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Exporter';

use Carp;
use Data::Dumper;
use Storable;

use List::MoreUtils qw(uniq);

use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL::Util;
use Sport::Analytics::NHL::Errors;

=head1 NAME

Sport::Analytics::NHL::Test - Utilities to test NHL reports data.

=head1 SYNOPSYS

Utilities to test NHL report data

 These are utilities that test and validate the data contained in the NHL reports to detect errors. They are also used to test and validate the permutations that are performed by this software on the data.
 Ideally, that method should extend Test::More, but first, I was too lazy to figure out how to do it, and second, I notice that in the huge number of tests that are run, Test::More begins to drag things down.

    use Sport::Analytics::NHL::Test;
    test_team_id('SJS') # pass
    test_team_id('S.J') # fail and die (usually)

 The failures are usually bad enough to force the death of the program and an update to Sport::Analytics::NHL::Errors (q.v.), but see the next section

=head1 GLOBAL VARIABLES

 The behaviour of the tests is controlled by several global variables:
 * $TEST_COUNTER - contains the number of the current test in Curr_Test field and the number of passes/fails in Test_Results.
 * $DO_NOT_DIE - when set to 1, failed test will not die.
 * $MESSAGE - the latest failure message
 * $TEST_ERRORS - accumulation of errors by type (event, player, boxscore, team)

=head1 FUNCTIONS

=over 2

=item C<my_die>

 Either dies with a stack trace dump, or aggregates the error messages, based on $DO_NOT_DIE
 Arguments: the death message
 Returns: void

=item C<my_test>

 Executes a test subroutine and sets the failure message in case of failure. Updates test counters.
 Arguments: the test subroutine and its arguments
 Returns: void

=item C<my_like>

 Approximately the same as Test::More::like()

=item C<my_is>

 Approximately the same as Test::More::is()

=item C<my_ok>

 Approximately the same as Test::More::ok()

=item C<my_is_one_of>

 Approximately the same as grep {$_[0] == $_} $_[1]

=item C<test_season>

 For the test_* functions below the second argument is always the notification message. Sometimes third parameter may be passed.
 This one tests if the season is one between $FIRST_SEASON (from Sports::Analytics::NHL::Config) and $CURRENT_SEASON (from Sports::Analytics::NHL::LocalConfig)

=item C<test_stage>

 Tests if the stage is either Regular (2) or Playoff (3)

=item C<test_season_id>

 Tests the season Id to be between 1 and 1500 (supposedly maximum number of games per reg. season)

=item C<test_game_id>

 Tests the game Id to be of the SSSSTIIII form. In case optional parameter is_nhl, tests for the NHL id SSSSTTIIII

=item C<test_team_code>

 Tests if the string is a three-letter team code, not necessarily the normalized one.

=item C<test_team_id>

 Tests if the string is a three-letter franchise code, as specified in keys of Sports::Analytics::NHL::Config::TEAMS

=item C<test_ts>

 Tests the timestamp to be an integer (negative for pre-1970 games) number.

=item C<test_game_date>

 Tests the game date to be in YYYYMMDD format.

=back

=cut

our $TEST_COUNTER = {Curr_Test => 0, Test_Results => []};

our @EXPORT = qw(
	my_like my_ok my_is
	test_game_id test_team_id test_team_code
	test_stage test_season test_season_id
	test_ts test_game_date
	$TEST_COUNTER
	$EVENT $BOXSCORE $PLAYER $TEAM
);

our $DO_NOT_DIE = 0;
our $TEST_ERRORS = {};
our $MESSAGE = '';
our $THIS_SEASON;

our $EVENT;
our $BOXSCORE;
our $PLAYER;
our $TEAM;

sub my_die ($) {

	my $message = shift;
	if ($DO_NOT_DIE) {
		my $field;
		my $object;
		if ($EVENT) {
			$field = 'events';
			$object = $EVENT;
		}
		elsif ($PLAYER) {
			$field = 'players';
			$object = $PLAYER;
		}
		else {
			$field = 'boxscore';
			$object = $BOXSCORE;
		}
		$TEST_ERRORS->{$field} ||= [];
		push(
			@{$TEST_ERRORS->{$field}},
			{
				_id => $object->{_id} || $object->{event_idx} || $object->{number},
				message => $MESSAGE,
			}
		);
		#store $TEST_ERRORS, 'test-errors.storable';
		return;
	}
	$message .= "\n" unless $message =~ /\n$/;
	my $c = 0;
	my $offset = '';
	while (my @caller = caller($c++)) {
		$message .= sprintf(
			"%sCalled in %s::%s, line %d in %s\n",
			$offset, $caller[0], $caller[3], $caller[2], $caller[1]
		);
		$offset .= '  ';
	}
	die $message;
}

sub my_test ($@) {

	my $test = shift;
	$TEST_COUNTER->{Curr_Test}++;
	no warnings 'uninitialized';
	if (@_ == 2) {
		$MESSAGE = "Failed $_[-1]: $_[0]";
	}
	else {
		if (ref $_[1] && ref $_[1] eq 'ARRAY') {
			my $arg1 = join('/', @{$_[1]});
			$MESSAGE = "Failed $_[-1]: $_[0] vs $arg1\n";
		}
		else {
			$MESSAGE = "Failed $_[-1]: $_[0] vs $_[1]\n";
		}
	}
	if ($test->(@_)) {
		$TEST_COUNTER->{Test_Results}[0]++;
	}
	else {
		$TEST_COUNTER->{Test_Results}[1]++;
		my_die($MESSAGE);
	}
	use warnings FATAL => 'all';
	debug "ok_$TEST_COUNTER->{Curr_Test} - $_[-1]\n" if $0 =~ /\.t$/;
}

sub my_like ($$$) { my_test(sub { no warnings 'uninitialized'; $_[0] =~ $_[1]  }, @_) }
sub my_is   ($$$) { my_test(sub { no warnings 'uninitialized'; $_[0] eq $_[1]  }, @_) }
sub my_ok   ($$)  { my_test(sub { no warnings 'uninitialized'; $_[0]           }, @_) }
sub my_is_one_of ($$$) { my_test(sub { no warnings 'uninitialized'; grep { $_[0] ==  $_ } @{$_[1]}}, @_) }

sub test_season ($$) {
	my $season  = shift;
	my $message = shift;
	my_ok($season >= $FIRST_SEASON, $message); my_ok($season <= $CURRENT_SEASON, $message);
	$THIS_SEASON = $season;
}

sub test_stage ($$) {
	my $stage   = shift;
	my $message = shift;
	my_ok($stage >= $REGULAR, 'stage ok'); my_ok($stage <= $PLAYOFF, $message);
}

sub test_season_id ($$) {
	my $id      = shift;
	my $message = shift;
	my_ok($id > 0, $message); my_ok($id < 1500, $message);
}

sub test_game_id ($$;$) {
	my $id      = shift;
	my $message = shift;
	my $is_nhl  = shift || 0;

	$is_nhl
		? $id =~ /^(\d{4})(\d{2})(\d{4})$/
		: $id =~ /^(\d{4})(\d{1})(\d{4})$/;
	test_season($1, $message); test_stage($2, $message); test_season_id($3, $message);
}

sub test_team_code ($$) {
	my_like(shift, qr/^\w{3}$/, shift .' tri letter code a team');
}

sub test_team_id ($$)   { test_team_code($_[0],$_[1]) && my_ok($TEAMS{$_[0]}, "$_[0] team defined")};
sub test_ts ($$)        { my_like(shift, qr/^-?\d+$/, shift) }
sub test_game_date ($$) { my_like(shift, qr/^\d{8}$/,  shift) }

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Test>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Test>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Test>

=back
