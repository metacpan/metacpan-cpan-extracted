#!/usr/bin/perl
#
use strict;
use warnings;

use Benchmark qw(cmpthese);
use DateTime::Format::HTTP;
use HTTP::Date;
use Time::Moment;
use Time::Piece;
use YAML;

my %dates;
while(<DATA>) {
    chomp;
    my ($str,$epoch) = split /\|/;

    $dates{$str} = $epoch;
}

my %converters = (
    DateTimeHTTP => sub {
        my ($str) = @_;
        my $dt = DateTime::Format::HTTP->parse_datetime($str);
        return $dt->epoch;
    },
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
        my $tp = Time::Piece->strptime($str,'%b %d %H:%M:%S');
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
print "Results\n", Dump(\%results);
__DATA__
Jan  1 13:15:45|1451682945
