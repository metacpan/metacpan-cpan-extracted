use Perl6::Rules;
use Test::Simple 'no_plan';

$str = "abrAcadAbbra";

@expected = (
	[ 0 => 'abrAcadAbbra' ],
	[ 0 => 'abrAcadA'     ],
	[ 0 => 'abrAca'       ],
	[ 0 => 'abrA'         ],
	[ 3 =>    'AcadAbbra' ],
	[ 3 =>    'AcadA'     ],
	[ 3 =>    'Aca'       ],
	[ 5 =>      'adAbbra' ],
	[ 5 =>      'adA'     ],
	[ 7 =>        'Abbra' ],
);

for my $rep (1..2) {
	ok( $str =~ m:i:exhaustive/ a .+ a /, "Repeatable every-way match ($rep)" );

	ok( @$0 == @expected, "Correct number of matches ($rep)" );
	my %expected; @expected{map $_->[1], @expected} = (1) x @expected;
	my %position; @position{map $_->[1], @expected} = map $_->[0], @expected;
	for (@$0) {
		ok ( $expected{$_}, "Matched '$_' ($rep)" );
		ok ( $position{$_} == $_->pos, "At correct position of '$_' ($rep)" );
		delete $expected{$_},
	}
	ok( keys %expected == 0, "No matches missed ($rep)" );
}

ok( "abcdefgh" !~ m:exhaustive/ a .+ a /, "Failed every-way match" );
ok( @$0 == 0, "No matches" );

ok( $str =~ m:e:i/ a (.+) a /, "Capturing every-way match" );

ok( @$0 == @expected, "Correct number of capturing matches" );
my %expected; @expected{map $_->[1], @expected} = (1) x @expected;
for (@$0) {
	ok ( $expected{$_}, "Capture matched '$_'" );
	ok ( $_->[1] = substr($_->[0],1,-1), "Captured within '$_'" );
	delete $expected{$_},
}

@adj  = qw(time);
@noun = qw(time flies arrow);
@verb = qw(time flies like);
@art  = qw(an);
@prep = qw(like);

ok ( "time flies like an arrow" =~
	m:we/^    [
				$?adj  := (@::adj)
				$?subj := (@::noun)
				$?verb := (@::verb)
				$?art  := (@::art)
				$?obj  := (@::noun)
			  |
				$?subj := (@::noun)
				$?verb := (@::verb)
				$?prep := (@::prep)
				$?art  := (@::art)
				$?obj  := (@::noun)
			  |
				$?verb := (@::verb)
				$?obj  := (@::noun)
				$?prep := (@::prep)
				$?art  := (@::art)
				$?noun := (@::noun)
			  ]
		   /, "Multiple capturing" );

ok( $0->[0]{adj}  eq 'time',  'Capture 0 adj' );
ok( $0->[0]{subj} eq 'flies', 'Capture 0 subj' );
ok( $0->[0]{verb} eq 'like',  'Capture 0 verb' );
ok( $0->[0]{art}  eq 'an',    'Capture 0 art' );
ok( $0->[0]{obj}  eq 'arrow', 'Capture 0 obj' );

ok( $0->[1]{subj} eq 'time',  'Capture 1 subj' );
ok( $0->[1]{verb} eq 'flies', 'Capture 1 verb' );
ok( $0->[1]{prep} eq 'like',  'Capture 1 prep' );
ok( $0->[1]{art}  eq 'an',    'Capture 1 art' );
ok( $0->[1]{obj}  eq 'arrow', 'Capture 1 obj' );

ok( $0->[2]{verb} eq 'time',  'Capture 2 verb' );
ok( $0->[2]{obj}  eq 'flies', 'Capture 2 obj' );
ok( $0->[2]{prep} eq 'like',  'Capture 2 prep' );
ok( $0->[2]{art}  eq 'an',    'Capture 2 art' );
ok( $0->[2]{noun} eq 'arrow', 'Capture 2 noun' );


rule subj  { <noun> }
rule obj   { <noun> }
rule noun  { time | flies | arrow }
rule verb  { flies | like | time }
rule adj   { time }
rule art   { an? }
rule prep  { like }

ok(             "time   flies   like    an     arrow" =~
	m:w:e/^ [ <?adj>  <?subj> <?verb> <?art> <?obj>
			| <?subj> <?verb> <?prep> <?art> <?noun> 
		    | <?verb> <?obj>  <?prep> <?art> <?noun>
			]
		 /,
	"Any with capturing rules"
);

ok( $0->[0]{adj}  eq 'time',  'Rule capture 0 adj' );
ok( $0->[0]{subj} eq 'flies', 'Rule capture 0 subj' );
ok( $0->[0]{verb} eq 'like',  'Rule capture 0 verb' );
ok( $0->[0]{art}  eq 'an',    'Rule capture 0 art' );
ok( $0->[0]{obj}  eq 'arrow', 'Rule capture 0 obj' );

ok( $0->[1]{subj} eq 'time',  'Rule capture 1 subj' );
ok( $0->[1]{verb} eq 'flies', 'Rule capture 1 verb' );
ok( $0->[1]{prep} eq 'like',  'Rule capture 1 prep' );
ok( $0->[1]{art}  eq 'an',    'Rule capture 1 art' );
ok( $0->[1]{noun} eq 'arrow', 'Rule capture 1 noun' );

ok( $0->[2]{verb} eq 'time',  'Rule capture 2 verb' );
ok( $0->[2]{obj}  eq 'flies', 'Rule capture 2 obj' );
ok( $0->[2]{prep} eq 'like',  'Rule capture 2 prep' );
ok( $0->[2]{art}  eq 'an',    'Rule capture 2 art' );
ok( $0->[2]{noun} eq 'arrow', 'Rule capture 2 noun' );


ok(	"fooooo" !~ m:exhaustive{ s o+ }, "Subsequent failed any match...");
ok( @$0 == 0, '...leaves @$0 empty' );
