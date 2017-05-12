#!/usr/bin/perl -w

# $Id: bathtest.pl,v 1.10 2005/03/03 14:59:34 mike Exp $

use strict;
use warnings;
use Net::Z3950::RadioMARC;
my $pattern = 'rmFFF1S1r'; # This is the type of tokens we're using
my $combo;

my $hosturl = '129.120.92.237:210/INNOPAC';
#my $hosturl = 'research.lis.unt.edu:2200/zinterop';
#my $hosturl = 'localhost:8989/Default';
#my $hosturl = 'test:9999/Default';

my ($host, $port, $dbname) = $hosturl =~ /(.*):(.*)\/(.*)/;
set host => $host, port => $port, db => $dbname;
set delay => 1;
set identityField => '001,035$a';
set verbosity => 5;

my $attributes_kw = '@attr 2=3 @attr 3=3 @attr 4=2 @attr 5=100 @attr 6=1';
my $attributes_kwt = '@attr 2=3 @attr 3=3 @attr 4=2 @attr 5=1 @attr 6=1';

add 'record3a.mrc';
#add 'RadMARCATS1';
#add 'record.mrc';

print "Bath compliance test script\n\n";
print "Test date: " . localtime() . "\n";
print "Test target: $hosturl\n";

if (test('@attr 1=4 rm2451a1r', {notfound=>'Not Found!', ok=>''}) ne 'ok') {
  print "Test record not found in database -- unable to continue\n";
  exit 1;
}

my @types = (
  {
    'name' => 'Author search (BP0.1).',
    'use' => 1003,
    'fields' => [
      '100$a', '100$d',
      '245$c',
      '700$a', '700$d',
      '710$a'
    ]
  },
  {
    'name' => 'Title search (BP0.2)',
    'use' => 4,
    'fields' => [
      '245$a', '245$b',
      '440$a',
      '490$a'
    ],
  },
  {
    'name' => 'Subject search (BP0.3)',
    'use' => 21,
    'fields' => [
      '600$a', '600$d',
      '650$a', '650$x', '650$v', '650$z',
      '653$a'
    ]
  }
);

# this function returns a MARC token for field$subfield in
# the global $pattern

sub radtoken {
  $_ = shift;
  my $ret = $pattern;

  my ($field, $subfield) = /(...)\$(.)/;
  $ret =~ s/FFF/$field/;
  $ret =~ s/S/$subfield/;
  return $ret;
}

sub runtest {
  my $combo = shift;
  my $list = shift;
  my $trunc = shift;
  foreach (@{$list}) {
    my $tok = radtoken $_;
    if (defined($trunc) && $trunc eq 't') {
      $tok =~ s/.$//; # strip last char
    }
    my $search = "$combo " . $tok;
    test $search, {
      ok=>"Search finds $_",
      notfound=>"Search does NOT find $_"
    };
  }
}

