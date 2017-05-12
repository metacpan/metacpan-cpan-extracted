#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';
use utf8;
use Template::Replace;

use FindBin;
use Data::Dumper;
use Encode;

#
# Prepare data directory ...
#
my $data_dir = "$FindBin::Bin/data";                       # construct path
$data_dir = $1 if $data_dir =~ m#^((?:/(?!\.\./)[^/]+)+)#; # un-taint
mkdir $data_dir unless -e $data_dir;                       # create if missing

#
# Cleanup beforehand ... no need for it so far!
#


#
# Let's have some prerequisites ...
#
my $tmpl;
my $str;
my $result;


#
# Testing tmpl->_read_file() ...
#
$tmpl = Template::Replace->new({ path => $data_dir }); # standard delimiters

$str = $tmpl->_read_file('tmpl1.txt');
ok( Encode::is_utf8($str), '_read_file() returns UTF-8 string' );

like( $str, qr/über/, '_read_file() returns correct German umlaut in UTF-8');

#diag( Dumper($str) );
ok( $str eq <<EOS
# t/data/tmpl1.txt:
Testdatei, 1. Zeile ...
2. Zeile der Testdatei

<!--( Abschnitt1 )-->
Erste Zeile von Abschnitt 1.
Zweite Zeile mit (\$Variable1\$) darin.
<!--( /Abschnitt1 )-->
<!--? !Abschnitt1 ?-->
Das hier sollte nicht erscheinen!
<!--? /!Abschnitt1 ?-->
<!--? Abschnitt1 ?-->
Das hier sollte erscheinen!
<!--? /Abschnitt1 ?-->
<!--? !Abschnitt2 ?-->
Abschnitt 2 ist nicht definiert!
<!--? /!Abschnitt2 ?-->

<!--# Ein Kommentar. #-->
Text nach Abschnitt1.
<!--#
	Ein mehrzeiliger Kommentar.
	Hier mit zweiter Zeile.
#-->
Noch eine Zeile ...
Include-Datei tmpl2.txt ...
Include-Datei subdir/tmpl3.txt geladen über tmpl2.txt
EOS
, '_read_file() returns template string with includes');


#
# Cleanup ... no need for it so far!
#

