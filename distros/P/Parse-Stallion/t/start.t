#!/usr/bin/perl
#Copyright 2010 Arthur S Goldstein
use Test::More tests => 6;
BEGIN { use_ok('Parse::Stallion') };

my %start_grammar = (
  start_rule => A('x',O('start_rule', 'y'),USE_STRING_MATCH),
  x => qr/x/,
  y => qr/y/
);

my $start_parser;
eval {$start_parser = new Parse::Stallion(\%start_grammar,
);
};
is ($@, '', 'start rule 1');

$start_parser = new Parse::Stallion(\%start_grammar);

my $g = $start_parser->parse_and_evaluate('xy');
is ($g, 'xy');

my %qstart_grammar = (
  start_rule => A('x',O('start_rule', 'y')),
  x => A(qr/x/, 'start_rule'),
  y => qr/y/
);

my $qstart_parser;
eval {$qstart_parser = new Parse::Stallion(\%qstart_grammar,
);
};
like ($@, qr/No valid start rule a/, 'start rule q');

my %qqstart_grammar = (
  qstart_rule => A('x',O('qstart_rule', 'y')),
  x => A(qr/w/, 'qstart_rule', qr/x/),
  y => qr/y/
);

my $qqstart_parser;
eval {$qqstart_parser = new Parse::Stallion(\%qqstart_grammar,
);
};
like ($@, qr/No valid start rule a/, 'start rule qq');



my %nstart_grammar = (
  nstart_rule => A('x',O(A(qr/sdf/,'nstart_rule'), 'y')),
  x => qr/x/,
  y => qr/y/
);

my $nstart_parser;
eval {$nstart_parser = new Parse::Stallion(\%nstart_grammar,
);
};
is ($@, '', 'start rule nst');

print "\nAll done\n";