if(1) {
print "Testing Level 0 keyword searching (BP0.1 to 0.4).\n\n";

foreach (@types) {
  my $combo = "\@attr 1=" . $_->{'use'} . " $attributes_kw";
  print "Testing: " . $_->{name} . "\n\n";
  runtest $combo, $_->{fields};
  print "\n";
}

$combo = "\@attr 1=1016 $attributes_kw";
print "Testing: Any\n";
foreach (@types) {
  runtest $combo, $_->{fields};
}

print "\nAuthor search -- keyword with right truncation (BP1.1)\n\n";

runtest "\@attr 1=1003 $attributes_kwt", $types[0]->{fields}, 't';

print "\nAuthor search -- exact match (BP1.2)\n\n";

$combo = '@attr 1=1003 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=3';

test "$combo {rm1001a1r, rm1001a2r}", {
  ok=>		'100$a with comma OK',
  notfound=>	'100$a with comma NOT FOUND'
};

test "$combo {rm1001a1r rm1001a2r}", {
  ok=>		'100$a without comma OK',
  notfound=>	'100$a without comma NOT FOUND'
};

test "$combo {rm1001a1r, rm1001a2r, rm1001d1r}", {
  ok=>		'100$a 100$d with comma OK',
  notfound=>	'100$a 100$d with comma NOT FOUND'
};

test "$combo {rm1001a1r rm1001a2r rm1001d1r}", {
  ok=>		'100$a 100$d without comma OK',
  notfound=>	'100$a 100$d without comma NOT FOUND'
};

test "$combo {rm7001a1r, rm7001a2r}", {
  ok=>		'700$a with comma OK',
  notfound=>	'700$a with comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a2r}", {
  ok=>		'700$a without comma OK',
  notfound=>	'700$a without comma NOT FOUND'
};

test "$combo {rm7001a1r, rm7001a2r, rm7001d1r}", {
  ok=>		'700$a 700$d without comma OK',
  notfound=>	'700$a 700$d without comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a2r rm7001d1r}", {
  ok=>		'700$a 700$d without comma OK',
  notfound=>	'700$a 700$d without comma NOT FOUND'
};

test "$combo {rm7101a1r rm7101a2r}", {
  ok=>		'710$a without comma OK',
  notfound=>	'710$a without comma NOT FOUND'
};

test "$combo {rm2451c1r rm2451c2r rm2451c3r}", {
  ok=>		'245$c without comma OK',
  notfound=>	'245$c without comma NOT FOUND'
};

print "\nAuthor search -- first words in field (BP 1.3).\n\n";

$combo = '@attr 1=1003 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=1';

test "$combo {rm1001a1r rm1001a2r}", {
  ok=>		'100$a without comma OK',
  notfound=>	'100$a without comma NOT FOUND'
};

test "$combo {rm1001a1r}", {
  ok=>		'100$a (partial) OK',
  notfound=>	'100$a (partial) NOT FOUND'
};
 
test "$combo {rm1001a1r rm1001a2r rm1001d1r}", {
  ok=>		'100$a 100$d without comma OK',
  notfound=>	'100$a 100$d without comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a2r}", {
  ok=>		'700$a without comma OK',
  notfound=>	'700$a without comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a2r rm7001d1r}", {
  ok=>		'700$a 700$d without comma OK',
  notfound=>	'700$a 700$d without comma NOT FOUND'
};

test "$combo {rm7101a1r rm7101a2r}", {
  ok=>		'710$a without comma OK',
  notfound=>	'710$a without comma NOT FOUND'
};

test "$combo {rm2451c1r rm2451c2r}", {
  ok=>		'245$c without comma OK',
  notfound=>	'245$c without comma NOT FOUND'
};

print "\nAuthor search -- first characters in field (BP 1.4).\n\n";

$combo = '@attr 1=1003 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=1 @attr 6=1';

test "$combo {rm1001a1r rm1001a21}", {
  ok=>		'100$a without comma OK',
  notfound=>	'100$a without comma NOT FOUND'
};

test "$combo {rm1001a11}", {
  ok=>		'100$a (partial) OK',
  notfound=>	'100$a (partial) NOT FOUND'
};
 
test "$combo {rm1001a1r rm1001a2r rm1001d11}", {
  ok=>		'100$a 100$d without comma OK',
  notfound=>	'100$a 100$d without comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a21}", {
  ok=>		'700$a without comma OK',
  notfound=>	'700$a without comma NOT FOUND'
};

test "$combo {rm7001a1r rm7001a2r rm7001d11}", {
  ok=>		'700$a 700$d without comma OK',
  notfound=>	'700$a 700$d without comma NOT FOUND'
};

test "$combo {rm7101a1r rm7101a21}", {
  ok=>		'710$a without comma OK',
  notfound=>	'710$a without comma NOT FOUND'
};

test "$combo {rm2451c1r rm2451c21}", {
  ok=>		'245$c without comma OK',
  notfound=>	'245$c without comma NOT FOUND'
};

print "\nTitle search -- keyword with right truncation (BP1.5)\n\n";

runtest "\@attr 1=4 $attributes_kwt", $types[1]->{fields}, 't';

print "\nTitle search -- Exact match (BP1.6).\n\n";

$combo = '@attr 1=4 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=3';

test "$combo {rm2451a1r rm2451a2r rm2451a3r}", {
  ok=>		'245$a OK',
  notfound=>	'245$a NOT FOUND'
};

test "$combo {rm2451a1r rm2451a2r rm2451a3r rm2451b1r rm2451b2r rm2451b3r}", {
  ok=>		'245$a 245$b OK',
  notfound=>	'245$a 245$b NOT FOUND'
};

test "$combo {rm2451b1r rm2451a1r rm2451a2r rm2451a3r rm2451b1r rm2451b2r rm2451b3r}", {
  ok=>		'!Server appears insensitive to word order (245$a 245$a)',
  notfound=>    'Reverse order test OK'
};

test "$combo {rm4401a1r rm4401a2r rm4401a3r}", {
  ok=>		'440$a OK',
  notfound=>	'440$a NOT FOUND'
};

test "$combo {rm4901a1r rm4901a2r rm4901a3r}", {
  ok=>		'490$a OK',
  notfound=>	'490$a NOT FOUND'
};

print "\nTitle search -- First words in field (BP1.7).\n\n";

$combo = '@attr 1=4 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=1';

test "$combo {rm2451a1r rm2451a2r rm2451a3r}", {
  ok=>		'245$a OK',
  notfound=>	'245$a NOT FOUND'
};

test "$combo {rm2451a1r rm2451a2r}", {
  ok=>		'245$a (partial) OK',
  notfound=>	'245$a (partial) NOT FOUND'
};

test "$combo {rm2451a1r rm2451a2r rm2451a3r rm2451b1r rm2451b2r}", {
  ok=>		'245$a 245$b (partial) OK',
  notfound=>	'245$a 245$b (partial) NOT FOUND'
};

test "$combo {rm4401a1r rm4401a2r}", {
  ok=>		'440$a (partial) OK',
  notfound=>	'440$a (partial) NOT FOUND'
};

test "$combo {rm4901a1r rm4901a2r}", {
  ok=>		'490$a (partial) OK',
  notfound=>	'490$a (partial) NOT FOUND'
};

print "\nTitle search -- First characters in field (BP1.8).\n\n";

$combo = '@attr 1=4 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=1 @attr 6=1';

test "$combo {rm2451a1r rm2451a2r rm2451a31}", {
  ok=>		'245$a OK',
  notfound=>	'245$a NOT FOUND'
};

test "$combo {rm2451a1r rm2451a21}", {
  ok=>		'245$a (partial) OK',
  notfound=>	'245$a (partial) NOT FOUND'
};

test "$combo {rm2451a1r rm2451a2r rm2451a3r rm2451b1r rm2451b21}", {
  ok=>		'245$a 245$b (partial) OK',
  notfound=>	'245$a 245$b (partial) NOT FOUND'
};

test "$combo {rm4401a1r rm4401a21}", {
  ok=>		'440$a (partial) OK',
  notfound=>	'440$a (partial) NOT FOUND'
};

test "$combo {rm4901a1r rm4901a21}", {
  ok=>		'490$a (partial) OK',
  notfound=>	'490$a (partial) NOT FOUND'
};
}

