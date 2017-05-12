package Sport::Analytics::SimpleRanking;

use warnings;
use strict;
use List::Util qw( max );
use Carp;

=head1 NAME

Sport::Analytics::SimpleRanking - This module provides a method that calculate Doug Drinen's simple ranking system. 

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

This module provides a method that calculates Doug Drinen's simple ranking system. 
It also provides access to some other useful team and season stats.

    use Sport::Analytics::SimpleRanking;
    my $stats = Sport::Analytics::SimpleRanking->new();
    my $games = [
        "Boston,13,Atlanta, 27",
        "Dallas,17,Chicago,21",
        "Eugene,30,Fairbanks,41",
        "Atlanta,15,Chicago,3",
        "Eugene,21,Boston,24",
        "Fairbanks,17,Dallas,7",
        "Dallas,19,Atlanta,7",
        "Boston,9,Fairbanks,31",
        "Chicago,10,Eugene,30",
    ];
    $stats->load_data( $games );
    my  $srs = $stats->simpleranking( verbose => 1 );
    my $mov = $stats->mov;
    my $sos = $stats->sos;
    for ( keys %$srs ) {
        print "Team $_ has a srs of ", $srs->{$_};
        print " and a mov of ",$mov->{$_},"\n";
    }


=head1 DESCRIPTION

The simple ranking system is one based on rates of scoring, generally by starting with team margin of victory (i.e. average point spread). It is perhaps the simplest model of the form

 Team Strength = a x (Mov) + b x (Opponent Strength)

In the simple ranking system, a = 1 and b = 1/(number of opponents played). Matrix solutions of this linear equation tend to be very unstable, whereas an iterative solution rapidly converges to a stable answer. This object implements the iterative solution, and since doing that much work means the object can calculate a number of other useful values on the data set, it does so as well.

One more note, though commonly described as N equations in N unknowns, an additional constraint is required to solve to a single unique answer, and that is that the sum of all simple rankings must add up to 0.0. This also guarantees that the average club in a season has a ranking of zero. 

=cut

package Sport::Analytics::SimpleRanking;

return 1;

=head1 METHODS

=head2 CREATION

=head3 new()

 my $stats = Sport::Analytics::SimpleRanking->new()

Output: a working SimpleRanking object.

=cut

sub new {
    my ( $class, %proto ) = @_;
    %proto = () unless (%proto);
    if ( $proto{debug} ) {
        for ( keys %proto ) {
            print "$_ => $proto{$_}\n";
        }
    }
    $proto{loaded} = 0;
    $proto{calc}   = 0;

    # parameter validation here.
    $proto{warnTeam} = 1000   unless ( $proto{warnTeam} );
    $proto{warnGame} = 100000 unless ( $proto{warnGeam} );
    croak " warnTeam should always be a number."
      unless ( $proto{warnTeam} =~ /^\d+$/ );
    croak " warnGame should always be a number."
      unless ( $proto{warnGame} =~ /^\d+$/ );
    bless \%proto, ref($class) || $class;
    return \%proto;
}

=head2 ACCESSORS

Unless otherwise specified, success returns the value (or values) requested and failure is carped and returns a reference to an empty hash. Failures in the accessors happen when data have not been successfully loaded.

=head3 total_games()

 my $total_games = $stats->total_games();

Input: none required

Output: The number of games total in the data set loaded.
=cut

sub total_games {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total_games};
}

=head3 total_teams()

 my $total_teams = $stats->total_teams();

Input: none required

Output: The number of teams total in the data set loaded.
=cut

sub total_teams {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total_team};
}


=head3 total_wins()

 my $total_wins = $stats->total_wins();

Input: none required

Output: The number of wins total in the data set loaded.
=cut

sub total_wins {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}->{wins};
}

=head3 home_wins()

 my $home_wins = $stats->home_wins();

Input: none required

Output: The number of wins by home teams in the data set loaded.
=cut

sub home_wins {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}->{home_wins};
}

=head3 home_win_pct()

 my $home_win_percent = $stats->home_win_pct();

Input: none required

Output: Percentage number of wins by home teams in the data set loaded.
=cut

sub home_win_pct {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}{home_wins}/$self->{total_games};
}

=head3 win_margin()

 my $win_margin = $stats->win_margin();

Input: none required

Output: Average margin of victory if a team does win.
=cut

sub win_margin {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}{win_margin}/$self->{total}{wins};
}

