package PlotCalendar::DateDesc;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( getdates getdom);

$VERSION = sprintf "%d.%02d", q$Revision: 1.0 $ =~ m#(\d+)\.(\d+)#;

use Carp;
use PlotCalendar::DateTools qw(Add_Delta_Days Day_of_Week Day_of_Year Days_in_Month Decode_Day_of_Week Day_of_Week_to_Text Month_to_Text);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

        #  Values to apply to all cells

     $self->{MONTH} = shift; # Month (1-12)
     $self->{YEAR} = shift; # 4 digit (yes, we are y2k compliant)

    bless $self, $class;

     return $self;

}

# ****************************************************************
sub getdates {
    my $self = shift;
     my $desc = shift;

     my @doms = parse_desc($self,$desc);

     my $mm = $self->{MONTH};
     my $yy = $self->{YEAR};

     my @dates = map {$mm . "/" . $_ . "/" . $yy} @doms;

     return \@dates
}

# ****************************************************************
sub getdom {
    my $self = shift;
     my $desc = shift;

     my @doms = parse_desc($self,$desc);

     return \@doms;
}

# ****************************************************************
sub parse_desc {
    #    parse the descriptions
    my $self = shift;
    my $desc = shift;

    my %ords = ( 'first'  => '0',
                 'second' => '1',
             'third'  => '2',
             'fourth' => '3',
             'fifth'  => '4',
             'last'   => '-1',
              );
    my @doms;
    my $component;
    foreach $component ( (split(/ and /,$desc))) { # split on 'and'
        # this is either a single dayname or a qualified dayname
        $component =~ s/^\s*//;
        $component =~ s/\s*$//;
        my @desc = (split(/\s+/,$component));
        my @temp = days_of_month($self->{YEAR},$self->{MONTH},$desc[$#desc]);
        if ($#desc == 0) { # just a dayname
            push @doms,@temp;
        }
        else { # dayname and qualifier
            push @doms,$temp[$ords{$desc[0]}];
        }
    }
    return @doms;
}

# ****************************************************************
sub days_of_month {
    my ($yr, $mon, $dayname) = @_;
    my $dow = Decode_Day_of_Week($dayname);
    my $dowfirst = Day_of_Week($yr,$mon,1);
    my $days = Days_in_Month($yr,$mon);

    my @dom;

    my $first = Add_Delta_Days($yr,$mon,1, ($dow - $dowfirst)%7);
    $dom[0]=$first;
    my $j=7;
    for (my $i=7+$first;$i<=$days;$i+=7) {
        push @dom,$first+$j;
        $j+=7;
    }

    return @dom;
    
}


1;
__END__

=head1 NAME

PlotCalendar::DateDesc - Perl extension for interpreting a file of
                         periodic (like weekly) events and assigning
                         actual dates to them. Used to feed the
                         calendar plotting software.

=head1 SYNOPSIS

  require PlotCalendar::DateDesc;

  my ($month, $year) = (3,1999);

    # ----    set the month and year
  my $trans = PlotCalendar::DateDesc->new($month, $year);

    # ----    parse a description and return the day of the month
    my $day = 'first monday and third monday';
   print "$day : ",join(',',@{$trans->getdom($day)}),"\n";

   $day = 'last monday and third monday';
   print "$day : ",join(',',@{$trans->getdom($day)}),"\n";

   $day = 'last fri and third Monday';
   print "$day : ",join(',',@{$trans->getdom($day)}),"\n";

    # ----    parse a description and return the date as mm/dd/yyyy
   $day = 'last fri and third Monday';
    print "$day dates: ", join(',',@{$trans->getdates($day)}),"\n";

    What gets returned by both routines is a pointer to an array of answers
  

=head1 DESCRIPTION

    input descriptions may be one of :
    a day of the week (monday, tuesday, etc)
    a qualified day of the week (first monday, second tuesday, last sunday)
    compound statements are allowed : mon and wed, first mon and third mon

    Qualifiers are : first, second, third, fourth, fifth, last
    Compounds are only formed with 'and' and are not associative

=head1 AUTHOR

    Alan Jackson
    March 1999
    ajackson@icct.net

=head1 SEE ALSO

PlotCalendar::Month
PlotCalendar::Day

=cut
