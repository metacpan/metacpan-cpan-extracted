use Test;
BEGIN { plan tests => 4 };
ok(1);

use Parse::Pyapp;
use Data::Dumper;
my $parser = Parse::Pyapp->new();

$parser->addrule('S',
	       [ 'VP', 0.433, ],
	       [ 'NP', 'VP', 'PREP', 'NP', 0.567, ],
	       );
$parser->addrule('NP',
	       [ 'DET', 'N', 0.3, ],
	       [ 'DET', 'ADJ', 'N', .5, sub { $_[0]->{var}->{$_[2]} = $_[0]->{pos}->[2]} ],
	       [ 'DET', 'ADJ', 'ADJ', 'N', .2, ]
	       );

$parser->addrule('VP',
	       [ 'V', 0.5 ],
	       [ 'V', 'NP', .5 ]
	       );

$parser->addlex('N',
		  [ 'fox', .5 ],
		  [ 'dog', .5 ]
		  );
$parser->addlex('V', [ 'jumps', 1 ],
		sub{
		    $_[0]->{var}->{$_[1]}= $_[0]->{lhs};
		});
$parser->addlex('DET', [ 'the', 1, ]);
$parser->addlex('ADJ', [ 'brown', 1 ],[ 'lazy', 1 ],);
$parser->addlex('PREP', [ 'over', 1 ]);

$parser->start('S');

ok($parser->parse('the', 'brown', 'fox', 'jumps', 'over', 'the', 'lazy', 'fox'), 1);
ok($parser->{var}->{jumps}, 'V');
ok($parser->{var}->{brown}, 'ADJ');

