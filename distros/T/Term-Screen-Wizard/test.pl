#!/usr/bin/perl

use lib "/prj/dsnew/perlmods/lib/site_perl/current";
use lib "/prj/dsnew/perlmods/lib/site_perl/current/aix";
use lib "/prj/dsnew/perlmods/lib/current";
use lib "./blib/lib";

BEGIN { $| = 1; $Ntst=5; print "1..$Ntst\n"; $tst=1; }
END { if ( $tst != $Ntst ) { print "not ok $tst\n"; } }

##############################################################################

print "Test $tst, loading the module and allocating screen\n";

use Term::Screen::Wizard;

$scr = new Term::Screen::Wizard;

print "ok $tst\n";
$tst++;

##############################################################################

$scr->clrscr();

$scr->add_screen(
      NAME => "PROCES",
      HEADER => "Test $tst(1), TESTING THE WIZARD, enter some things here, please also test F1",
      CANCEL => "Esc - Annuleren",
      NEXT   => "Ctrl-Enter (F4) - Volgende",
      PREVIOUS => "F3 - Vorige",
      FINISH => "Ctrl-Enter - Klaar",
      HASPREVIOUS => 1,
      PROMPTS => [
         { KEY => "PROCESID", PROMPT => "Proces Id", LEN=>32, VALUE=>"123456789.00.04" , ONLYVALID => "[a-zA-Z0-9.]*" },
         { KEY => "TYPE", PROMPT => "Intern of Extern Proces (I/E)", CONVERT => "up", LEN=>1, ONLYVALID=>"[ieIE]*", NOCOMMIT=>1 },
         { KEY => "OMSCHRIJVING", PROMPT => "Beschrijving Proces", LEN=>75 },
         { KEY => "PASSWORD", PROMPT => "Enter a password", LEN=>14, PASSWORD=>1 }
                ],
      HELPTEXT => "\n\n\n".
              "  Don't worry, it's dutch.\n".
              "\n".
              "  In dit scherm kan een nieuw proces Id worden opgevoerd\n".
              "\n".
              "  ProcesId      - is het ingevoerde Proces Id\n".
              "  Intern/Extern - is het proces belastingdienst intern of niet?\n".
              "  Omschrijving  - Een korte omschrijving van het proces.\n"
     );

$scr->add_screen(
   NAME => "X.400",,
   HEADER => "Test $tst(2), TESTING THE WIZARD, enter some things here, please also test F1",
   CANCEL => "Esc - Annuleren",
   NEXT   => "Ctrl-Enter - Volgende",
   PREVIOUS => "F3 - Vorige",
   FINISH => "Ctrl-Enter - Klaar",
   PROMPTS => [
     { KEY => "COUNTRY", PROMPT => "COUNTRY", LEN => 2, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "AMDM",    PROMPT => "AMDM",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "PRDM",    PROMPT => "PRDM",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "ORG",     PROMPT => "ORGANISATION",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "OU1",     PROMPT => "UNIT1",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "OU2",     PROMPT => "UNIT2",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
     { KEY => "OU3",     PROMPT => "UNIT3",    LEN => 16, CONVERT => "up", ONLYVALID => "[^/]*" },
   ],
   HELPTEXT => "\n\n\n".
           "  In dit scherm kan een standaard X.400 adres worden ingevoerd voor een ProcesId",
);

$scr->add_screen(
   NAME => "GETALLEN",,
   HEADER => "Test $tst(3), TESTING THE WIZARD, enter some things here, please also test F1",
   CANCEL => "Esc - Annuleren",
   NEXT   => "Ctrl-Enter - Volgende",
   PREVIOUS => "F3 - Vorige",
   FINISH => "Ctrl-Enter - Klaar",
   #NOFINISH => 1,
   PROMPTS => [
     { KEY => "ANINT",     PROMPT => "INT",     LEN => 10, CONVERT => "up", ONLYVALID => "[0-9]*" },
     { KEY => "ADOUBLE",  PROMPT => "DOUBLE",  LEN => 16, CONVERT => "up", ONLYVALID => "[0-9]+([.,][0-9]*)?" },
     { KEY => "DATUM",  PROMPT => "DATUM",  LEN => 8, CONVERT => "up", ONLYVALID => "[0-9]+", VALIDATOR => "valdate" },
   ],
);

$result=$scr->wizard();
print "\r\n\n\n\n$result, ok $tst\n";
$tst++;

##############################################################################

#$scr1=$scr->get_screen("GETALLEN");
#$scr1->{HEADER}="This header has been renewed";
$scr->set("GETALLEN",HEADER,"dit is de header");
$scr->set("GETALLEN","ADOUBLE",999.99);
$scr->set("PROCES",READONLY,1);
$scr->set("PROCES",HEADER,"proces scherm is read only nu");
$scr->set("GETALLEN",PROMPTS,ANINT,READONLY,1);
#$scr->set("GETALLEN","HANS",32232);

$scr->puts("Only PROCES and GETALLEN")->getch();
$result=$scr->wizard("PROCES","GETALLEN");
print "\r\n\n\n\n$result, ok $tst\n";
$tst++;

##############################################################################

$scr->clrscr();
print "Test $tst, printing the entered values in the wizard.\n";
print "Wizard result was : '$result'\n";

%values=$scr->get_keys();
@array=( "PROCES", "X.400" );

for $i (@array) {
  print "\n$i\n\r";
  for $key (keys % { $values{$i} }) {
    my $val=$values{$i}{$key};
    print "  $key=$val\n\r";
  }
}


%values=$scr->get_keys("GETALLEN");
@array=( "GETALLEN" );

for $i (@array) {
  print "\n$i\n\r";
  for $key (keys % { $values{$i} }) {
    my $val=$values{$i}{$key};
    print "  $key=$val\n\r";
  }
}

print "\r\n\n\n\n$result, ok $tst\n";
$tst++;

##############################################################################

sub valdate {
  my $wizard=shift;
  my $line=shift;
  my $year=substr($line,0,4);
  my $month=substr($line,4,2);
  my $day=substr($line,6,2);
  my $str="";
  my @days=( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

  if (length $line eq 8) {
    if ($year<1900) {
      $str.="1900<=year ";
    }
    if ($month<1 or $month>12) {
      $str.="01<=month<=12 ";
    }
    else {
      if ($day<1 or $day>$days[$month]) {
        $str.="01<=day<=".$days[$month];
      }
    }
  }
  else {
    $str=" ";
  }  

  if ($str) {
    my $w=$wizard->setstr(" ",length $str);
    $wizard->at(20,0)->puts($str);
    $wizard->at(21,0)->puts("Date format is CCYYMMDD!")->getch();
    $wizard->at(20,0)->puts($w);
    $wizard->at(21,0)->puts("                        ");
    return 0;
  }

return 1;
}

$scr->system("ksh -e echo hoi!");
$scr->system("more Wizard.pm");

exit;

