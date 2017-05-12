use 5.010;
use warnings;


use Perl6::Form qw(form drill);

# Easy when data already in columns...

@name  = qw(Tom Dick Harry);
@score = qw( 88   54    99);
@time  = qw( 15   13    18);

print form
	'-------------------------------------------',   
	'Name             Score   Time  | Normalized',   
	'-------------------------------------------',   
	'{[[[[[[[[[[[[}   {III}   {II}  |  {]]].[[}',
	 \@name,          \@score,\@time, [map $score[$_]/$time[$_], 0..$#score];

print "\n"x2;

# Not so easy when data in rows...

@data = (
	{ name=>'Tom',   score=>88, time=>15 },
	{ name=>'Dick',  score=>54, time=>13 },
	{ name=>'Harry', score=>99, time=>18 },
);


# The ugly way...

print form
'-----------------------------',   
'Name             Score   Time',   
'-----------------------------',   
'{[[[[[[[[[[[[}   {III}   {II}',
[map $$_{name},  @data],
[map $$_{score}, @data],
[map $$_{time} , @data];

print "\n"x2;

# The even nicer way...

print form
'-----------------------------',   
'Name             Score   Time',   
'-----------------------------',   
'{[[[[[[[[[[[[}   {III}   {II}',
drill @data, [], [qw{name score time}];


# Works for arrays of arrays too, and multiple lists...

@data = (
	[ 15, 'Tom',   88 ],
	[ 13, 'Dick',  54 ],
	[ 18, 'Harry', 99 ],
);

print "\n"x2;


print form
'--------------------------------------',   
'Name             Score   Time  | Total',   
'--------------------------------------',   
'{[[[[[[[[[[[[}   {III}   {II}  | {III}',
drill @data, [], [1,2,0,2];

# Even works for hashes of arrays...

%data = (
	a => [ 15, 'Tom',   88 ],
	b => [ 13, 'Dick',  54 ],
	c => [ 18, 'Harry', 99 ],
);

print "\n"x2;


print form
'--------------------------------------',   
'Name             Score   Time  | Total',   
'--------------------------------------',   
'{[[[[[[[[[[[[}   {III}   {II}  | {III}',
drill %data, [], [1,2,0,2];
