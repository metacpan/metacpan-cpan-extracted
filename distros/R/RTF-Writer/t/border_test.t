
require 5;
# Time-stamp: "2003-10-14 17:51:37 ADT"
use strict;
use Test;

BEGIN { plan tests => 8 }

sub isbal ($) { (my $x = $_[0]) =~ tr/\{\}//cd; while($x =~ s/\{\}//g){;}; length($x) ? 0 : 1 }

use RTF::Writer;
ok 1;

my $f = "bordery.rtf";
use File::Spec;
$f = File::Spec::->catfile( File::Spec::->curdir(), $f);

my $doc = RTF::Writer->new_to_file($f);
$doc->prolog;
my $t = RTF::Writer::TableRowDecl->new( 

 borders => 't-20 l-33-wavy', #['n s e', 'n-wavy s-wavy'],

);

my $x = 'This module is for generating documents in Rich Text Format.';
$doc->row($t, $x, $x, "$x $x", $x);
$doc->row($t, $x, $x, $x,      $x);

$doc->close;
undef $doc;

my $errorcount = 0;

ok 1;
{
  my $rtf;
  open IN, $f or die $!;
  local $/;
  $rtf = <IN>;
  close(IN);
  ok $rtf, '/\\\\brdrs\\b/'  or ++$errorcount;
  ok $rtf, '/\\\\brdrwavy\\b/'  or ++$errorcount;
  ok scalar( grep 1, $rtf =~ m/(\\brdrs)\b/g),    8 or ++$errorcount;
  ok scalar( grep 1, $rtf =~ m/(\\brdrwavy)\b/g), 8 or ++$errorcount;;
  ok isbal($rtf), 1, "Unbalanced: $rtf";
}

$errorcount or unlink $f;
print "# Bye...\n";
ok 1;
