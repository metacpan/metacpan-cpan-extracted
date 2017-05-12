package No::Dato;

use Time::Local qw(timelocal);
use Carp ();

require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK = qw(tekstdato helligdag hverdag helligdager @UKEDAGER @MANEDER);

use strict;
use vars qw(%SPECIAL_DAYS @UKEDAGER @MANEDER $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);


=head1 NAME

No::Dato - Norwegian dates

=head1 SYNOPSIS

  use No::Dato qw(tekstdato helligdag helligdager);

  print tekstdato(time), "\n";
  if (helligdag(time)) {
      print "Idag er det ", helligdag(time), "\n";
  }

  for (helligdager()) {
      print "$_\n";
  }


=head1 DESCRIPTION

B<This documentation is written in Norwegian.>

Denne modulen tilbyr funksjoner for Â hÂndtere det som er spesielt med
datoer pÂ norsk.  Dette gjelder blant annet Â identifisere offentlige
h¯ytidsdager.

F¯lgende funksjoner er tilgjengelig:

=over

=cut




%SPECIAL_DAYS = (
  "nyttÂrsdag"            => '01-01',
  "1. mai"                => '05-01',
  "grunnlovsdag"          => '05-17',
  "juledag"               => '12-25',
  "2. juledag"            => '12-26',

  # relative to easter day
  "skjÊrtorsdag"          => -3,
  "langfredag"            => -2,
  "pÂskedag"              =>  0,
  "2. pÂskedag"           => +1,
  "kristi himmelfartsdag" => +39,
  "pinsedag"              => +49,
  "2. pinsedag"           => +50,
);

@UKEDAGER = qw(s¯ndag mandag tirsdag onsdag torsdag fredag l¯rdag);
@MANEDER = qw(januar februar mars      april   mai      juni
              juli   august  september oktober november desember);

my %hellig_cache = ();


=item tekstdato($time)

Denne rutinen returnerer en dato formatert pÂ formen:

  fredag, 7. februar 2004

Argumentet er en vanlig perl $time verdi.  Hvis argumentet utelates sÂ
benyttes dagens dato.

=cut

sub tekstdato (;$)
{
    my $time = shift || time;
    my($d,$m,$y,$wd) = (localtime $time)[3,4,5,6];
    sprintf "%s, %d. %s %d", $UKEDAGER[$wd], $d, $MANEDER[$m], $y+1900;
}


=item helligdag($time)

Rutinen avgj¯r om en gitt dato er en norsk helligdag eller ikke.  Hvis
det er en helligdag sÂ vil navnet pÂ helligdagen bli returnert.  Hvis
det er en vanlig hverdag eller l¯rdag sÂ vil en tom streng (som er
FALSE i perl) bli returnert.

Argumentet kan vÊre en vanlig $time verdi eller en streng pÂ formen
"≈≈≈≈-MM-DD".

For denne funksjonen er "helligdag" definert til Â vÊre det samme som
norsk offentlig h¯ytidsdag samt s¯ndager, dvs de dagene som er r¯de pÂ
kalenderen.  Dette inkluderer nyttÂrsdagen, samt 1. og 17. mai selv om
disse egentlig ikke er hellige.

=cut

sub helligdag (;$$)
{
    my $date = shift || time;
    my $year;
    my $weekday;
    if ($date =~ /^\d+$/) {
	my($d,$m,$y,$w) = (localtime $date)[3,4,5,6];
	$year = $y+1900;
	$weekday = $w;
	$date = sprintf "%02d-%02d", $m+1, $d;
    } elsif ($date =~ s/^(\d{4})-(\d\d-\d\d)$/$2/) {
	$year = $1;
    } else {
        Carp::croak("Bad date '$date'");
    } 
    helligdager($year) unless exists $hellig_cache{$year};
    my $day = "";
    if (exists $hellig_cache{$year}{$date}) {
	$day = $hellig_cache{$year}{$date};
    } else {
	# sjekk om det er s¯ndag
	unless (defined $weekday) {
	    my($m, $d) = split(/-/, $date);
	    $weekday = (localtime(timelocal(12,0,0,$d, $m-1, $year-1900)))[6];
        }
        $day = "s¯ndag" if $weekday == 0;
	$day = "l¯rdag" if $weekday == 6 && $_[0];
    }
    $day;
}

=item hverdag($time)

Rutinen avgj¯r om en gitt date er en hverdag eller ikke.  L¯rdag er
her ikke regnet som hverdag.

