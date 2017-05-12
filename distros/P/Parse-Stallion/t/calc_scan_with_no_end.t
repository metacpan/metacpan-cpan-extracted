#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 3;
BEGIN { use_ok('Parse::Stallion') };

my @results_array;
my %calculator_scan_rules = (
 start_expression => A(
   'tokens', {regex_match => qr /\z/})
,
 tokens => M(
   'token')
,
 token => O(
   'whitespace', 
    'comment',
    'less_than_equal',
    'greater_than_equal',
    'equal',
    'left_parenthesis',
    'right_parenthesis',
    'addition',
    'subtraction',
    'multiplication',
    'assignment',
    'semicolon',
    'literal',
    'identifier',
    'constant',
   ),
whitespace => L(
   qr/\s+/,
   E(sub{})),
comment => L(
  qr/\/\*.*?\*\//,
  E(sub {})),
less_than_equal => L(
  qr/\<\=?/,
  E(sub {
    if ($_[0] eq '<') {
      push @results_array, {token=>'less than'};
    }
    else {
      push @results_array, {token=>'less than or equal'};
    }
  }
 )),
greater_than_equal => L(
  qr/\>\=?/,
  E(sub {
    if ($_[0] eq '>') {
      push @results_array, {token=>'greater than'};
    }
    else {
      push @results_array, {token=>'greater than or equal'};
    }
  }
 )),
equal =>
  L(qr/\=/,
   E(sub {
    push @results_array, {token=>'equal'};
  }
 )),
left_parenthesis => L(
  qr/\(/,
  E(sub {
    push @results_array, {token=>'left parenthesis'};
  }
 )),
right_parenthesis => L(
  qr/\)/,
  E( sub {
    push @results_array, {token=>'right parenthesis'};
  }
 )),
addition => L(
  qr/\+/,
  E(sub {
    push @results_array, {token=>'addition'};
  }
 )),
subtraction => L(
  qr/\-/,
  E(sub {
    push @results_array, {token=>'subtraction'};
  }
 )),
multiplication => L(
  qr/\*/,
  E(sub {
    push @results_array, {token=>'multiplication'};
  }
 )),
assignment => L(
  qr/\:\=/,
  E(sub {
    push @results_array, {token=>'assignment'};
  }
 )),
semicolon => L(
  qr/\;/,
  E(sub {
    push @results_array, {token=>'assignment'};
  }
 )),
literal => L(
  qr/\"[^"]*\"/,
  E(sub {
    my $in_literal = $_[0];
    $in_literal =~ s/\"//;
    push @results_array, {token=>'literal', value => $in_literal};
  }
 )),
identifier => L(
  qr/[a-zA-Z]\w*/,
  E(sub {
    push @results_array, {token=>'identifier', value => $_[0]};
  }
 )),
constant => L(
  qr/\d+/,
  E(sub {
#print STDERR "constant of ".$_[0]."\n";
    push @results_array, {token=>'constant', value => $_[0]};
  }
 ))
);

my $calculator_scan_parser = new Parse::Stallion(
  \%calculator_scan_rules,
  {start_rule => 'start_expression'});

my $result =
 $calculator_scan_parser->parse_and_evaluate("7+4");

is_deeply (\@results_array, 
 [                        
          {
            'value' => '7',
            'token' => 'constant'
          },
          {
            'token' => 'addition'
          },
          {
            'value' => '4',
            'token' => 'constant'
          }
        ]
,
 "tokenized simple plus");

@results_array = ();
$result =
 $calculator_scan_parser->parse_and_evaluate("8*7+4+ (43 )");

is_deeply (\@results_array, 
 [                        
          {
            'value' => '8',
            'token' => 'constant'
          },
          {
            'token' => 'multiplication'
          },
          {
            'value' => '7',
            'token' => 'constant'
          },
          {
            'token' => 'addition'
          },
          {
            'value' => '4',
            'token' => 'constant'
          },
          {
            'token' => 'addition'
          },
          {
            'token' => 'left parenthesis'
          },
          {
            'value' => '43',
            'token' => 'constant'
          },
          {
            'token' => 'right parenthesis'
          },
        ]
,
 "tokenized times plus plus parentheses");


print "\nAll done\n";


