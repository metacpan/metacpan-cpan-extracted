use Perl6::Form 'drill';

my @data = (
	{name=>'Smith', rank=>'PFC', num=>12345 },
	{name=>'Yeun',  rank=>'Corporal', num=>34521 },
	{name=>'Patton', rank=>'General', num=>00012 },
);

print form
	'      Rank Name         Serial Number',
	'{]]]]]]]]} {[[[[[[[[[}     {IIIII}',
	drill @data, [], [qw{rank name num}];

print "\n\n";

print form
	'      Rank Name         Serial Number',
	{under=>"="},
	'{]]]]]]]]} {[[[[[[[[[}     {IIIII}',
	drill @data, [], [qw{rank name num}];

print "\n\n";
