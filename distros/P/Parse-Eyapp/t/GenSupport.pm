package GenSupport;
use strict;
use warnings;

use Getopt::Long;
use Test::LectroTest::Generator qw(:all);
use Parse::Eyapp::TokenGen;

sub _Error {
  my $parser = shift;

  my $t = $parser->YYCurval;
  my @e = $parser->YYExpect();
  my $attr = $parser->YYSemval(0);
  local $" = " ";
  warn "Error:\nCurrent attribute: <$attr>\nCurrent token: <$t>\nExpected: <@e>\n";
}

my %st; # Symbol Table
sub defined_variable {
  my ($parser, $var) = @_;

  $st{$var} = 1;
}

sub generate_token {
  my $parser = shift;

  my @token = $parser->YYExpect; # the list of token that can be expected 

  # Generate on of those using the token_weight distribution
  my $tokengen = Frequency( map { [$parser->token_weight($_), Unit($_)] } @token);

  return $tokengen->generate;
}

sub generate_attribute {
  my $parser = shift;
  my $token = shift;

  my $gen = $parser->token_generator($token);
  return $gen->generate  if defined($gen);
  return $token;
}

#my $WHITESPACES = String( length=>[0,1], charset=>" \t\n", size => 100 );

sub gen_lexer {
  my $parser = shift;

  my $token = $parser->generate_token;
  my $attr = $parser->generate_attribute($token);
  #$attr = $WHITESPACES->generate.$attr;

  return ($token, $attr);
}

sub evaluate_using_perl { # if possible
  my $perlexp = shift;

  $perlexp =~ s/\b([a-zA-Z])/\$$1/g; # substitute A by $A everywhere 
  $perlexp =~ s/\^/**/g;             # substitute power operator: ^ by **

  my $res = eval "no warnings; no strict;$perlexp";
  if ($@ =~ /Illegal division/) {
    $res = "error. Division by zero.";
  }
  elsif ($@) { # Our calc notation is incompatible with perl in a few gotchas
    # Perl interprets -- in a different way
    $@ =~ m{(.*)}; # Show only the first line of error message
    $res = "Calculator syntax differs from Perl. Can't compute the result: $1"; 
  }

  $res;
}


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
    VAR => [
              0,  # At the beginning, no variables are defined
              Gen {
                return  Elements(keys %st)->generate if keys %st;
                return Int(range=>[0, 9], sized=>0)->generate;
              },
            ],
    VARDEF => [ 
                2,  
                String( length=>[1,2], charset=>"A-NP-Z", size => 100 )
              ],
    '=' => 2, '-' => 1, '+' => 2, 
    '*' => 4, '/' => 2, '^' => 0.5, 
    ';' => 1, '(' => 1, ')' => 2, 
    ''  => 2, 'error' => 0,
  );

  my $exp = $parser->YYParse( 
      yylex => \&gen_lexer, 
      yyerror => \&_Error,
      yydebug => $debug, # 0x1F
    );

  my $res = evaluate_using_perl($exp);

  print "\n# result: $res\n$exp\n";
}

1;
