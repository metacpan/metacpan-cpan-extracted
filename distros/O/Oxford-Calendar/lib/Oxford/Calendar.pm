# Oxford University calendar conversion.
# Simon Cozens (c) 1999-2002
# Eugene van der Pijll (c) 2004
# University of Oxford (c) 2007-2015
# Dominic Hargreaves (c) 2016
# Artistic License
package Oxford::Calendar;
$Oxford::Calendar::VERSION = "2.13";
use strict;
use Text::Abbrev;
use Date::Calc qw(Add_Delta_Days Decode_Date_EU Delta_Days Mktime Easter_Sunday Date_to_Days Day_of_Week_to_Text Day_of_Week);
use YAML;
use Time::Seconds;
use Time::Piece;

use constant CALENDAR => '/etc/oxford-calendar.yaml';
use constant SEVEN_WEEKS => 7 * ONE_WEEK;
use constant DEFAULT_MODE => 'nearest';
use constant TERMS => qw(Michaelmas Hilary Trinity);
use constant DAYS => qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

# Constants defined by University regulations
use constant MICHAELMAS_START       => (10, 1);
use constant MICHAELMAS_END         => (12, 17);
use constant HILARY_START           => (1, 7);
use constant HILARY_END_IF_EARLIER  => (3, 25);
use constant TRINITY_START_IF_LATER => (4, 20);
use constant TRINITY_END            => (7, 6);

=head1 NAME

Oxford::Calendar - University of Oxford calendar conversion routines

=head1 SYNOPSIS

    use 5.10.0;
    use Oxford::Calendar;
    use Date::Calc;
    say "Today is " . Oxford::Calendar::ToOx(reverse Date::Calc::Today);

=head1 DESCRIPTION

This module converts University of Oxford dates (Oxford academic dates)
to and from Real World dates, and provides information on Terms of the
University.

The Terms of the University are defined by the
B<Regulations on the number and lengths of terms>, available online from

L<https://www.admin.ox.ac.uk/examregs/2015-16/rotnalengofterm/>

This document describes the start and end dates of Oxford Terms.

In addition to this, the dates of Full Term, required to calculate the
week number of the term, are prescribed by Council, and published
periodically in the B<University Gazette>.

Full term comprises weeks 1-8 inclusive, but sometimes, dates outside of
full term are presented in the Oxford academic date format.
This module will optionally provide such dates.

Data for these prescribed dates may be supplied in the file
F</etc/oxford-calendar.yaml>; if this file does not exist, built-in data
will be used. The built-in data is periodically updated from the
semi-authoritative source at

L<http://www.ox.ac.uk/about/facts-and-figures/dates-of-term>.

or the authoritative source, the Gazette, available online from

L<http://www.ox.ac.uk/gazette/>.

L<http://www.ox.ac.uk/news-and-events/The-University-Year>
describes the academic year at Oxford.

=head1 DATE FORMAT

An Oxford academic date has the following format:

=over

<day of week>, <week number>[st,nd,rd,th] week, <term name> <year>

=back

where term name is one of

=over

=item *

Michaelmas (autumn)

=item *

Hilary (spring)

=item *

Trinity (summer)

=back

Example:

Friday, 8th Week, Michaelmas 2007

=cut

our %db;

my $_initcal;    # If this is true, we have our database of dates already.
my $_initrange;
my @_oxford_full_terms;

sub _get_week_suffix {
    my $week = shift;
    die "_get_week_suffix: No week given" unless defined $week;
    my $wsuffix = "th";
    abs($week) == 1 && ( $wsuffix = "st" );
    abs($week) == 2 && ( $wsuffix = "nd" );
    abs($week) == 3 && ( $wsuffix = "rd" );
  
    return $wsuffix;
}

sub _find_week {
    my $tm = shift;
    my $sweek = shift;
    my $sweek_tm = shift;

    my $eow = $sweek_tm + ONE_WEEK;

    while ( $tm >= $eow ) {
        $eow += ONE_WEEK;
        $sweek++;
    }
    return $sweek;
}

sub _init_db {
    my $db;
    if ( -r CALENDAR ) {
        $db = YAML::LoadFile(CALENDAR);
    }
    else {
        my $data = join '', <DATA>;
        $db = YAML::Load($data);
    }
    %db = %{ $db->{Calendar} };
}

sub _init_range {
    foreach my $termspec ( keys %db ) {
        next unless $db{$termspec};

        my $time = eval { Time::Piece->strptime($db{$termspec}->{start}, '%d/%m/%Y' ) }
             or die
                "Could not decode date ($db{$termspec}->{start}) for term $termspec: $@";

        push @_oxford_full_terms,
            [$time, ($time + SEVEN_WEEKS), split(/ /, $termspec), $db{$termspec}->{provisional}];
    }

    $_initrange++;
}