=head3 win_score()

 my $average_winnning_score = $stats->win_score();

Input: none required

Output: Average winning score if a team does win.
=cut

sub win_score {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}{win_score}/$self->{total}{wins};
}

=head3 loss_score()

 my $average_losing_score = $stats->loss_score();

Input: none required

Output: Average losing score if a team does lose.
=cut

sub loss_score {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}{losing_score}/$self->{total}{wins};
}

=head3 avg_score()

 my $average_score = $stats->avg_score();

Input: none required

Output: Average score under any circumstance.
=cut

sub avg_score {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    return $self->{total}{total_scores}/( 2.0*$self->{total_games} );
}

=head3 team_stats()

 my $teams = $stats->team_stats();
 for (sort keys %$teams) {
     printf "%s:  %3d-%3d-%3d\n", $_, $team{$_}{wins}, $team{$_}{losses}, $team{$_}{ties};
 }

Input: none required

Output: A reference to a hash of statistics per team. These include
        wins
        losses
        ties
        games_played
        points_for
        points_against
        point_spread
        win_pct
        mov  (also known as average point spread).

This function will return an empty hash reference if data have not yet been loaded.

=cut

sub team_stats {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    my %team;
        for my $t ( sort keys %{ $self->{team} } ) {
            print "Team_Stats: t = $t\n" if ( $self->{debug} );
            $team{$t}{wins} = ${$self->{team}}{$t}{wins};
            $team{$t}{wins} ||= 0;
            $team{$t}{losses} = ${$self->{team}}{$t}{losses};
            $team{$t}{losses} ||= 0;
            $team{$t}{ties} = ${$self->{team}}{$t}{ties};
            $team{$t}{ties} ||= 0;
            $team{$t}{games_played} = ${$self->{team}}{$t}{games_played};
            $team{$t}{points_for} = ${$self->{team}}{$t}{points_for};
            $team{$t}{points_against} = ${$self->{team}}{$t}{points_against};
            $team{$t}{point_spread} = $team{$t}{points_for} - $team{$t}{points_against};
            $team{$t}{win_pct} = ($team{$t}{wins} + 0.5*$team{$t}{ties})/ $team{$t}{games_played};
            $team{$t}{mov} = ${$self->{team}}{$t}{mov};
        }
    return \%team;
}

=head3 pythag()

The Pythagorean formula is a rule of thumb that estimates winning percentage from points scored and points allowed. 

 Estimated Winning Percentage = (Pts Scored)**N/( (Pts Scored)**N + (Pts Allowed)**N )

In the original Bill James formulation, the power of the Pythagorean formula, N, is 2. This implementation can calculate the
Pythagorean power from the game data set itself.


 my $teams = $stats->team_stats();
 my $predicted = $stats->pythag();
 for (sort keys %$teams) {
     printf "%s:  %6.2f %6.2f\n", $_, $team{$_}{win_pct}, $predicted{$_};
 }

Input:  If none given, will assume N = 2. 

 my $predicted = $stats->pythag();

If input is a number, that number will be used to calculate the power of the Pythagorean prediction.

 my $predicted = $stats->pythag(2.5);

If input is a reference to a scalar, and the option 'best => 1' is used, then this program will use a golden mean search to find the best fit value of N, and return the value in the reference provided.

 my $predicted = $stats->pythag( \$exp, best => 1 );

Output: 

A hash reference with team names as keys and predicted winning percentage as values.

This function will return an empty hash reference if data have not yet been loaded.

=cut

sub pythag {
    my ( $self, $exp, %opt ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }

    my $power = 2.0;
    if ( $exp ) {
        if ( $opt{best} ) {
            if ( ref($exp) eq 'SCALAR' ) {
                if ( $opt{verbose} ) {
                    $$exp = $self->_py_sect( verbose => 1 );
                }
                else {
                    $$exp = $self->_py_sect();
                }
                $power = $$exp;
            }
        }
        else { 
            $power = $exp;
        }
    };
    my %pred;
    for my $t ( sort keys %{ $self->{team} } ) {
        $pred{$t} = $self->_py_calc( $self->{team}{$t}{points_for}, $self->{team}{$t}{points_against}, $power );
    }
    return \%pred;
}

sub _py_calc {
    my $self = shift;
    my $pf = shift;
    my $pa = shift;
    my $power = shift;
    $power ||= 2.0;
    return ( $pf**$power) / ( $pf**$power + $pa**$power );
}