Argumentet kan vÊre en vanlig $time verdi eller en streng pÂ formen
"≈≈≈≈-MM-DD".

=cut

sub hverdag {
    return !helligdag(shift, 1);
}

=item helligdager($year)

Denne rutinen vil returnere en liste av datostrenger, Èn for hver
helligdag i Âret gitt som argument.  Hvis argumentet mangler vil vi
bruke innevÊrende Âr.  Datostrengene er pÂ formen:

   "≈≈≈≈-MM-DD skjÊrtorsdag"

Dvs. datoen formatert i henhold til ISO 8601 etterfulgt av navnet pÂ
helligdagen.  Listen vil vÊre sortert pÂ dato.

For denne funksjonen er "helligdag" definert til Â vÊre det samme som
norsk offentlig h¯ytidsdag.  S¯ndagene er ikke tatt med selv om
funksjonen helligdag(), beskrevet over, er TRUE for disse.

=cut

sub helligdager (;$)
{
    my $year = shift || (localtime)[5] + 1900;

    unless (exists $hellig_cache{$year}) {
	my $easter = easter_day($year);

	my ($text, $date);
	while (($text, $date) = each %SPECIAL_DAYS) {
	    my($month, $mday);
	    if ($date =~ /^(\d+)-(\d+)$/) {
		# a fixed date
		($month, $mday) = ($1, $2);
	    } else {
		($month, $mday) = dayno_to_date($year, $easter + $date);
	    }
	    $hellig_cache{$year}{sprintf "%02d-%02d", $month, $mday} = $text;
	}
    }

    # we want to return a sorted array
    my @days;
    for (sort keys %{$hellig_cache{$year}}) {
	push(@days, "$year-$_ $hellig_cache{$year}{$_}");
    }
    @days;
}



sub easter_day ($)
{
    use integer;
    # The algoritm is taken from LaTeX calendar macros by  C. E. Chew, which
    # has taken the algoritm from "The Calculation of Easter", D.E.Knuth,
    # CACM April 1962 p 209.

    my $year = shift;
    my $golden;                      # year in Mentonic cycle
    my $easter;                      # easter sunday
    my $grCor;                       # Gregorian correction
    my $clCor;                       # Clavian correction
    my $epact;                       # age of calendar moon at start of year
    my $century;
    my $extra;                       # when Sunday occurs in March

    $golden = ($year / 19) * -19 + $year + 1;
    if ($year > 1582) {
	$century = ($year / 100) + 1;
	$grCor = ($century * 3) / -4 + 12;
	$clCor = (($century - 18)/ -25 + $century - 16) / 3;
	$extra = ($year * 5) / 4 + $grCor - 10;
	$epact = $golden * 11 + 20 + $clCor + $grCor;
	$epact += ($epact / 30) * -30;
	$epact += 30 if $epact <= 0;
	if ($epact == 25) {
	    $epact++ if $golden > 11;
	} else {
	    $epact++ if $epact == 24;
	}
    } else {                              # year <= 1582
	$extra = ($year * 5) / 4;
	$epact = ($golden * 11) - 4;
	$epact += ($epact / 30) * -30 + 1;
    }
    $easter = -$epact + 44;
    $easter += 30 if $easter < 21;
    $extra += $easter;
    $extra += ($extra / 7) * -7;
    $extra = -$extra;
    $easter += $extra + 7;
    # easter is now a date in march

    # convert to a dayno relative to 1. jan
    $easter += 31 + 28;   # days in january and february
    $easter++ if leap_year($year);
    $easter;
}


sub leap_year ($)
{
    my $year = shift;
    (($year % 4 == 0) && ($year % 100 != 0)) || ($year % 400 == 0);
}


sub dayno_to_date($$)
{
    my($year, $dayno) = @_;
    my @days_pr_month = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $maxdayno = 365;
    if (leap_year($year)) {
	$days_pr_month[1]++;
	$maxdayno++;
    }
    die "Dayno $dayno out of range" if $dayno < 1 || $dayno > $maxdayno;

    my $month = 1;
    while ($dayno > $days_pr_month[0]) {
	$month++;
	$dayno -= shift @days_pr_month;
    }

    ($month, $dayno);
}

1;
__END__

=back

=head1 SEE ALSO

L<HTTP::Date>, som kan konvertere til og fra ISO 8601 formaterte
datoer (≈≈≈≈-MM-DD).

=head1 AUTHOR

Gisle Aas <gisle@aas.no>

=cut