print "\nSubject search -- keyword with right truncation (BP1.9)\n\n";

runtest "\@attr 1=21 $attributes_kwt", $types[2]->{fields}, 't';

print "\nSubject search -- Exact match (BP1.10).\n\n";

$combo = '@attr 1=21 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=3';

test "$combo {rm6001a1r rm6001a2r}", {
  ok=>		'600$a OK',
  notfound=>	'600$a NOT FOUND'
};

test "$combo {rm6001a1r rm6001a2r rm6001d1r}", {
  ok=>		'600$a 600$d OK',
  notfound=>	'600$a 600$d NOT FOUND'
};

test "$combo {rm6501a1r rm6501a2r rm6501a3r}", {
  ok=>		'650$a OK',
  notfound=>	'650$a NOT FOUND'
};

test "$combo {rm6501a1r rm6501a2r rm6501a3r rm6501x1r}", {
  ok=>		'650$a 650$x OK',
  notfound=>	'650$a 650$x NOT FOUND'
};

test "$combo {rm6511a1r rm6511a2r}", {
  ok=>		'651$a OK',
  notfound=>	'651$a NOT FOUND'
};

test "$combo {rm6511a1r rm6511a2r rm6511x1r}", {
  ok=>		'651$a 651$x OK',
  notfound=>	'651$a 651$x NOT FOUND'
};