sub _py_fit {
    my  ($self, $exp ) = @_;
    my $ssq = 0;
    for my $t ( keys % { $self->{team} } ) {
        my $calc = $self->_py_calc( $self->{team}{$t}{points_for}, $self->{team}{$t}{points_against}, $exp );
        $ssq += ( $self->{team}{$t}{win_pct} - $calc )**2;
    }
    return $ssq;
}

sub _py_sect {
    my ( $self, %opt ) = @_;
    my $lo = 0.0;
    my $hi = 25.0;
    my $tol = 0.001;
    my $g = $self->_golden_ratio();
    my $one_minus_g = 1.0 - $g;
    my @p;
    my @f;
#
# if [  $lo, $hi ] is an interval in which a minimum is found, choose points so that
# p[1] = ~ 2/3 lo + ~ 1/3 hi and p[2] = ~ 1/3 lo + ~ 2/3 hi. 
#
    $p[0] = $lo;
    $p[3] = $hi;
    $p[1] = $one_minus_g*$p[0] + $g*$p[3];
    $p[2] = $g*$p[0] + $one_minus_g*$p[3];
    $f[1] = $self->_py_fit( $p[1] );
    $f[2] = $self->_py_fit( $p[2] );
    while ( abs( $p[3] - $p[0] )  > $tol ) {
        if ( $f[2] < $f[1] ) {
            print "Low = $p[1]\n" if ( $opt{verbose} );
            $p[0] = $p[1];
            $p[1] = $p[2];
            $p[2] = $one_minus_g*$p[1] + $g*$p[3];
            $f[1] = $f[2];
            $f[2] = $self->_py_fit( $p[2] );
        }
        else {
            print "High = $p[2]\n" if ( $opt{verbose} );
            $p[3] = $p[2];
            $p[2] = $p[1];
            $p[1] = $one_minus_g*$p[2] + $g*$p[0];
            $f[2] = $f[1];
            $f[1] = $self->_py_fit( $p[1] );
        }
    }
    return $f[2] > $f[1] ? $p[1] : $p[2];
}

sub _golden_ratio {
    my $self = shift;
    return ( 3.0 - sqrt(5))/2 ;
}



=head2 ALGORITHM COMPONENTS

=head3 mov()

 my $mov = $stats->mov();
 for (sort keys %$mov) {
     printf "team %s: margin of victory: %6.2f\n", $_, $mov{$_};
 }

Input: none required

Output: a hash of mov values (margin of victory, or average point spread) per team.
This function will return an empty hash reference if data have not yet been loaded.

=cut

sub mov {
    my ( $self ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }
    else {
        my %mov;
        for my $t ( sort keys %{ $self->{team} } ) {
            print "mov: t = $t\n" if ( $self->{debug} );
            $mov{$t} = ${$self->{team}}{$t}{mov};
        }
        return \%mov;
    }
}

=head3 sos()

Strength of schedule is the sum of the simple rankings of all teams that
played a specific team, divided by the total number of teams that played
the team.

 my $sos = $stats->sos();
 for (sort keys %$sos) {
     printf "team %s: strength of schedule: %6.2f\n", $_, $sos{$_};
 }


Input: none required

Output: a hash of sos values (strength of schedule) per team.
This function will return an empty hash reference if data have not yet been calculated.

=cut

sub sos {
    my ( $self ) = @_;

    if ( !$self->{calc} ) {
        carp "No data are calculated presently.";
        return {};

    }
    else {
        my %sos;
        for my $t ( sort keys %{ $self->{team} } ) {
            print "sos: t = $t\n" if ( $self->{debug} );
            $sos{$t} = ${$self->{team}}{$t}{sos};
        }
        return \%sos;
    }
}

=head3 simpleranking()

Input: none required, options possible.

Example:

 my $stats = Sport::Analytics::SimpleRanking->new();
 $stats->load_data( \@games );
 my $srs = $stats->simpleranking( verbose => 1 );
 my $mov = $stats->mov();
 my $sos = $stats->sos();
 for (sort keys %$srs) {
     printf "team %s: simple ranking: %6.2f = margin of victory: %6.2f", $_, $srs{$_},$mov{$_};
     printf " + strength of schedule: %6.2f\n",$sos{$_};
 }

