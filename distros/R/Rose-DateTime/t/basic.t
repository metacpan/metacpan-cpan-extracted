#!/usr/bin/perl -w

use strict;

use Test::More tests => 5531;

BEGIN 
{
  use_ok('Rose::DateTime::Util');
  use_ok('DateTime');
}

use Rose::DateTime::Util qw(:all); # test import

# Test to see if we can creat local DateTimes
eval { DateTime->now(time_zone => 'local') };

# Use UTC if we can't
Rose::DateTime::Util->time_zone('UTC')  if($@);

#
# parse_date()
#

my $dt1 = DateTime->new(month => 2, day => 3, year => 2004, 
                        hour  => 13, minute => 34, second => 56,
                        time_zone => Rose::DateTime::Util->time_zone);

my $dt2 = DateTime->new(month => 2, day => 3, year => 2004, 
                        hour  => 13, minute => 34, second => 56,
                        nanosecond => '123456789',
                        time_zone => Rose::DateTime::Util->time_zone);

my $dt3 = DateTime->new(month => 2, day => 3, year => 2004, 
                        hour  => 13, minute => 34, second => 56,
                        nanosecond => '1234',
                        time_zone => Rose::DateTime::Util->time_zone);

my $dt4 = DateTime->new(month => 2, day => 3, year => 2004, 
                        hour  => 13, minute => 34, second => 56,
                        nanosecond => '123400000',
                        time_zone => Rose::DateTime::Util->time_zone);

Rose::DateTime::Util->european_dates(0);

# mm/dd/yyyy [hh:mm[:ss[.nnnnnnnnn]]] [am/pm]
foreach my $month (qw(2 02))
{
  foreach my $day (qw(3 03))
  {
    foreach my $hour (qw(1 01))
    {
      foreach my $fsec ('', '.', '.0', '.123456789')
      {
        foreach my $sep ('-', '/', '.')
        {
          foreach my $sep3 ('', ' ')
          {
            foreach my $pm ('Pm', 'p.M.')
            {
              my $arg = "$month$sep$day${sep}2004 $hour:34:56$fsec$sep3$pm";

              my $d = parse_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                #elsif($fsec =~ /4$/)
                #{
                #  ok($d == $dt3, "$arg 2");
                #}
                #elsif($fsec =~ /4$/)
                #{
                #  ok($d == $dt3, "$arg 2");
                #}
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }

              $arg = "$month$sep$day${sep}2004 13:34:56$fsec";

              $d = Rose::DateTime::Util::parse_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                #elsif($fsec =~ /4$/)
                #{
                #  ok($d == $dt3, "$arg 2");
                #}
                #elsif($fsec =~ /4$/)
                #{
                #  ok($d == $dt3, "$arg 2");
                #}
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }
            }
          }
        }
      }
    }
  }
}

# dd/mm/yyyy [hh:mm[:ss[.nnnnnnnnn]]] [am/pm]
foreach my $month (qw(2 02))
{
  foreach my $day (qw(3 03))
  {
    foreach my $hour (qw(1 01))
    {
      foreach my $fsec ('', '.', '.0', '.123456789')
      {
        foreach my $sep ('-', '/', '.')
        {
          foreach my $sep3 ('', ' ')
          {
            foreach my $pm ('Pm', 'p.M.')
            {
              my $arg = "$day$sep$month${sep}2004 $hour:34:56$fsec$sep3$pm";

              my $d = parse_european_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }

              $arg = "$day$sep$month${sep}2004 13:34:56$fsec";

              $d = Rose::DateTime::Util::parse_european_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }
            }
          }
        }
      }
    }
  }
}

# dd/mm/yyyy [hh:mm[:ss[.nnnnnnnnn]]] [am/pm] (implicit European mode)
is(Rose::DateTime::Util->european_dates, 0, 'european_dates() 1');
is(Rose::DateTime::Util->european_dates('foo'), 1, 'european_dates() 2');

