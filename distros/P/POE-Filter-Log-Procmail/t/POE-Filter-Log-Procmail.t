# -*- mode: cperl; cperl-indent-level: 4; -*-
# vi:ai:sm:et:sw=4:ts=4

# $Id: POE-Filter-Log-Procmail.t,v 1.3 2004/11/11 19:32:24 paulv Exp $

use Data::Dumper;
#use Test::More tests => 55;
use Test::More qw(no_plan);
BEGIN { use_ok('POE::Filter::Log::Procmail') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $test_data =
 [
   # 0 - default
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov 11 12:22:50 2004\n",
    " Subject: Re: use XML::Simple breaks my PoCo::IKC::Server\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

   # 1 - one digit dom
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    " Subject: Re: use XML::Simple breaks my PoCo::IKC::Server\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

   # 2 - garbage lines
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    "THIS LINE IS GARBAGE!!!!\n",
    "From THIS LINE IS GARBAGE TOO!!!!\n",
    " Subject: Re: use XML::Simple breaks my PoCo::IKC::Server\n",
    " Subject: THIS LINE IS GARBAGE AS WELL!!!!\n",
    "  Folder: I WANT TO GO HOME!!!!\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

   # 3 - more garbage
   [
    "I LIKE PIES AND SODA WATER YUM!!!\n",
    "From me!\n",
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    "THIS LINE IS GARBAGE!!!!\n",
    "From THIS LINE IS GARBAGE TOO!!!!\n",
    " Subject: Re: use XML::Simple breaks my PoCo::IKC::Server\n",
    " Subject: THIS LINE IS GARBAGE AS WELL!!!!\n",
    "  Folder: mail/perl/poe                                           1726\n",
    "  Folder: YR MOM!!!!\n",
   ],

   # 4 - empty subject
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    " Subject:\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

   # 5 - no subject
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

  # 6 - weird combo
  [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov  1 12:22:50 2004\n",
    "  Folder: mail/perl/poe                                           1726\n",
    " Subject: DUDE!\n",
   ],
   # 7 - uppercase Subject
   [
    "From poe-return-2605-paulv=cpan.org\@perl.org  Thu Nov 11 12:22:50 2004\n",
    " SUBJECT: Re: use XML::Simple breaks my PoCo::IKC::Server\n",
    "  Folder: mail/perl/poe                                           1726\n",
   ],

  

 ];


my $test = 0;
my $obj;
my $filter = POE::Filter::Log::Procmail->new();

$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "11", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, "Re: use XML::Simple breaks my PoCo::IKC::Server", "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, "Re: use XML::Simple breaks my PoCo::IKC::Server", "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, "Re: use XML::Simple breaks my PoCo::IKC::Server", "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, "Re: use XML::Simple breaks my PoCo::IKC::Server", "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, undef, "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, undef, "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "1", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, undef, "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size ok");

$obj = undef;
$test++;
$obj = $filter->get($test_data->[$test]);

is($obj->[0]->{from}, "poe-return-2605-paulv=cpan.org\@perl.org", "from");
is($obj->[0]->{dow}, "Thu", "dow");
is($obj->[0]->{mon}, "Nov", "mon");
is($obj->[0]->{date}, "11", "date");
is($obj->[0]->{time}, "12:22:50", "time");
is($obj->[0]->{year}, "2004", "year");
is($obj->[0]->{subject}, "Re: use XML::Simple breaks my PoCo::IKC::Server", "subject");
is($obj->[0]->{folder}, "mail/perl/poe", "folder");
is($obj->[0]->{size}, 1726, "size");