Options:

    epsilon => value

    This is a convergence criterion. Usually you won't need to set this.

    maxiter => value

    A stopgap to prevent runaways. Usually unnecessary as this algorithm converges rapidly.

    verbose => value

    Set this on to visually watch values converge.

Output: The simple rankings of the data as a hash of values per team name.
This function will return an empty hash reference if data have not yet been calculated.

=cut

sub simpleranking {
    my ( $self, %options ) = @_;

    if ( !$self->{loaded} ) {
        carp "No data are loaded presently.";
        return {};
    }

    $options{epsilon} ||= 0.001;
    $options{maxiter} ||= 1000000;
    for ( keys %{ $self->{team} } ) {
        $self->{team}{$_}{srs}    = $self->{team}{$_}{mov};
        $self->{team}{$_}{oldsrs} = $self->{team}{$_}{srs};
        $self->{team}{$_}{sos}    = 0;
    }
    my $delta = 10.0;
    my $iter  = 0;
    while ( $delta > $options{epsilon} and $iter < $options{maxiter} ) {
        $delta = 0.0;
        for ( keys %{ $self->{team} } ) {
            print "team => $_\n" if ( $self->{debug} );
            my $sos = 0.0;
            for my $g ( @{ $self->{played}{$_} } ) {
                $sos += $self->{team}{$g}{srs};
            }
            $sos /= $self->{team}{$_}{games_played};
            $self->{team}{$_}{srs} = $self->{team}{$_}{mov} + $sos;
            my $newdelt = abs( $sos - $self->{team}{$_}{sos} );
            $self->{team}{$_}{sos} = $sos;
            $delta = max( $newdelt, $delta );
        }
        for ( keys %{ $self->{team} } ) {
            $self->{team}{$_}{oldsrs} = $self->{team}{$_}{srs};
        }
        $iter++;
        if ( $options{verbose} ) {
            print "iter  : $iter\n";
            print "delta : $delta\n";
            for ( sort keys %{$self->{team}} ) {
                printf "%20s srs:%7.2f mov:%7.2f sos:%7.2f \n" ,$_ , 
                    $self->{team}{$_}{srs},$self->{team}{$_}{mov}, $self->{team}{$_}{sos};
            }
            print "elements in \$self->{team}: ",scalar keys %{$self->{team}},"\n" if ( $self->{debug} );
            print "\n\n";
        }
    }
    $self->_srs_correction();
    if ( $options{verbose} ) {
        print "Adjusted to 0.0\n";
        for ( sort keys %{$self->{team}} ) {
            printf "%20s srs:%7.2f mov:%7.2f sos:%7.2f \n" ,$_ , 
                $self->{team}{$_}{srs},$self->{team}{$_}{mov}, $self->{team}{$_}{sos};
        }
        print "\n\n";
    }
    print "iter     = $iter\n"             if $options{verbose};
    print "epsilon  = $options{epsilon}\n" if $options{verbose};
    printf "delta    = %7.4f\n", $delta if $options{verbose};
    print "elements in \$self->{team}: ",scalar keys %{$self->{team}},"\n" if ( $options{verbose} and $self->{debug} );
    $self->{calc} = 1;
    my %srsmap;
    $srsmap{$_} = $self->{team}{$_}{srs} for ( keys %{ $self->{team} } );
    return \%srsmap;
}

#
# Any solution SRS = MOV + SOS has an equally valid solution
#
# SRS + c = MOV + SOS + c.
#
# You have to correct for that by setting the sum  of all srs values to average to 0.0.
#
sub _srs_correction {
    my ( $self, %options ) = @_;
    my $sum = 0.0;
    for ( keys %{ $self->{team} } ) {
        $sum += $self->{team}{$_}{srs};
    }
    $sum /= $self->{total_team};
    for ( keys %{ $self->{team} } ) {
        $self->{team}{$_}{srs} -= $sum;
        $self->{team}{$_}{sos} -= $sum;
    }
    return;
}

=head2 DATA LOADING

There are  two methods provided, C<load_data()> and C<add_data()>. The method
C<load_data()> can only be used once, then C<add_data()> thereafter. 

=head3 load_data()

Input: a reference to an array of comma separated strings of the form:

"visting team,score,home team,score"

