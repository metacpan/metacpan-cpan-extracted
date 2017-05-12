#!/usr/bin/perl -w

# $Id: st_et.t,v 1.5 2006-08-14 12:25:11+10 sh1517 Exp sh1517 $

# $Log: st_et.t,v $
# Revision 1.5  2006-08-14 12:25:11+10  sh1517
# 1 Changed time_t values for 'Mar 2006' and 'Apr 2006'. The vals for the end of Mar and start
#   of Apr were (inexplicably) wrong (ie different to the dev machine).
#
# Revision 1.4  2006-08-12 12:32:51+10  sh1517
# 1 Added some tests for the new date selector (Mon YYYY).
#
# Revision 1.3  2005-11-30 22:14:41+11  sh1517
# 1 Add more tests for the time patterns based on 'at' times
#   under the __DEFAULT__ tag. All of these tests are hard to
#   understand (and prob wrong).
#
# Revision 1.2  2005-11-28 10:28:13+11  sh1517
# 1 Add tests for 'lastnhours' and 'lastndays'.
#
# Revision 1.1  2005-11-12 20:09:22+11  sh1517
# Initial revision
#

use Test;

use Nagios::Report ;
use Time::Local ;
use constant {
               SEC   => 0,
               MIN   => 1,
               HOUR  => 2,
               MDAY  => 3,
               MON   => 4,
               YEAR  => 5,
               WDAY  => 6,
               YDAY  => 7,
               ISDST => 8,
};



# Each element in this array is a single test. Storing them this way makes
# maintenance easy, and should be OK since perl should be pretty functional
# before these tests are run.

$tests = <<'EOTESTS' ;
# Scalar expression 
# 1==1,

@t = localtime; ($t1, $t2) = $st_et{today}->('', \@t); $t2 - $t1 == time() - timelocal(0, 0, 0, $t[MDAY], $t[MON], $t[YEAR])
($t1, $t2) = $st_et{last24hours}->('', \@t);          $t2 - $t1 == 1 * 86_400
($t1, $t2) = $st_et{last12hours}->('', \@t);          $t2 - $t1 == 1 * 86_400 >> 1
($t1, $t2) = $st_et{__DEFAULT__}->('last0hours', \@t);$t2 - $t1 == 0
($t1, $t2) = $st_et{__DEFAULT__}->('last2hours', \@t);$t2 - $t1 == 2 * 3_600
($t1, $t2) = $st_et{__DEFAULT__}->('last2days', \@t); $t2 - $t1 == 2 * 86_400

# Set @t to whatever time/date to compare with the arg of $st_et.
# The st_et functions return the interval between sometime before now, the first arg, 
# and 'now', the second arg.

@t = localtime(timelocal(0, 30, 20, $t[MDAY], $t[MON], $t[YEAR])); ($t1, $t2) = $st_et{__DEFAULT__}->('20:30', \@t); $t2 - $t1 == 0
@t = localtime(timelocal(0, 30, 20, $t[MDAY], $t[MON], $t[YEAR])); ($t1, $t2) = $st_et{__DEFAULT__}->('2030', \@t);  $t2 - $t1 == 0

# Urrgh

@t = localtime(timelocal(0, 0, 0, $t[MDAY], $t[MON], $t[YEAR]) + 86_400); $d = substr("0$t[MDAY]", -2, 2) . "." . substr("0" . ($t[MON] + 1), -2, 2) . "." . (1900+$t[YEAR]); ($t1, $t2) = $st_et{__DEFAULT__}->($d, \@t);  $t2 - $t1 == 0
@t = localtime(timelocal(0, 0, 0, $t[MDAY], $t[MON], $t[YEAR]) + 86_400); $d = substr("0" . ($t[MON] + 1), -2, 2) . "/" . substr("0$t[MDAY]", -2, 2) . "/" . (1900+$t[YEAR]); ($t1, $t2) = $st_et{__DEFAULT__}->($d, \@t);  $t2 - $t1 == 0
@t = localtime(timelocal(0, 30, 20, $t[MDAY], $t[MON], $t[YEAR])); $d = '20:30 ' . substr("0$t[MDAY]", -2, 2) . "." . substr("0" . ($t[MON] + 1), -2, 2) . "." . (1900+$t[YEAR]); ($t1, $t2) = $st_et{__DEFAULT__}->($d, \@t);  $t2 - $t1 == 0
@t = localtime(timelocal(0, 30, 20, $t[MDAY], $t[MON], $t[YEAR])); $d = '2030 ' . substr("0" . ($t[MON] + 1), -2, 2) . "/" . substr("0$t[MDAY]", -2, 2) . "/" . (1900+$t[YEAR]); ($t1, $t2) = $st_et{__DEFAULT__}->($d, \@t);  $t2 - $t1 == 0


