#!/usr/bin/perl
#Copyright 2007-10 Arthur S Goldstein
use Parse::Stallion;
use Time::Local;

my %rule;
$rule{start_date} =
  A('parsed_date', 'end_of_string',
   E(sub {
    my $seconds_since_epoch = $_[0]->{parsed_date};
    my ($seconds, $minutes, $hour, $mday, $month, $year) =
     localtime($seconds_since_epoch);
    $month++;  #Have January be 01 instead of 00.
    if ($month < 10) { $month = '0'.$month;};
    if ($mday < 10) { $mday = '0'.$mday;};
    if ($seconds < 10) { $seconds = '0'.$seconds;};
    if ($minutes < 10) { $minutes = '0'.$minutes;};
    if ($hour < 10) { $hour = '0'.$hour;};
    return (1900+$year).$month.$mday.$hour.$minutes.$seconds;
  })
);
$rule{parsed_date} =
  O('date', 'date_operation');
$rule{date_operation} =
  O('add_time', 'subtract_time');
$rule{add_time} =
  A('date', 'plus', 'time',
   E(sub {return $_[0]->{date} + $_[0]->{time}}))
;
$rule{subtract_time} =
  A('date', 'minus', 'time',
   E(sub {
   return $_[0]->{date} - $_[0]->{time}})
);
$rule{date} =
  O('standard_date', 'special_date');
$rule{end_of_string} = qr/\z/;
$rule{plus} = qr/\s*\+\s*/;
$rule{minus} = qr/\s*\-\s*/;
$rule{standard_date} =
  L(qr(\d+\/\d+\/\d+),
   E(sub {my $date = $_[0];
    $date =~ /(\d+)\/(\d+)\/(\d+)/;
    my $month = $1 -1;
    my $mday = $2;
    my $year = $3;
    return timelocal(0,0,0,$mday, $month, $year);
  })
);
$rule{special_date} =
  L(qr/now/i,
   E(sub {return time;})
);
$rule{time} =
  O('just_time', 'just_time_plus_list', 'just_time_minus_list'
);
$rule{just_time_plus_list} =
  A('just_time', 'plus', 'time',
   E(sub {return $_[0]->{just_time} + $_[0]->{time}})
);
$rule{just_time_minus_list} =
  A('just_time', 'minus', 'time',
   E(sub {return $_[0]->{just_time} - $_[0]->{time}})
);
$rule{just_time} = L(
  qr(\d+\s*[hdms])i,
  E(sub {
    my $to_match = $_[0];
    $to_match =~ /(\d+)\s*([hdms])/i;
    my $number = $1;
    my $unit = $2;
    if (lc $unit eq 'h') {
      return $1 * 60 * 60;
    }
    if (lc $unit eq 'd') {
      return $1 * 24 * 60 * 60;
    }
    if (lc $unit eq 's') {
      return $1;
    }
    if (lc $unit eq 'm') {
      return $1 * 60;
    }
  })
);

my $date_parser = new Parse::Stallion(\%rule);

$result = $date_parser->parse_and_evaluate("now");
print "now is $result\n";

$result = $date_parser->parse_and_evaluate("now - 30s");
print "now minus 30 seconds is $result\n";

$result = $date_parser->parse_and_evaluate("now + 70h");
print "now plus 70 hours is $result\n";

$result = $date_parser->parse_and_evaluate("now + 70H + 45s");
print "now plus 70 hours and 45 seconds is $result\n";

$result = $date_parser->parse_and_evaluate(
 "6/6/2008 + 2d + 3h");
print "2 days and 3 hours after 6/6/2008 is $result\n";

my $q = {'a'=>3, 'b'=>1};
my $ph = {};
$result = $date_parser->parse_and_evaluate(
 "6/6/2008 + 2d + 3h", {parse_hash => $ph});
print "2 days and 3 hours after 6/6/2008 is $result\n";

#use Data::Dumper;
#print Dumper($ph);
#print "\n";
#print Dumper($q);
#print "\n";

print "\nAll done\n";