sub _fmt_oxdate_as_string {
    my ( $dow, $week, $term, $year ) = @_;
    my $wsuffix = _get_week_suffix($week);
    return "$dow, $week$wsuffix week, $term $year";
}

sub _increment_term { 
    my ( $year, $term ) = @_;
    if ( $term eq 'Michaelmas' ) { 
        return $year + 1, 'Hilary';
    } elsif ( $term eq 'Hilary' ) { 
        return $year, 'Trinity'
    } elsif ( $term eq 'Trinity' ) {
        return $year, 'Michaelmas';
    } else {
        die "_increment_term: Unknown term $term";
    }
}

sub _sunday_of_first {
    my ( $year, $term ) = @_;
    Init() unless defined $_initcal;
    my $date = $db{"$term $year"};
    return undef unless $date;
    return ( $date->{provisional}, Decode_Date_EU($date->{start}) );
}

sub _to_ox_nearest {
    my @date = @_;
    my $confirmed = pop @date;
    my $week;
    my @term;
    _init_range() unless defined $_initrange;
    my $dow = Day_of_Week_to_Text( Day_of_Week( @date ) );
    my $tm = Time::Piece->strptime(join('/', @date[0..2]), '%Y/%m/%d');
    my @terms = sort { $a->[0] <=> $b->[0] } @_oxford_full_terms;
    my ( $prevterm, $nextterm );
    my $curterm = shift @terms;

    while ($curterm) {
        if ( $tm < $curterm->[0] ) {
            if ( $prevterm && $tm >= ($prevterm->[1] + ONE_WEEK) ) {
                $nextterm = $curterm;
                last;
            } else {
                die "Date out of range";
            }
        }
        $prevterm = $curterm;
        $curterm = shift @terms;
    }
    return undef unless $nextterm;

    # We are in the gap between terms .. which one is closest?
    my $prevgap = $tm - ($prevterm->[1] + ONE_WEEK);
    my $nextgap = $tm - $nextterm->[0];

    if ( abs($prevgap) < abs($nextgap) ) {
        # if equal go for -<n>th week
        $week = _find_week( $tm, 8, $prevterm->[1] );
        @term = @{$prevterm};
    } else {
        my $delta = $nextgap / (24 * 60 * 60);
        $week = 1 + int( $delta / 7 );
        $week -= 1 if $delta % 7;
        @term = @{$nextterm};
    }
    return undef if $term[4] && $confirmed;
    return ($dow, $week, $term[2], $term[3]) if ( wantarray );
    return _fmt_oxdate_as_string( $dow, $week, $term[2], $term[3] );
}


sub Init {
    _init_db;
    Date::Calc::Language(Date::Calc::Decode_Language('English'));
    $_initcal++;
}

=head1 FUNCTIONS

=over 3

=item ToOx($day, $month, $year, [\%options])

Given a day, month and year in standard human format (that is, month is
1-12, not 0-11, and year is four digits) will return a string of the
form

    Day, xth week, Term year

or an array

    (Day, week of term, Term, year)
    
depending on how it is called. The exact behaviour is modified by the 'mode'
option described below.

If the requested date is not in full term or extended term (see below),
undef will be returned.

If the requested date is not covered by the database, ToOx will die with
an "out of range" error message. Therefore it is recommended to eval ToOx
with appropriate error handling.

%options can contain additional named parameter options:

=over 5

=item mode

Several modes are available:

=over 6

=item full_term

Term dates will only be returned if the date requested is part of a full
term (as defined by the web page above).

=item ext_term

Term dates will only be returned if the date requested is part of an extended
term, or statutory term.

=item nearest

Will return term dates based on the nearest term, even if the date requested
is not part of an extended term (i.e. will include fictional week numbers).

This is currently the default behaviour, for backwards compatibility with
previous releases; this may be changed in future.

=back

=back

=over 4

=item confirmed

If true, ignores dates marked as provisional in the database.

=back

=cut

