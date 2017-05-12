#!/usr/bin/env perl
# Run this like so: `perl test_query.t'
#   Michal Sedlak <sedlakmichal@gmail.com>     2014/05/07 15:13:00

use Test::Most;
use File::Spec;
use File::Basename 'dirname';
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'bootstrap.pl';
}

use PMLTQ;
use PMLTQ::TypeMapper;
use PMLTQ::BtredEvaluator;

use Treex::PML;
use Test::MockModule;
use List::Util 'pairmap';
use List::MoreUtils 'zip';

# Mocks
use PML;
use TredMacro;

binmode STDOUT, ':utf8';

my $TypeMapperMock = Test::MockModule->new('PMLTQ::TypeMapper');

$PMLTQ::BtredEvaluator::DEBUG //= 0;

# # list of available user defined relations (this should be compiled automatically based on tred extensions)
# $PMLTQ::user_defined = '\b(?:echild|eparent|a/lex.rf\|a/aux.rf|a/lex.rf|a/aux.rf|coref_gram.rf|coref_text.rf|coref_text|coref_gram|compl)\b';

sub test_query {
  my ( $name, $treebank_name, $query ) = @_;

  my @files  = treebank_files($treebank_name);
  my $fsfile = open_file( shift @files );

  my $evaluator;
  lives_ok {
    $evaluator = PMLTQ::BtredEvaluator->new( $query, { fsfile => $fsfile } );
  }
  "create evaluator ($name) on $treebank_name";

  return unless $evaluator;

  my @result;
  if ( $evaluator->get_filters() ) {

    # query with filters (produces text output)
    ## customize output from the final filter
    $evaluator->init_filters(
      { init        => sub { },
        finish      => sub { },
        process_row => sub {
          my ( $self, $row ) = @_;
          push @result, [sort @$row];
        }
      } );
    do {
      $evaluator->run_filters while $evaluator->find_next_match();    # feed the filter pipe
    } while ( $fsfile = next_file( $evaluator, shift @files ) );
    $evaluator->flush_filters;                                        # flush the pipe
  }
  else {
    # query without a fitlter (just selects nodes)
    do {
      while ( $evaluator->find_next_match() ) {
        my @pairs = pairmap {TredMacro::ThisAddress($a, $b)} zip(@{ $evaluator->get_results }, @{$evaluator->get_result_files});
        push @result, [sort @pairs];
      }
    } while ( $fsfile = next_file( $evaluator, shift @files ) );
  }

  my $res = [sort sort_results @result];
  my $result_file = result_filename( $treebank_name, $name );
  save_result( $result_file, $res ) unless -f $result_file;

  my $expected = load_results($result_file);
  eq_or_diff_data( $res, $expected, "result match for ($name) on $treebank_name" );
}

for my $treebank ( treebanks() ) {
  my $treebank_name = $treebank->{name};

  my @schemas = treebank_schemas($treebank_name);
  $TypeMapperMock->mock( get_schemas => sub {@schemas} );

  my @queries = load_queries($treebank_name);
  for my $query ( @queries ) {
    my $name = $query->{name};
    my @args = ( $treebank_name, $query->{text} );

    if ( $name =~ s/^_// ) {
    TODO: {
        local $TODO = 'Failing query...';
        subtest "$treebank_name:$name" => sub {
          test_query( $name, @args );
          fail('Fail');
        }
      }
    }
    else {
      subtest "$treebank_name:$name" => sub {
        test_query( $name, @args );
      }
    }
  }
}

# for my $treebank (@treebanks) {

#   for my $query ($doc->trees) {
#     my $qfile = $query->get_id();
#     my ($layer) = basename($qfile) =~ m/^(.)/;
#     my @files = glob(File::Spec->catfile($treebanks_dir, $treebank, 'data', "*.$layer.gz"));
#     open my $fh, '<:utf8', $query->get_id() || die "Cannot open query file ".$query->get_id().": $!\n";
#     local $/;
#     my $string_query = <$fh>;

#     runquery($string_query,$treebank,basename($qfile),@files);# if $qfile =~ m/$ENV{XXX}/;
#   }
# }

################
# TEST GRAMMAR PARSER

# my $doc = Treex::PML::Factory->createDocument('queries.pml');
# $doc->changeBackend('Treex::PML::Backend::PML');
# $doc->changeEncoding('utf-8');
# $doc->changeSchemaURL('tree_query_schema.xml');
# $doc->changeMetaData('schema', PMLTQ::Common::Schema);
# $doc->changeMetaData('pml_root', Treex::PML::Factory->createStructure);

# my @files = glob(File::Spec->catfile($FindBin::RealBin, 'queries', '*.tq'));

# # @files = glob(File::Spec->catfile($FindBin::RealBin, 'queries', 't-dative*.tq')); ####################################
# for my $file (@files) {
#   local $/;
#   undef $/;

#   open my $fh, '<:utf8', $file or die "Can't open file: '$file'\n";
#   my $string = <$fh>;
#   close($fh);
#   my $result;
#   eval { $result = PMLTQ::Common::parse_query($string)};

#   my $query_name = basename($file);
#   $query_name=~s/\.\w+$//;
#   ok($result, "parsing query '$query_name'");
#   if($result) {
#     $result->set_attr('id', $file);
#     $doc->append_tree($result); ## every tree contains one query
#   }
# }

done_testing();
