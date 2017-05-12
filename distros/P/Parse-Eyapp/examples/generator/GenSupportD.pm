package GenSupportD;
use strict;
use warnings;

use Getopt::Long;
use Test::LectroTest::Generator qw(:all);
use Parse::Eyapp::TokenGen;

sub main {
  my $package = shift;

  my $debug = shift || 0;
  my $result = GetOptions (
    "debug!" => \$debug,  
  );

  $debug = 0x1F if $debug;

  my $parser = $package->new();

  # set_tokenweightsandgenerators receives the parser object and the pairs 
  #   token => [weight, generator] or token => weight
  # and sets the weight and generator attributes of the tokens.
  $parser->set_tokenweightsandgenerators(
    NUM => [ 2, Int(range=>[0, 9], sized=>0)],
    VARDEF => [ 
                2,  
                String( length=>[1,2], charset=>"A-NP-Z", size => 100 )
              ],
    '=' => 2, '-' => 1, '+' => 2, 
    '*' => 4, '/' => 2, '^' => 0.5, 
    ';' => 1, '(' => 1, ')' => 2, 
    ''  => 2, 'error' => 0,
  );

  my $expg = $parser->YYParse( 
      yylex => \&gen_lexer, 
      yydebug => $debug, # 0x1F
    );

  for (1..1) {
    my $exp = $expg->generate();

    print "$exp\n";

  }
}

1;