foreach my $month (qw(2 02))
{
  foreach my $day (qw(3 03))
  {
    foreach my $hour (qw(1 01))
    {
      foreach my $fsec ('', '.', '.0', '.123456789')
      {
        foreach my $sep ('-', '/', '.')
        {
          foreach my $sep3 ('', ' ')
          {
            foreach my $pm ('Pm', 'p.M.')
            {
              my $arg = "$day$sep$month${sep}2004 $hour:34:56$fsec$sep3$pm";

              my $d = Rose::DateTime::Util::parse_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }

              $arg = "$day$sep$month${sep}2004 13:34:56$fsec";

              $d = Rose::DateTime::Util::parse_date($arg);

              ok($d && $d->isa('DateTime'), "$arg");

              SKIP:
              {
                skip("Failed to parse '$arg'", 1)  unless($d);

                if(index($fsec, '9') > 0)
                {
                  ok($d == $dt2, "$arg 2");
                }
                else
                {
                  ok($d == $dt1, "$arg 2");
                }
              }
            }
          }
        }
      }
    }
  }
}

is(Rose::DateTime::Util->european_dates(''), 0, 'european_dates() 3');

# yyyy-mm-dd [hh:mm[:ss[.nnnnnnnnn]]] [am/pm]
foreach my $hour (qw(1 01))
{
  foreach my $fsec ('', '.', '.0', '.123456789')
  {
    foreach my $sep ('-', '')
    {
      foreach my $sep3 ('', ' ')
      {
        foreach my $pm ('Pm', 'p.M.')
        {
          foreach my $sep4 ('', ' ', '-')
          {
            my $arg = "2004${sep}02${sep}03${sep4}$hour:34:56$fsec$sep3$pm";

            my $d = Rose::DateTime::Util::parse_date($arg);

            ok($d && $d->isa('DateTime'), "$arg");

            SKIP:
            {
              skip("Failed to parse '$arg'", 1)  unless($d);

              if(index($fsec, '9') > 0)
              {
                ok($d == $dt2, "$arg 2");
              }
              #elsif($fsec =~ /4$/)
              #{
              #  ok($d == $dt3, "$arg 2");
              #}
              #elsif($fsec =~ /4/)
              #{
              #  ok($d == $dt3, "$arg 2");
              #}
              else
              {
                ok($d == $dt1, "$arg 2");
              }
            }

            $arg = "2004${sep}02${sep}03${sep4}13:34:56$fsec";

            $d = Rose::DateTime::Util::parse_date($arg);

            ok($d && $d->isa('DateTime'), "$arg");

            SKIP:
            {
              skip("Failed to parse '$arg'", 1)  unless($d);

              if(index($fsec, '9') > 0)
              {
                ok($d == $dt2, "$arg 2");
              }
              #elsif($fsec =~ /4$/)
              #{
              #  ok($d == $dt3, "$arg 2");
              #}
              #elsif($fsec =~ /4/)
              #{
              #  ok($d == $dt4, "$arg 2");
              #}
              else
              {
                ok($d == $dt1, "$arg 2");
              }
            }
          }
        }
      }
    }
  }
}

my $d = parse_date('1/2/2003 8am');
my $d2 = parse_date('1/2/2003 8:00:00.000000000 AM');

ok($d == $d2, 'parse_date(m/d/yyyy ham)');
$d2 = parse_date('2003-01-02 8:00:00.000000000 AM');

ok($d == $d2, 'parse_date(m/d/yyyy ham) 2');

my $now    = parse_date('now');
my $dt_now = DateTime->now->truncate(to => 'minute');

ok($now && $now->isa('DateTime'), 'now');

# Time marches on; did we cross minute?
if($now)
{
  $now->truncate(to => 'minute');
  $now = parse_date('now')->truncate(to => 'minute')
    unless ($now == $dt_now);
}

is($now, $dt_now, 'now is current');

