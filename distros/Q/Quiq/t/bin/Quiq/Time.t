#!/usr/bin/env perl

package Quiq::Time::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Time');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(59) {
    my $self = shift;

    my ($msg,$ti,$ti2,$obj,$str);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new;
    $msg = 'new(): Zeit-Objekt ohne Argument instantiiert';
    $self->is($ti->dump,'1970-01-01-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(utc=>-1);
    $msg = 'new(): Aufruf mit negativem Epoch-Wert';
    $self->is($ti->dump,'1969-12-31-23-59-59',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,12,28,22,56,37);
    $msg = 'new(): Zeit-Objekt instantiiert';
    $self->is($ti->dump,'2005-12-28-22-56-37',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti2 = $ti->copy;
    $msg = 'copy(): Referenzen sind verschieden';
    $self->isnt($ti2,$ti,$msg);

    $msg = 'copy(): Zeit-Objekte sind gleich';
    $self->is($ti->dump,$ti2->dump,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $obj = $ti->truncate('D');
    $self->is($ti,$obj,'truncate(): liefere Zeit-Objekt');

    $msg = 'truncate(): Zeit-Objekt auf Tag gekürzt';
    $self->is($ti->dump,'2005-12-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28,22,56,37);
    $obj = $ti->addYears(5);
    $msg = 'addYears(): liefere Zeit-Objekt';
    $self->is($ti,$obj,$msg);

    $msg = 'addYears(): 5 Jahre addiert';
    $self->is($ti->dump,'2010-12-28-22-56-37',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28,22,56,37);
    $obj = $ti->addYears(-6);
    $msg = 'addYears(): -6 Jahre addiert';
    $self->is($ti->dump,'1999-12-28-22-56-37',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $obj = $ti->addMonths(1);
    $msg = 'addMonths(): liefere Zeit-Objekt';
    $self->is($ti,$obj,$msg);

    $msg = 'addMonths(): 1 Monat addiert';
    $self->is($ti->dump,'2006-01-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $ti->addMonths(12);
    $msg = 'addMonths(): 12 Monate addiert';
    $self->is($ti->dump,'2006-12-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $ti->addMonths(13);
    $msg = 'addMonths(): 13 Monate addiert';
    $self->is($ti->dump,'2007-01-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $ti->addMonths(-1);
    $msg = 'addMonths(): -1 Monat addiert';
    $self->is($ti->dump,'2005-11-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $ti->addMonths(-12);
    $msg = 'addMonths(): -12 Monate addiert';
    $self->is($ti->dump,'2004-12-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28);
    $ti->addMonths(-24);
    $msg = 'addMonths(): -24 Monate addiert';
    $self->is($ti->dump,'2003-12-28-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28,22,56,37);
    $obj = $ti->addDays(1);
    $msg = 'addDays(): liefere Zeit-Objekt';
    $self->is($ti,$obj,$msg);

    $msg = 'addDays(): 1 Tag addiert';
    $self->is($ti->dump,'2005-12-29-22-56-37',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,28,22,56,37);
    $obj = $ti->add(3,'Y',5,'M',-1,'D');
    $msg = 'add(): liefere Zeit-Objekt';
    $self->is($ti,$obj,$msg);

    $msg = 'add()';
    $self->is($ti->dump,'2009-05-27-22-56-37',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,31);
    $msg = 'dayOfWeek()';
    $self->is($ti->dayOfWeek,6,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,31);
    $msg = 'dayName()';
    $self->is($ti->dayName,'Samstag',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,12,31);
    $msg = 'dayAbbr()';
    $self->is($ti->dayAbbr,'Sa',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2004);
    $msg = 'isLeapyear(): Schaltjahr';
    $self->is($ti->isLeapyear,1,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005);
    $msg = 'isLeapyear(): kein Schaltjahr';
    $self->is($ti->isLeapyear,0,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2004,12);
    $msg = 'daysOfMonth(): Dezember';
    $self->is($ti->daysOfMonth,31,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2004,2);
    $msg = 'daysOfMonth(): Februar, Schaltjahr';
    $self->is($ti->daysOfMonth,29,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti->set(2005,2);
    $msg = 'daysOfMonth(): Februar, kein Schaltjahr';
    $self->is($ti->daysOfMonth,28,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31);
    $msg = 'yyyymmdd(): mit Default-Trenner';
    $self->is($ti->yyyymmdd,'2005-01-31',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31);
    $msg = 'yyyymmdd(): ohne Trenner';
    $self->is($ti->yyyymmdd(''),'20050131',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31);
    $msg = 'yymmdd(): mit Default-Trenner';
    $self->is($ti->yymmdd,'05-01-31',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31);
    $msg = 'yymmdd(): ohne Trenner';
    $self->is($ti->yymmdd(''),'050131',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,1,7,2);
    $msg = 'hhmmss(): mit Default-Trenner';
    $self->is($ti->hhmmss,'01:07:02',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,1,7,2);
    $msg = 'hhmmss(): ohne Trenner';
    $self->is($ti->hhmmss(''),'010702',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,1,7,2);
    $msg = 'setTime(): Stunden';
    $ti->setTime(23);
    $self->is($ti->dump,'2005-01-31-23-07-02',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,1,7,2);
    $msg = 'setTime(): Stunden, Minuten';
    $ti->setTime(23,59);
    $self->is($ti->dump,'2005-01-31-23-59-02',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,1,7,2);
    $msg = 'setTime(): Stunden, Minuten, Sekunden';
    $ti->setTime(23,59,59);
    $self->is($ti->dump,'2005-01-31-23-59-59',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,1,1,0,1);
    $msg = 'addHours(): positives Argument';
    $ti->addHours(5);
    $self->is($ti->dump,'2005-01-01-06-00-01',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,1);
    $msg = 'addHours(): negatives Argument';
    $ti->addHours(-1);
    $self->is($ti->dump,'2004-12-31-23-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,1);
    $msg = 'addSeconds(): positives Argument';
    $ti->addSeconds(61);
    $self->is($ti->dump,'2005-01-01-00-01-01',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,1);
    $msg = 'addSeconds(): negatives Argument';
    $ti->addSeconds(-1);
    $self->is($ti->dump,'2004-12-31-23-59-59',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(dmyhms=>'27.7.2005 7:12:13');
    $msg = 'new(): dmyhms=>"D.M.YYYY H:M:S"';
    $self->is($ti->dump,'2005-07-27-07-12-13',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = eval { Quiq::Time->new(dmyhms=>'x') };
    $msg = 'new(): dmyhms=>"D.M.YYYY H:M:S" - ungültige Angabe';
    $self->like($@,qr/TIME-00002/,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(dmy=>'27.7.2005');
    $msg = 'new(): dmy=>"D.M.YYYY"';
    $self->is($ti->dump,'2005-07-27-00-00-00',$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = eval { Quiq::Time->new(dmyhms=>'39.4.2001') };
    $msg = 'new(): dmy=>"D.M.YYYY" - ungültige Angabe';
    $self->like($@,qr/TIME-00002/,$msg);

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # parse
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'27.7.2005');
    $self->is($ti->dump,'2005-07-27-00-00-00','Quiq::Time: deutsches Datum');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'27.7.2005 17:23:56');
    $self->is($ti->dump,'2005-07-27-17-23-56','Quiq::Time: deutsche Zeit');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'7/27/2005');
    $self->is($ti->dump,'2005-07-27-00-00-00','Quiq::Time: amerikanisches Datum');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'7/27/2005 17:23:56');
    $self->is($ti->dump,'2005-07-27-17-23-56','Quiq::Time: amerikanische Zeit');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'2005-07-27');
    $self->is($ti->dump,'2005-07-27-00-00-00','Quiq::Time: ISO Datum');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(parse=>'2005-07-27 17:23:56');
    $self->is($ti->dump,'2005-07-27-17-23-56','Quiq::Time: ISO Zeit');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = eval { Quiq::Time->new(parse=>'1 4 2001') };
    $self->ok($@,'Quiq::Time: Datum kann nicht geparsed werden');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $ti = Quiq::Time->new(2005,1,31,12,27,9);
    my ($year,$month,$day,$hour,$minute,$second) = $ti->asArray;
    $self->is($year,2005);
    $self->is($month,1);
    $self->is($day,31);
    $self->is($hour,12);
    $self->is($minute,27);
    $self->is($second,9);
}

# -----------------------------------------------------------------------------

sub test_set : Test(1) {
    my $self = shift;

    my $ti = Quiq::Time->new;
    $ti->set(ymdhms=>'2008-12-5 14:26:11');
    my $val = $ti->yyyymmddhhmmss('+');
    $self->is($val,'2008-12-05+14:26:11','set: ymdhms');
}

# -----------------------------------------------------------------------------

sub test_year : Test(1) {
    my $self = shift;

    my $val = Quiq::Time->new(2005,1,1)->year;
    $self->is($val,2005,'year');
}

# -----------------------------------------------------------------------------

sub test_month : Test(1) {
    my $self = shift;

    my $val = Quiq::Time->new(2005,5,3)->month;
    $self->is($val,5,'month');
}

# -----------------------------------------------------------------------------

sub test_day : Test(1) {
    my $self = shift;

    my $val = Quiq::Time->new(2005,5,3)->day;
    $self->is($val,3,'day');
}

# -----------------------------------------------------------------------------

sub test_dayOfYear : Test(3) {
    my $self = shift;

    my $val = Quiq::Time->new(2005,1,1)->dayOfYear;
    $self->is($val,1);

    $val = Quiq::Time->new(2005,12,31)->dayOfYear;
    $self->is($val,365);

    $val = Quiq::Time->new(2004,12,31)->dayOfYear;
    $self->is($val,366);
}

# -----------------------------------------------------------------------------

sub test_weekOfYear : Test(16) {
    my $self = shift;

    my ($year,$week) = Quiq::Time->new(2017,1,1)->weekOfYear;
    $self->is($year,2016);
    $self->is($week,53);

    ($year,$week) = Quiq::Time->new(2017,1,2)->weekOfYear;
    $self->is($year,2017);
    $self->is($week,1);

    ($year,$week) = Quiq::Time->new(2017,1,11)->weekOfYear;
    $self->is($year,2017);
    $self->is($week,2);

    ($year,$week) = Quiq::Time->new(2016,1,1)->weekOfYear;
    $self->is($year,2015);
    $self->is($week,53);

    ($year,$week) = Quiq::Time->new(2016,1,4)->weekOfYear;
    $self->is($year,2016);
    $self->is($week,1);

    ($year,$week) = Quiq::Time->new(2016,1,11)->weekOfYear;
    $self->is($year,2016);
    $self->is($week,2);

    ($year,$week) = Quiq::Time->new(2015,1,1)->weekOfYear;
    $self->is($year,2015);
    $self->is($week,1);

    ($year,$week) = Quiq::Time->new(2015,1,5)->weekOfYear;
    $self->is($year,2015);
    $self->is($week,2);
}

# -----------------------------------------------------------------------------

sub test_strftime : Test(1) {
    my $self = shift;

    my $val = Quiq::Time->new(utc=>1)->strftime('%F %H:%M:%S');
    $self->is($val,'1970-01-01 00:00:01','strftime');
}

# -----------------------------------------------------------------------------

sub test_yyyymmddhhmmss : Test(2) {
    my $self = shift;

    my $val = Quiq::Time->new(utc=>0)->yyyymmddhhmmss;
    $self->is($val,'1970-01-01 00:00:00','yyyymmddhhmmss: ohne Trenner');

    $val = Quiq::Time->new(utc=>0)->yyyymmddhhmmss('+');
    $self->is($val,'1970-01-01+00:00:00','yyyymmddhhmmss: mit Trenner +');
}

# -----------------------------------------------------------------------------

sub test_yyyymmddxhhmmss : Test(1) {
    my $self = shift;

    my $val = Quiq::Time->new(utc=>1)->yyyymmddxhhmmss;
    $self->is($val,'1970-01-01+00:00:01','yyyymmddxhhmmss');
}

# -----------------------------------------------------------------------------

sub test_monthAbbrToNum : Test(3) {
    my $self = shift;

    my $n = Quiq::Time->monthAbbrToNum('May');
    $self->is($n,5);

    $n = eval{Quiq::Time->monthAbbrToNum('May','de')};
    $self->ok($@);

    $n = Quiq::Time->monthAbbrToNum('Mai','de');
    $self->is($n,5);

}

# -----------------------------------------------------------------------------

package main;
Quiq::Time::Test->runTests;

# eof
