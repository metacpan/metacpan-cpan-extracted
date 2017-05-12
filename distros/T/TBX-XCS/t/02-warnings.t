#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::More 0.88;
plan tests => 6;
use Test::Warn;
use Test::Exception;
use TBX::XCS;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');
my $termCompList_xcs_file = path($corpus_dir, 'termCompList.xcs');
my $datatype_xcs_file = path($corpus_dir, 'datatype.xcs');
my $levels_xcs_file = path($corpus_dir, 'levels.xcs');
my $contents_xcs_file = path($corpus_dir, 'contents.xcs');

my $xcs = TBX::XCS->new();

throws_ok {$xcs->parse(file => 'nonexistent.xcs')}
  qr/file does not exist: nonexistent.xcs/,
  'Exception thrown when trying to read non-existent file';

throws_ok {$xcs->parse(filet => 'nonexistent.xcs')}
  qr/Need to specify either a file or a string pointer with XCS contents/,
  'Exception thrown for missing arguments';

warning_is {$xcs->parse(file => $termCompList_xcs_file)}
  {carped => 'Ignoring datatype value in termCompList contents element'},
  'Warning about ignoring termCompList datatype';

throws_ok {$xcs->parse(file => $datatype_xcs_file)}
  qr/Can't set datatype of hi to noteText. Must be picklist or plainText/,
  'Exception thrown with illegal datatype';

throws_ok {$xcs->parse(file => $levels_xcs_file)}
  qr/Bad levels in descrip/,
  'Exception thrown with illegal <levels>';

throws_ok {$xcs->parse(file => $contents_xcs_file)}
  qr/No contents element/,
  'Exception thrown when missing <contents>';