Example:

    use Sport::Analytics::SimpleRanking;
    my $stats = Sport::Analytics::SimpleRanking->new();
    my $games = [
        "Boston,13,Atlanta, 27",
        "Dallas,17,Chicago,21",
        "Eugene,30,Fairbanks,41",
        "Atlanta,15,Chicago,3",
        "Eugene,21,Boston,24",
        "Fairbanks,17,Dallas,7",
        "Dallas,19,Atlanta,7",
        "Boston,9,Fairbanks,31",
        "Chicago,10,Eugene,30",
    ];
    $stats->load_data( $games );

This calculation requires at least two teams, and then at least two games per
team in order to be successful.

Output: returns 1 on success, croaks on failure.

=cut

sub load_data {
    my ( $self, $games ) = @_;
    croak("You can only load data once into this object. Use add_data to add more data.")
      if ( $self->{loaded} );
    $self->{loaded} = 0;
    croak("Method load_data requires a reference to a games array.")
      unless ( ref($games) eq 'ARRAY' );
    $self->{total_games} = 0;
    $self->{total} = ();
    $self->{team} = ();
    $self->{game} = ();
    for (@$games) {
        my ( $visitor, $visit_score, $home_team, $home_score ) = split "\,", $_;
        croak "The home score is undefined in array element $self->{total_games}. Perhaps you have missed a comma?"
          unless ( defined( $home_score ) );
        croak
"The visitor score field in array element $self->{total_games} needs to be a number."
          unless ( $visit_score =~ /^\s*\d+\s*$/ );
        croak
"The home score field in array element $self->{total_games} needs to be a number."
          unless ( $home_score =~ /^\s*\d+\s*$/ );
        my $diff = $home_score - $visit_score;
        if ( $diff > 0 ) {
            $self->{total}{wins}++;
            $self->{total}{win_score} += $home_score;
            $self->{total}{losing_score} += $visit_score;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{total}{home_wins}++;
            $self->{total}{win_margin} += $diff;
            $self->{team}{$home_team}{wins}++;
            $self->{team}{$visitor}{losses}++;
        }
        elsif ( $diff == 0 ) {
            $self->{total}{ties}++;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{team}{$home_team}{ties}++;
            $self->{team}{$visitor}{ties}++;
        }
        else {
            $self->{total}{wins}++;
            $self->{total}{losing_score} += $home_score;
            $self->{total}{win_score} += $visit_score;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{total}{visit_wins}++;
            $self->{total}{win_margin} -= $diff;
            $self->{team}{$home_team}{losses}++;
            $self->{team}{$visitor}{wins}++;
        }
        push @{ $self->{game}{visitor} },     $visitor;
        push @{ $self->{game}{visit_score} }, $visit_score;
        push @{ $self->{game}{home_team} },   $home_team;
        push @{ $self->{game}{home_score} },  $home_score;
        push @{ $self->{game}{mov} },         $diff;
        $self->{team}{$visitor}{games_played}++;
        $self->{team}{$home_team}{games_played}++;
        $self->{team}{$visitor}{points} -= $diff;
        $self->{team}{$home_team}{points} += $diff;
        $self->{team}{$visitor}{points_for} += $visit_score;
        $self->{team}{$visitor}{points_against} += $home_score;
        $self->{team}{$home_team}{points_for} += $home_score;
        $self->{team}{$home_team}{points_against} += $visit_score;
        push @{ $self->{played}{$visitor} },   $home_team;
        push @{ $self->{played}{$home_team} }, $visitor;
        $self->{total_games}++;
    }
    croak("Method load_data requires at least two games to analyze data.")
      unless ( $self->{total_games} > 1 );
    $self->{total_team} = scalar keys %{ $self->{team} };
    croak("Method load_data requires at least two teams.")
      unless ( $self->{total_team} > 1 );
    croak("Method load_data requires at least as many games as teams.")
      unless (  $self->{total_team} <= $self->{total_games} );
    for my $t ( keys %{ $self->{team} } ) {
        croak("Method load_data requires team $t to have played at least two games.")
          unless ( $self->{team}{$t}{games_played} > 1 );
    }
    carp("The number of teams in this data set is exceptionally large.")
      if ( $self->{total_team} > $self->{warnTeam} );
    carp("The number of games in this data set is exceptionally large.")
      if ( $self->{total_games} > $self->{warnGame} );

    for my $t ( sort keys %{ $self->{team} } ) {
        my $team_diff =
          $self->{team}{$t}{points} / $self->{team}{$t}{games_played};
        $self->{team}{$t}{mov} = $team_diff;
        $self->{team}{$t}{wins} ||=  0;
        $self->{team}{$t}{ties} ||=  0;
        $self->{team}{$t}{losses} ||=  0;
        $self->{team}{$t}{win_pct} = ($self->{team}{$t}{wins} + 0.5*$self->{team}{$t}{ties})/ $self->{team}{$t}{games_played};
    }
    $self->{loaded} = 1;
    return $self->{loaded};
}