# Differ across architectures/Perl versions. Impossible to maintain. 
# See st_et_2.t

# ($t1, $t2) = $st_et{__DEFAULT__}->("Jan 2006", [localtime]); $t1 == 1136034000 && $t2 == 1138712399;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Feb 2006", [localtime]); $t1 == 1138712400 && $t2 == 1141131599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Mar 2006", [localtime]); $t1 == 1141131600 && ($t2 == 1143813599 || $t2 == 1143809999);
# ($t1, $t2) = $st_et{__DEFAULT__}->("Apr 2006", [localtime]); ($t1 == 1143813600 || 1143810000) && $t2 == 1146405599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("May 2006", [localtime]); $t1 == 1146405600 && $t2 == 1149083999;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Jun 2006", [localtime]); $t1 == 1149084000 && $t2 == 1151675999;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Jul 2006", [localtime]); $t1 == 1151676000 && $t2 == 1154354399;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Aug 2006", [localtime]); $t1 == 1154354400 && $t2 == 1157032799;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Sep 2006", [localtime]); $t1 == 1157032800 && $t2 == 1159624799;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Oct 2006", [localtime]); $t1 == 1159624800 && $t2 == 1162299599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Nov 2006", [localtime]); $t1 == 1162299600 && $t2 == 1164891599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Dec 2006", [localtime]); $t1 == 1164891600 && $t2 == 1167569999;


($t1, $t2) = $st_et{__DEFAULT__}->("Jan 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Feb 2006", [localtime]); localtime($t2) =~ /28 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Mar 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Apr 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("May 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Jun 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Jul 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Aug 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Sep 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Oct 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Nov 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/
($t1, $t2) = $st_et{__DEFAULT__}->("Dec 2006", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2006$/


# ($t1, $t2) = $st_et{__DEFAULT__}->("Jan 2000", [localtime]); $t1 == 946645200 && $t2 == 949323599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Feb 2000", [localtime]); $t1 == 949323600 && $t2 == 951829199;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Mar 2000", [localtime]); $t1 == 951829200 && $t2 == 954511199;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Apr 2000", [localtime]); $t1 == 954511200 && $t2 == 957103199;
# ($t1, $t2) = $st_et{__DEFAULT__}->("May 2000", [localtime]); $t1 == 957103200 && $t2 == 959781599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Jun 2000", [localtime]); $t1 == 959781600 && $t2 == 962373599;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Jul 2000", [localtime]); $t1 == 962373600 && $t2 == 965051999;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Aug 2000", [localtime]); $t1 == 965052000 && $t2 == 967726799;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Sep 2000", [localtime]); $t1 == 967726800 && $t2 == 970318799;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Oct 2000", [localtime]); $t1 == 970318800 && $t2 == 972997199;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Nov 2000", [localtime]); $t1 == 972997200 && $t2 == 975589199;
# ($t1, $t2) = $st_et{__DEFAULT__}->("Dec 2000", [localtime]); $t1 == 975589200 && $t2 == 978267599;


($t1, $t2) = $st_et{__DEFAULT__}->("Jan 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Feb 2000", [localtime]); localtime($t2) =~ /29 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Mar 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Apr 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("May 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Jun 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Jul 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Aug 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Sep 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Oct 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Nov 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/
($t1, $t2) = $st_et{__DEFAULT__}->("Dec 2000", [localtime]); localtime($t2) =~ /(?:30|31) 23:59:59 2000$/

EOTESTS

@t = split /\n/, $tests ;
@tests = grep !( m<\s*#> or m<^\s*$> ), @t ;

plan tests => scalar(@tests) ;
# plan tests => scalar(@tests) + 1 ;


for ( @tests ) {

  $sub = eval "sub { $_ }" ;

  warn "sub { $_ } fails to compile: $@"
    if $@ ;

  ok $sub  ;

  1 ;
}

