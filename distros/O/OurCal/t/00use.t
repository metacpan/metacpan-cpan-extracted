#!perl -w

use strict;
use Test::More tests => 16;

use_ok("OurCal");
use_ok("OurCal::Config");
use_ok("OurCal::Day");
use_ok("OurCal::Event");
use_ok("OurCal::Handler::CGI");
use_ok("OurCal::Month");
use_ok("OurCal::Provider");
use_ok("OurCal::Provider::Cache");
use_ok("OurCal::Provider::DBI");
use_ok("OurCal::Provider::ICalendar");
use_ok("OurCal::Provider::Multi");
use_ok("OurCal::Span");
use_ok("OurCal::Todo");
use_ok("OurCal::View");
use_ok("OurCal::View::HTML");
use_ok("OurCal::View::ICalendar");