=head3 add_data()

Input: a reference to an array of comma separated strings of the form:

"visting team,score,home team,score"

Example:

    use Sport::Analytics::SimpleRanking;
    my $stats = Sport::Analytics::SimpleRanking->new();
    # first two weeks games.
    my $games = [
        "Boston,13,Atlanta, 27",
        "Dallas,17,Chicago,21",
        "Eugene,30,Fairbanks,41",
        "Atlanta,15,Chicago,3",
        "Eugene,21,Boston,24",
        "Fairbanks,17,Dallas,7",
    ];
    $stats->load_data( $games );
    # add another week of games.
    my $newgames = [
        "Dallas,19,Atlanta,7",
        "Boston,9,Fairbanks,31",
        "Chicago,10,Eugene,30",
    ];
    $stats->add_data( $newgames ); 

This calculation requires at least two teams, and then at least two games per
team in order to be successful.

Output: returns 1 on success, croaks on failure.

=cut

sub add_data {
    my ( $self, $games ) = @_;
    croak("Method add_data requires a reference to a games array.")
      unless ( ref($games) eq 'ARRAY' );
    # two passes allows add_data to croak without disrupting already existing data in the object.
    for (@$games) {
        my ( $visitor, $visit_score, $home_team, $home_score ) = split "\,", $_;
        croak "The home score is undefined in array element $self->{total_games}. Perhaps you have missed a comma?"
          unless ( defined( $home_score ) );
        croak
"The visitor score field in array element $self->{total_games} needs to be a number."
          unless ( $visit_score =~ /^\s*\d+\s*$/ );
        croak
"The home score field in array element $self->{total_games} needs to be a number."
          unless ( $home_score =~ /^\s*\d+\s*$/ );
    }
    for (@$games) {
        my ( $visitor, $visit_score, $home_team, $home_score ) = split "\,", $_;
        my $diff = $home_score - $visit_score;
        if ( $diff > 0 ) {
            $self->{total}{wins}++;
            $self->{total}{win_score} += $home_score;
            $self->{total}{losing_score} += $visit_score;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{total}{home_wins}++;
            $self->{total}{win_margin} += $diff;
            $self->{team}{$home_team}{wins}++;
            $self->{team}{$visitor}{losses}++;
        }
        elsif ( $diff == 0 ) {
            $self->{total}{ties}++;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{team}{$home_team}{ties}++;
            $self->{team}{$visitor}{ties}++;
        }
        else {
            $self->{total}{wins}++;
            $self->{total}{losing_score} += $home_score;
            $self->{total}{win_score} += $visit_score;
            $self->{total}{total_scores} += ( $home_score + $visit_score );
            $self->{total}{visit_wins}++;
            $self->{total}{win_margin} += -$diff;
            $self->{team}{$home_team}{losses}++;
            $self->{team}{$visitor}{wins}++;
        }
        push @{ $self->{game}{visitor} },     $visitor;
        push @{ $self->{game}{visit_score} }, $visit_score;
        push @{ $self->{game}{home_team} },   $home_team;
        push @{ $self->{game}{home_score} },  $home_score;
        push @{ $self->{game}{mov} },         $diff;
        $self->{team}{$visitor}{games_played}++;
        $self->{team}{$home_team}{games_played}++;
        $self->{team}{$visitor}{points} -= $diff;
        $self->{team}{$home_team}{points} += $diff;
        $self->{team}{$visitor}{points_for} += $visit_score;
        $self->{team}{$visitor}{points_against} += $home_score;
        $self->{team}{$home_team}{points_for} += $home_score;
        $self->{team}{$home_team}{points_against} += $visit_score;
        push @{ $self->{played}{$visitor} },   $home_team;
        push @{ $self->{played}{$home_team} }, $visitor;
        $self->{total_games}++;
    }
    $self->{total_team} = scalar keys %{ $self->{team} };
    carp("The number of teams in this data set is exceptionally large.")
      if ( $self->{total_team} > $self->{warnTeam} );
    carp("The number of games in this data set is exceptionally large.")
      if ( $self->{total_games} > $self->{warnGame} );

    for my $t ( sort keys %{ $self->{team} } ) {
        my $team_diff =
          $self->{team}{$t}{points} / $self->{team}{$t}{games_played};
        $self->{team}{$t}{mov} = $team_diff;
        $self->{team}{$t}{wins} ||=  0;
        $self->{team}{$t}{ties} ||=  0;
        $self->{team}{$t}{losses} ||=  0;
        $self->{team}{$t}{win_pct} = ($self->{team}{$t}{wins} + 0.5*$self->{team}{$t}{ties})/ $self->{team}{$t}{games_played};
    }
    $self->{loaded} = 1;
    $self->{calc} = 0;
    return $self->{loaded};
}