sub ToOx {
    my (@dmy, $options);
    ($dmy[0], $dmy[1], $dmy[2], $options) = @_;
    my $mode = $options->{mode} || DEFAULT_MODE;
    my ($week, @term);
    my @date = reverse @dmy;
    Init unless defined $_initcal;
    my $dow = Day_of_Week_to_Text( Day_of_Week( @date ) );

    @term = ThisTerm( @date );
    if ( $#term ) {
        # We're in term
        my @term_start = _sunday_of_first( @term );
        my $provisional = shift @term_start;
        die "Date out of range" unless ( $#term_start == 2 );
        my $days_from_start = Delta_Days( @term_start, @date );
        my $week_offset = $days_from_start < 0 ? 1 : 7;
        my $week = int( ( $days_from_start + $week_offset ) / 7);
        return undef if $options->{confirmed} && $provisional;
        return undef if ( ( $week < 1 || $week > 8 ) && $mode eq 'full_term' );
        return ( $dow, $week, $term[1], $term[0] ) if ( wantarray );
        return _fmt_oxdate_as_string( $dow, $week, $term[1], $term[0] );
    } else {
        return undef if $mode eq 'full_term';
        return undef if $mode eq 'ext_term';
        return _to_ox_nearest( @date, $options->{confirmed} );
    }
}

=item ThisTerm($year, $month, $day)

Given a year, month, term in standard human format (that is, month is
1-12, not 0-11, and year is four digits) will returns the current term
or undef if in vacation or unknown. The term is given as an array in the
form (year, term).

=cut

sub ThisTerm {
    my ( $year, $month, $day ) = @_;
    my $term_dates = StatutoryTermDates( $year );
    foreach my $term ( keys %{$term_dates} ) {
        my $start = Date_to_Days( @{$term_dates->{$term}->{start}} );
        my $end = Date_to_Days( @{$term_dates->{$term}->{end}} );
        my $date = Date_to_Days( $year, $month, $day );
        if ( ( $date >= $start ) && ( $date <= $end )) {
            return ( $year, $term );
        }
    }
    return undef;
}

=item NextTerm($year, $month, $day)

Given a day, month and year in standard human format (that is, month is
1-12, not 0-11, and year is four digits) will return the next term (whether
or not the date given is in term time).
The term is given as an array in the form (year, term).

=cut

sub NextTerm {
    my @date = @_;
    my @next_term;
    my @this_term = ThisTerm( @date );
    if ( @this_term == 2 ) {
        @next_term = _increment_term( @this_term );
    } else {
        my @test_date = @date;
        while ( @next_term != 2 ) {
            @test_date = Add_Delta_Days( @test_date, 1 );
            @next_term = ThisTerm( @test_date );
        }
    }
    return @next_term;
}

=item StatutoryTermDates($year)

Returns a hash reference keyed on terms for a given year, the value of
each being a hash reference containing start and end dates for that term.
The dates are stored as array references containing numeric
year, month, day values.

Note: these are the statutory term dates, not full term dates.

=cut

sub StatutoryTermDates {
    my $year = shift;
    die "StatutoryTermDates: no year given" unless $year;
    
    # Calculate end of Hilary
    my @palm_sunday =
        Date::Calc::Add_Delta_Days( Date::Calc::Easter_Sunday( $year ), -7 );
    my @saturday_before_palm_sunday =
        Date::Calc::Add_Delta_Days( @palm_sunday, -6 );

    my $hilary_delta = Date::Calc::Delta_Days(
                            $year, HILARY_END_IF_EARLIER,
                            @saturday_before_palm_sunday
    );

    my @hilary_end;
    if ( $hilary_delta == 1 ) {
        @hilary_end = ( $year, HILARY_END_IF_EARLIER );
    } else {
        @hilary_end = @saturday_before_palm_sunday;
    }
    
    # Calculate start of Trinity
    my @wednesday_after_easter_sunday =
        Date::Calc::Add_Delta_Days( Date::Calc::Easter_Sunday( $year ), 3 );

    my $trinity_delta = Date::Calc::Delta_Days(
                            @wednesday_after_easter_sunday,
                            $year, TRINITY_START_IF_LATER
    );

    my @trinity_start;
    if ( $trinity_delta == 1 ) {
        @trinity_start = ( $year, TRINITY_START_IF_LATER );
    } else {
        @trinity_start = @wednesday_after_easter_sunday;
    }

    my $term_dates = {
        Michaelmas => {
            start => [$year, MICHAELMAS_START],
            end   => [$year, MICHAELMAS_END]
        },
        Hilary => {
            start => [$year, HILARY_START],
            end   => [@hilary_end]
        },
        Trinity => {
            start => [@trinity_start],
            end   => [$year, TRINITY_END]
        }
    };
    return $term_dates;
}

=item Parse($string)

Takes a free-form description of an Oxford calendar date, and attempts
to divine the expected meaning. If the name of a term is not found, the
current term will be assumed. If the description is unparsable, undef
is returned.  Otherwise, an array will be returned of the form
C<($year,$term,$week,$day)>.

This function is experimental.

=cut

sub Parse {
    my $string = shift;
    my $term   = "";
    my ( $day, $week, $year );
    $day = $week = $year = "";

    $string = lc($string);
    $string =~ s/week//g;
    $string =~ s/(\d+)(?:rd|st|nd|th)/$1/;
    my %ab = Text::Abbrev::abbrev( DAYS, TERMS );
    my $expand;
    while ( $string =~ s/((?:\d|-)\d*)/ / ) {
        if ( $1 > 50 ) { $year = $1; $year += 1900 if $year < 1900; }
        else { $week = $1 }
    }
    foreach ( sort { length $b <=> length $a } keys %ab ) {
        if ( $string =~ s/\b$_\w+//i ) {

            #pos($string)-=length($_);
            #my $foo=lc($_); $string=~s/\G$foo[a-z]*/ /i;
            $expand = $ab{$_};
            $term   = $expand if ( scalar( grep /$expand/, TERMS ) > 0 );
            $day    = $expand if ( scalar( grep /$expand/, DAYS ) > 0 );
        }
    }
    unless ($day) {
        %ab = Text::Abbrev::abbrev(DAYS);
        foreach ( sort { length $b <=> length $a } keys %ab ) {
            if ( $string =~ /$_/ig ) {
                pos($string) -= length($_);
                my $foo = lc($_);
                $string =~ s/\G$foo[a-z]*/ /;
                $day = $ab{$_};
            }
        }
    }
    unless ($term) {
        %ab = Text::Abbrev::abbrev(TERMS);
        foreach ( sort { length $b <=> length $a } keys %ab ) {
            if ( $string =~ /$_/ig ) {
                pos($string) -= length($_);
                my $foo = lc($_);
                $string =~ s/\G$foo[a-z]*/ /;
                $term = $ab{$_};
            }
        }
    }

    # Assume this term?
    unless ($term) {
        $term = ToOx( reverse Date::Calc::Today() );
        return "Can't work out what term" unless $term =~ /week/;
        $term =~ s/.*eek,\s+(\w+).*/$1/;
    }
    $year = ( Date::Calc::Today() )[0] unless $year;
    return undef unless defined $week and defined $day;
    return ( $year, $term, $week, $day );
}

=item FromOx($year, $term, $week, $day)

Converts an Oxford date into a Gregorian date, returning a string of the
form C<DD/MM/YYYY> or undef.

The arguments are of the same format as returned by ToOx in array context;
that is, a four-digit year, the name of the term, the week number, and
the name of the day of week (e.g. 'Sunday').

If the requested date is not covered by the database, FromOx will die with
an "out of range" error message. Therefore it is recommended to eval ToOx
with appropriate error handling.

=cut

sub FromOx {
    my %lu;
    Init unless defined $_initcal;
    my ( $year, $term, $week, $day );
    ( $year, $term, $week, $day ) = @_;
    $year =~ s/\s//g;
    $term =~ s/\s//g;
    die "No data for $term $year" unless exists $db{"$term $year"};
    {
        my $foo = 0;
        %lu = ( map { $_, $foo++ } DAYS );
    }
    my $delta = 7 * ( $week - 1 ) + $lu{$day};
    my @start = _sunday_of_first( $year, $term );
    shift @start;
    die "The internal database is bad for $term $year"
        unless $start[0];
    return join "/", reverse( Date::Calc::Add_Delta_Days( @start, $delta ) );
}

1;

=back

=head1 BUGS

Bugs may be browsed and submitted at

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Oxford-Calendar>

A copy of the maintainer's git repository may be found at

L<https://github.com/jmdh/Oxford-Calendar>

=head1 AUTHOR

Simon Cozens is the original author of this module.

Eugene van der Pijll, C<pijll@cpan.org> took over maintenance from
Simon for a time.

Dominic Hargreaves maintains this module (between 2008 and 2015 for
IT Services, University of Oxford).

=cut

__DATA__
--- #YAML:1.0
Calendar:
  Hilary 2001:
    start: 14/01/2001
  Hilary 2002:
    start: 13/01/2002
  Hilary 2003:
    start: 19/01/2003
  Hilary 2004:
    start: 18/01/2004
  Hilary 2005:
    start: 16/01/2005
  Hilary 2006:
    start: 15/01/2006
  Hilary 2007:
    start: 14/01/2007
  Hilary 2008:
    start: 13/01/2008
  Hilary 2009:
    start: 18/01/2009
  Hilary 2010:
    start: 17/01/2010
  Hilary 2011:
    start: 16/01/2011
  Hilary 2012:
    start: 15/01/2012
  Hilary 2013:
    start: 13/01/2013
  Hilary 2014:
    start: 19/01/2014
  Hilary 2015:
    start: 18/01/2015
  Hilary 2016:
    start: 17/01/2016
  Hilary 2017:
    start: 15/01/2017
  Hilary 2018:
    start: 14/01/2018
  Hilary 2019:
    start: 13/01/2019
  Hilary 2020:
    start: 19/01/2020
  Hilary 2021:
    start: 17/01/2021
  Hilary 2022:
    start: 16/01/2022
  Hilary 2023:
    start: 15/01/2023
  Hilary 2024:
    start: 14/01/2024
  Hilary 2025:
    start: 19/01/2025
  Hilary 2026:
    start: 18/01/2026
    provisional: 1
  Hilary 2027:
    start: 17/01/2027
    provisional: 1
  Hilary 2028:
    start: 16/01/2028
    provisional: 1
  Hilary 2029:
    start: 14/01/2029
    provisional: 1
  Hilary 2030:
    start: 13/01/2030
    provisional: 1
  Hilary 2031:
    start: 19/01/2031
    provisional: 1
  Michaelmas 2001:
    start: 07/10/2001
  Michaelmas 2002:
    start: 13/10/2002
  Michaelmas 2003:
    start: 12/10/2003
  Michaelmas 2004:
    start: 10/10/2004
  Michaelmas 2005:
    start: 09/10/2005
  Michaelmas 2006:
    start: 08/10/2006
  Michaelmas 2007:
    start: 07/10/2007
  Michaelmas 2008:
    start: 12/10/2008
  Michaelmas 2009:
    start: 11/10/2009
  Michaelmas 2010:
    start: 10/10/2010
  Michaelmas 2011:
    start: 09/10/2011
  Michaelmas 2012:
    start: 07/10/2012
  Michaelmas 2013:
    start: 13/10/2013
  Michaelmas 2014:
    start: 12/10/2014
  Michaelmas 2015:
    start: 11/10/2015
  Michaelmas 2016:
    start: 09/10/2016
  Michaelmas 2017:
    start: 08/10/2017
  Michaelmas 2018:
    start: 07/10/2018
  Michaelmas 2019:
    start: 13/10/2019
  Michaelmas 2020:
    start: 11/10/2020
  Michaelmas 2021:
    start: 10/10/2021
  Michaelmas 2022:
    start: 09/10/2022
  Michaelmas 2023:
    start: 08/10/2023
  Michaelmas 2024:
    start: 13/10/2024
  Michaelmas 2025:
    start: 12/10/2025
    provisional: 1
  Michaelmas 2026:
    start: 11/10/2026
    provisional: 1
  Michaelmas 2027:
    start: 10/10/2027
    provisional: 1
  Michaelmas 2028:
    start: 08/10/2028
    provisional: 1
  Michaelmas 2029:
    start: 07/10/2029
    provisional: 1
  Michaelmas 2030:
    start: 13/10/2030
    provisional: 1
  Trinity 2001:
    start: 22/04/2001
  Trinity 2002:
    start: 21/04/2002
  Trinity 2003:
    start: 27/04/2003
  Trinity 2004:
    start: 25/04/2004
  Trinity 2005:
    start: 24/04/2005
  Trinity 2006:
    start: 23/04/2006
  Trinity 2007:
    start: 22/04/2007
  Trinity 2008:
    start: 20/04/2008
  Trinity 2009:
    start: 26/04/2009
  Trinity 2010:
    start: 25/04/2010
  Trinity 2011:
    start: 01/05/2011
  Trinity 2012:
    start: 22/04/2012
  Trinity 2013:
    start: 21/04/2013
  Trinity 2014:
    start: 27/04/2014
  Trinity 2015:
    start: 26/04/2015
  Trinity 2016:
    start: 24/04/2016
  Trinity 2017:
    start: 23/04/2017
  Trinity 2018:
    start: 22/04/2018
  Trinity 2019:
    start: 28/04/2019
  Trinity 2020:
    start: 26/04/2020
  Trinity 2021:
    start: 25/04/2021
  Trinity 2022:
    start: 24/04/2022
  Trinity 2023:
    start: 23/04/2023
  Trinity 2024:
    start: 21/04/2024
  Trinity 2025:
    start: 27/04/2025
  Trinity 2026:
    start: 26/04/2026
    provisional: 1
  Trinity 2027:
    start: 25/04/2027
    provisional: 1
  Trinity 2028:
    start: 23/04/2028
    provisional: 1
  Trinity 2029:
    start: 22/04/2029
    provisional: 1
  Trinity 2030:
    start: 28/04/2030
    provisional: 1
  Trinity 2031:
    start: 27/04/2031
    provisional: 1
