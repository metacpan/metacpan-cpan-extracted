#!/usr/bin/perl
#
use strict;
use warnings;

use Benchmark qw(cmpthese);
use Data::Dumper;
use HTTP::Date;
use Time::Moment;
use Time::Piece;

my %dates;
while(<DATA>) {
    chomp;
    my ($str,$epoch) = split /\|/;

    $dates{$str} = $epoch;
}

my %converters = (
    TimeMoment => sub {
        my ($str) = @_;
        my $tm = Time::Moment->from_string( $str, lenient => 1 );
        return $tm->epoch;
    },
    HTTPDate => sub {
        my ($str) = @_;
        return HTTP::Date::str2time( $str );
    },
    TimePiece => sub {
        my ($str) = @_;
        # Normalize to the strptime format
        $str =~ s/(\d{2})\.\d{3,6}/$1/;
        $str =~ s/([+\-])(\d{2}):?(\d{2})$/$1$2$3/;
        $str =~ s/ /T/;
        my $tp = Time::Piece->strptime($str,'%Y-%m-%dT%H:%M:%S%z');
        return $tp->epoch;
    },
);

my %results = ();
my %tests = ();
foreach my $k (keys %converters) {
    $tests{$k} = sub {
        foreach my $date (sort keys %dates) {
            my $epoch;
            eval {
                $epoch = int $converters{$k}->($date);
            };
            my $status = defined $epoch ? ($dates{$date} == $epoch ? 'right' : 'wrong') : 'fail';
            $results{$k} ||= {};
            $results{$k}->{$status}++;
        }
    }
}


cmpthese(50_000, \%tests);
print "Results\n", Dumper(\%results);

__DATA__
2013-08-09T11:09:36+02:00|1376039376
2013-08-09 11:09:36+02:00|1376039376
2015-09-30T06:26:06.779373-05:00|1443612366
2015-09-30 06:26:06.779373-05:00|1443612366
