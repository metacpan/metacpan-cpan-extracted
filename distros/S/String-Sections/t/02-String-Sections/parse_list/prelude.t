use strict;
use warnings;
use Test::More;

use Path::Tiny;
use FindBin;
use lib path($FindBin::Bin)->parent->parent->child('lib')->stringify;

use Test::Fatal::Assert;
use Scalar::Util qw( refaddr );
use Data::Dump qw(pp);

#===[user]===

my $testfile = 'prelude.ds';
my (@constructor_args) = ( default_name => 'prelude' );
my (@expected_names) = ( 'prelude', 'othersection' );

#==[enduser]==

my $parser;
my $result;
my @source_list;

my $corpus;
my $parsefiles;

use String::Sections;

nofatals 'can create a parser' => sub {
  $parser = String::Sections->new(@constructor_args);
};
nofatals 'resolve corpus dir' => sub {
  $corpus = path($FindBin::Bin)->parent->parent->parent->child('corpus');
};
nofatals 'resolve parsefiles dir' => sub {
  $parsefiles = $corpus->child('parse_files');
};
nofatals 'resolve testfile' => sub {
  $testfile = $parsefiles->child($testfile);
};
nofatals 'can open source file' => sub {
  @source_list = $testfile->lines();
};
nofatals 'can parse the filehandle' => sub {
  $result = $parser->load_list(@source_list);
};
nofatals 'section_names' => sub {
  my $label = join q{,}, map { pp($_) } sort @expected_names;
  is_deeply( [ sort $result->section_names ], [ sort @expected_names ], "[ sort section_names() ] == [ $label ]" );
};

#==[user]==
#==[enduser]==

done_testing;