my $today    = parse_date('today');
my $dt_today = DateTime->now->truncate(to => 'day');

ok($today && $today->isa('DateTime'), 'today');

# Similarly for midnight
if($today and $today != $dt_today)
{
  $today = parse_date('today');
}

is($today, $dt_today, 'today is current');

my $inf  = parse_date('infinity');
my $ninf = parse_date('-infinity');

is(format_date($inf), 'infinity', 'format infinity');
is(format_date($ninf), '-infinity', 'format -infinity');

my $arg = '1/2/2003 12:34:56.001';
$d = parse_date($arg);
ok($d && $d->isa('DateTime'), $arg);
is($d->nanosecond, '001000000', 'Nanoseconds 1');

$arg = '1/2/2003 12:34:56.100';
$d = parse_date($arg);
ok($d && $d->isa('DateTime'), $arg);
is($d->nanosecond, 100000000, 'Nanoseconds 2');

$d = parse_date($arg, 'floating');
ok($d && $d->isa('DateTime'), $arg);
is($d->time_zone->name, 'floating', 'parse_date() time zone floating');

$d = parse_date($arg, 'UTC');
ok($d && $d->isa('DateTime'), $arg);
is($d->time_zone->name, 'UTC', 'parse_date() time zone UTC');

$d2 = parse_date($d);
ok($d2 && $d2->isa('DateTime') && $d2 eq $d, 'parse_date(DateTime)');

$d2 = parse_date($d, 'floating');
ok($d2 && $d2->isa('DateTime') && $d2->time_zone->name eq 'floating', 'parse_date(DateTime, TZ) 2');

$d2 = parse_date('.');
ok(!defined $d2, 'parse_date(.)');

$d2 = parse_date('.123');
is($d2->strftime('%Y-%m-%d %H:%M:%S.%N'), '1970-01-01 00:00:00.123000000', 'parse_date(.123)');

$d2 = parse_date('1.123');
is($d2->strftime('%Y-%m-%d %H:%M:%S.%N'), '1970-01-01 00:00:01.123000000', 'parse_date(1.123)');

$d2 = parse_date('19991201');
is($d2->strftime('%Y-%m-%d'), '1999-12-01', 'parse_date(19991201)');

$d2 = parse_epoch('19991201');
is($d2->strftime('%Y-%m-%d'), '1970-08-20', 'parse_date(parse_epoch)');

$d2 = parse_date($d, 'nonesuchasdf');
ok(!defined $d2, 'parse_date(DateTime, invalid TZ)');

#
# error()
#

ok(Rose::DateTime::Util->error =~ /\S/, 'error()');

#
# format_date()
#

foreach my $fmt (qw(a A b B c C d D e G g h H I j k l m M n N p P r R s S
                    T u U V w W x X y Y z Z %))
{
  is(format_date($d, '%' . $fmt), $d->strftime('%' . $fmt), "format_date(%$fmt)");
}

my @s = format_date($d, '%m', '%d', '%Y');

is($s[0], '01', 'format_date() list context 1');
is($s[1], '02', 'format_date() list context 2');
is($s[2], '2003', 'format_date() list context 3');

foreach my $p ('', 2)
{
  $arg = "12/${p}1/1984";
  $d = parse_date($arg);
  ok($d && $d->isa('DateTime'), $arg);
  is(format_date($d, '%E'), "${p}1st", "format_date(%E) ${p}1st");

  $arg = "12/${p}2/1984";
  $d = parse_date($arg);
  ok($d && $d->isa('DateTime'), $arg);
  is(format_date($d, '%E'), "${p}2nd", "format_date(%E) ${p}2nd");

  $arg = "12/${p}3/1984";
  $d = parse_date($arg);
  ok($d && $d->isa('DateTime'), $arg);
  is(format_date($d, '%E'), "${p}3rd", "format_date(%E) ${p}3rd");
}

