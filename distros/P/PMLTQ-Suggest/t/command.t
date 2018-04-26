use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Basename qw/dirname basename/;
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__),File::Spec->updir, 'lib' ) );
use Capture::Tiny ':all';
use PMLTQ::Command::suggest;
use PMLTQ::Commands;


my @message_tests = (
#      [File::Spec->rel2abs( dirname(__FILE__))."/FILE#ID", '/No such file or directory/', 'nonexisting file'],
#      [File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#ID", '/Empty query!/', 'nonexisting ID'],
#      [File::Spec->rel2abs( dirname(__FILE__))."/treebanks/noschema_test/noschema.pml#ID", '/no suitable backend/', 'no schema'],
      [File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p2s1w2", '/t-cmpr9410-001-p2s1w2/', 'suggest one node'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p2s1w$_"} qw/2 1/), '/child t-node/', 'suggest on parent and child'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p2s1w$_"} qw/2 4/), '/sibling t-node/', 'suggest on siblings'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.$_.gz#$_-cmpr9410-001-p2s1w2"} qw/a t/), '/lex\.rf \$[a-z],/', 'suggest on two layers'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p4s1w$_"} qw/13 12/), '/descendant t-node/', 'suggest on descendant'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p10s2$_"} qw/w23 a8/), '/target_node\.rf \$[a-z],/', 'suggest on coref'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/cmpr9410_001.t.gz#t-cmpr9410-001-p10s2$_"} qw/w23 a8/), '/target_node\.rf \$[a-z],/', 'suggest on coref'],
      [join('|', map {File::Spec->rel2abs( dirname(__FILE__))."/treebanks/pdt_test/data/$_"} qw/cmpr9410_001.t.gz#t-cmpr9410-001-p2s1w2 mf920922_001.t.gz#t-mf920922-001-p1s1w1/), '/(?:t-node \$[a-z].*){2}/ms', 'suggest on two different files'],
#      [File::Spec->rel2abs( dirname(__FILE__))."/treebanks/treex_test/data/1.treex.gz#a_tree-cs-fiction-b1-00train-f00001-s1-n3773", '/a_tree-cs-fiction-b1-00train-f00001-s1-n3773/', 'suggest on one treex node '],

);

foreach my $message_test (@message_tests) {
  my ($paths, $expected, $description) = @$message_test;
  subtest $description => sub {
    my $cmd = PMLTQ::Command::suggest->new(
      config => {
        resources  => File::Spec->catdir( dirname(__FILE__),'treebanks','pdt_test','resources'),
      },
    );
    my $h = capture_merged {
      lives_ok { $cmd->run("--nodes" => $paths) } "calling suggest";
    };
    like($h, $expected, "result");
  }
}

done_testing();