=head1 DIAGNOSTICS

=head2 accessors and calculations
 
 No data are loaded presently.

Data need to be loaded before this value can be returned.

 No data are calculated presently.

Data need to be loaded and simpleranking needs to be run first.

=head2 load_data()

 You can only load data once into this object. Use add_data to add more data.

Code attempts to use load_data more than once. Use add_data instead.

 Method load_data requires a reference to a games array.

Either no data passed to load_data, or the wrong kind of data has been passed to load_data.
Arrays should be dereferenced: C<\@array>.

 The home score is undefined in array element X. Perhaps you have missed a comma?

This happens when there are less than 3 commas in a data string passed to the method. 

 The visitor score field in array element X needs to be a number.

The second field in a game string needs to be a number.

 The home score field in array element X needs to be a number.

The fourth field in a game string needs to be a number.

 Method load_data requires at least two games to analyze data.
 Method load_data requires at least two teams.
 Method load_data requires at least as many games as teams.
 Method load_data requires team T to have played at least two games.

There are certain minimum data requirements for this program to function.

 The number of teams in this data set is exceptionally large.

Happens if you pass more than 1000 teams to this method.

 The number of games in this data set is exceptionally large.
 
Happens if you pass more than 1,000,000 games to this method.


=head2 add_data()

 Method add_data requires a reference to a games array.

Either no data passed to add_data, or the wrong kind of data has been passed to add_data.
Arrays should be dereferenced: C<\@array>.

 The home score is undefined in array element X. Perhaps you have missed a comma?
 
This happens when there are less than 3 commas in a data string passed to the method. 

 The visitor score field in array element X needs to be a number.

The second field in a game string needs to be a number.

 The home score field in array element X needs to be a number.

The fourth field in a game string needs to be a number.

 The number of teams in this data set is exceptionally large.

Happens if you pass more than 1000 teams to this method.

 The number of games in this data set is exceptionally large.
 
Happens if you pass more than 1,000,000 games to this method.

=head1 CONFIGURATION AND ENVIRONMENT

No specific issues to note.

=head1 DEPENDENCIES

To build, Test::More. The modules List::Util and Carp are needed to build and to run this code.

=head1 INCOMPATIBILITIES

None known at this time.

=head1 AUTHOR

David Myers, C<< <dwm042 at email.com> >>

=head1 REFERENCES

  algorithm: L<http://www.pro-football-reference.com/blog/?p=37>
  original Perl implementation: L<http://wp.me/p1m41i-8p>
  Pythagorean formula: L<http://en.wikipedia.org/wiki/Pythagorean_expectation>

=head1 BUGS AND LIMITATIONS

No known bugs at this time.

Please report any bugs or feature requests to C<bug-sport-analytics-simpleranking at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport-Analytics-SimpleRanking>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

The algorithm requires at least two teams, and at least two games per team to calculate a simple ranking. If you have N teams, a minimum of N games are required in order to do the simple ranking calculation. It could be more, depending on who has played whom.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::SimpleRanking


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport-Analytics-SimpleRanking>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport-Analytics-SimpleRanking>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sport-Analytics-SimpleRanking>

=item * Search CPAN

L<http://search.cpan.org/dist/Sport-Analytics-SimpleRanking/>

=back


=head1 ACKNOWLEDGEMENTS

To Doug Drinen, who manages the Pro Football Reference site, and who has published and promoted the use of the simple rankings system. To GrandFather at Perl Monks, who suggested many improvements in the design of the first versions of this module.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 David Myers, C<< <dwm042 at email.com> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head2 Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.



=cut

1;    # End of Sport::Analytics::SimpleRanking
