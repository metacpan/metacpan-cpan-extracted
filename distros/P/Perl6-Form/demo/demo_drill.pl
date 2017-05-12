use 5.010;
use warnings;

use Perl6::Form 'drill';

my @AoA = (
	[1,2,3],
	[4,5,6],
	[7,8,9],
);

my @AoH = (
	{a=>1,b=>2,c=>3},
	{a=>4,b=>5,c=>6},
	{a=>7,b=>8,c=>9},
);

my %HoA = (
	x=>[1,2,3],
	y=>[4,5,6],
	z=>[7,8,9],
);

my %HoH = (
	x=>{a=>1,b=>2,c=>3},
	y=>{a=>4,b=>5,c=>6},
	z=>{a=>7,b=>8,c=>9},
);


use Data::Dumper 'Dumper';

warn Dumper [ drill @AoA, [], [1,2]     ];
warn Dumper [ drill @AoH, [], ['b','c'] ];
warn Dumper [ drill %HoA, [], [1,2]     ];
warn Dumper [ drill %HoH, [], ['b','c'] ];

my @AoHoA = (
	{a=>[1,11,111],b=>[2,22,222],c=>[3,33,333]},
	{a=>[4,44,444],b=>[5,55,555],c=>[6,66,666]},
	{a=>[7,77,777],b=>[8,88,888],c=>[9,99,999]},
);

warn Dumper [ drill @AoHoA, [], ['b','c'] ];
warn Dumper [ drill @AoHoA, [], ['b','c'], [1,2] ];

my @AoHoAoH = (
	{a=>[{x=>1},{x=>11},{y=>111}],b=>[{x=>2},{y=>22},{x=>222}],c=>[{x=>3},{y=>33}]},
	{a=>[{x=>4},{x=>44},{y=>444}],b=>[{y=>5},{x=>55},{x=>555}],c=>[{x=>6},{y=>66}]},
);

warn Dumper [ drill @AoHoAoH, [], ['b','c'], [0], ['x'] ];