foreach my $day (4 .. 20, 24 .. 30)
{
  $arg = "12/$day/1984";
  $d = parse_date($arg);
  ok($d && $d->isa('DateTime'), $arg);
  is(format_date($d, '%E'), $day . 'th', 'format_date(%E) ' . $day . 'th');
}

$arg = '12/31/1984';
$d = parse_date($arg);
ok($d && $d->isa('DateTime'), $arg);
is(format_date($d, '%E'), '31st', 'format_date(%E) ' . '31st');

#
# time_zone()
#

Rose::DateTime::Util->time_zone('floating');

$arg = '12/31/1984';

$d = parse_date($arg);
ok($d && $d->isa('DateTime'), $arg);
is($d->time_zone->name, 'floating', 'time_zone() floating');

Rose::DateTime::Util->time_zone('UTC');

$d = parse_date($arg);
ok($d && $d->isa('DateTime'), $arg);
is($d->time_zone->name, 'UTC', 'time_zone() UTC');

is(Rose::DateTime::Util->time_zone, 'UTC', 'time_zone() get');

#
# Epoch vs. yyyymmdd hh
#

$d = parse_date(1143744435);
is($d->strftime('%Y-%m-%d %H:%M:%S'), '2006-03-30 18:47:15', 'Epoch vs. yyyymmdd 1');

$d = parse_date('1143744435.123456789');
is($d->strftime('%Y-%m-%d %H:%M:%S.%N'), '2006-03-30 18:47:15.123456789', 'Epoch vs. yyyymmdd 2');

# Check copied from DateTime's 04epoch.t test
my $negative_epoch_ok = defined((localtime(-1))[0]) ? 1 : 0;

if($negative_epoch_ok)
{
  $d = parse_date('-1143744435.123456789');
  is($d->strftime('%Y-%m-%d %H:%M:%S.%N'), '1933-10-04 05:12:45.123456789', 'Epoch vs. yyyymmdd 3');
}
else
{
  ok(1, "This system ($^O) can't handle negative epoch values");
}

$d = parse_date('1143744435.123451234');
is($d->strftime('%Y-%m-%d %H:%M:%S.%5N'), '2006-03-30 18:47:15.12345', 'Epoch vs. yyyymmdd 4');

$d = parse_date('1143744435.123');
is($d->strftime('%Y-%m-%d %H:%M:%S.%5N'), '2006-03-30 18:47:15.12300', 'Epoch vs. yyyymmdd 5');

$d = parse_date('1143744435.');

if ($DateTime::VERSION >= 0.67 && $DateTime::VERSION <= 0.68)
{
  is($d->strftime('%Y-%m-%d %H:%M:%S.%5N'), '2006-03-30 18:47:15.0', 'Epoch vs. yyyymmdd 6');
}
else
{
  is($d->strftime('%Y-%m-%d %H:%M:%S.%5N'), '2006-03-30 18:47:15.00000', 'Epoch vs. yyyymmdd 6');
}

$d = parse_date('19800102 8pm');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 20:00:00', 'yyyymmdd 1');

$d = parse_date('198001028pm');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 20:00:00', 'yyyymmdd 2');

$d = parse_date('19800102T8pm');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 20:00:00', 'yyyymmdd 4');

$d = parse_date('19800102_8pm');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 20:00:00', 'yyyymmdd 5');

$d = parse_date('19800102-8pm');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 20:00:00', 'yyyymmdd 6');

$d = parse_date('1980.01.02.8:00');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 08:00:00', 'yyyymmdd 7');

$d = parse_date('1980_01_02T8:00');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 08:00:00', 'yyyymmdd 8');

$d = parse_date('1980_01.02-8:00');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 08:00:00', 'yyyymmdd 9');

$d = parse_date('01.02_1980-8');
is($d->strftime('%Y-%m-%d %H:%M:%S'), '1980-01-02 08:00:00', 'yyyymmdd 10');