test "$combo {rm6531a1r rm6531a2r rm6531a3r}", {
  ok=>		'653$a OK',
  notfound=>	'653$a NOT FOUND'
};

print "\nSubject search -- First words in fields (BP1.11)\n\n";

$combo = '@attr 1=21 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=100 @attr 6=1';

test "$combo {rm6001a1r}", {
  ok=>		'600$a (partial) OK',
  notfound=>	'600$a (partial) NOT FOUND'
};

test "$combo {rm6001a1r rm6001a2r}", {
  ok=>		'600$a OK',
  notfound=>	'600$a NOT FOUND'
};

test "$combo {rm6501a1r rm6501a2r}", {
  ok=>		'650$a (partial) OK',
  notfound=>	'650$a (partial) NOT FOUND'
};

test "$combo {rm6501a1r rm6501a2r rm6501a3r rm6501x1r}", {
  ok=>		'650$a 650$x OK',
  notfound=>	'650$a 650$x NOT FOUND'
};

test "$combo {rm6511a1r rm6511a2r}", {
  ok=>		'651$a OK',
  notfound=>	'651$a NOT FOUND'
};

test "$combo {rm6511a1r rm6511a2r rm6511x1r}", {
  ok=>		'651$a 651$x OK',
  notfound=>	'651$a 651$x NOT FOUND'
};

test "$combo {rm6531a1r rm6531a2r rm6531a3r}", {
  ok=>		'653$a OK',
  notfound=>	'653$a NOT FOUND'
};

print "\nSubject search -- First characters in fields (BP1.12)\n\n";

$combo = '@attr 1=21 @attr 2=3 @attr 3=1 @attr 4=1 @attr 5=1 @attr 6=1';

test "$combo {rm6001a11}", {
  ok=>		'600$a (partial) OK',
  notfound=>	'600$a (partial) NOT FOUND'
};

test "$combo {rm6001a1r rm6001a21}", {
  ok=>		'600$a OK',
  notfound=>	'600$a NOT FOUND'
};

test "$combo {rm6501a1r rm6501a21}", {
  ok=>		'650$a (partial) OK',
  notfound=>	'650$a (partial) NOT FOUND'
};

test "$combo {rm6501a1r rm6501a2r rm6501a3r rm6501x11}", {
  ok=>		'650$a 650$x OK',
  notfound=>	'650$a 650$x NOT FOUND'
};

test "$combo {rm6511a1r rm6511a21}", {
  ok=>		'651$a OK',
  notfound=>	'651$a NOT FOUND'
};

test "$combo {rm6511a1r rm6511a2r rm6511x11}", {
  ok=>		'651$a 651$x OK',
  notfound=>	'651$a 651$x NOT FOUND'
};

test "$combo {rm6531a1r rm6531a2r rm6531a31}", {
  ok=>		'653$a OK',
  notfound=>	'653$a NOT FOUND'
};

print "\nTesting Any Search -- keyword with right truncation (BP1.13)\n\n";

$combo = "\@attr 1=1016 $attributes_kwt";
foreach (@types) {
  runtest $combo, $_->{fields}, 't';
}

print "\n\nInsert explanatory verbiage about RadMarc/Z-Interop  here\n";



# $Log: bathtest.pl,v $
# Revision 1.10  2005/03/03 14:59:34  mike
# Use the identity-field pair 001 and 035$a
#
# Revision 1.9  2005/03/02 22:31:15  mike
# New hosturl, the main UNT server.
# Delay set to 1s, otherwise UNT throws us off quite quickly.
# Identity field set to 035$a, as UNT discards our 001 field.
# Uses new test-set "record3a.mrc", which is the same as "record3.mrc"
# 	except for the addition of the 035$a field.
#
# Revision 1.8  2005/02/15 15:30:06  quinn
# Latest rec
#
# Revision 1.7  2005/02/01 22:10:18  quinn
# This version fails on the truncated tests.
#
# Revision 1.6  2005/02/01 21:53:33  quinn
# Smallish
#
# Revision 1.5  2004/12/20 15:23:06  quinn
# Added last truncated level 1 searches
#
# Revision 1.4  2004/12/20 15:04:20  quinn
# Inserted log in tail
#
