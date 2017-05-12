# -*- perl -*-

# t/002_pov.t - check pov code accuracy

use Games::Roguelike::Utils qw(:all);

#### TEST POV ####

my @map;
my @res;

BEGIN {

$map[0] = '
 12345678
1######k#
2#@.....#
3###..###
';
$res[0] = 1;

$map[1] = '
 12345678
1######k#
2######.#
3#@.....#
4###  ###
';
$res[1] = 0;

$map[2] = '
 12345678
1#..k####
2#.#....#
3#@.#...#
4###  ###
';
$res[2] = 0;

$map[3] = '
 12345678
1    k
2    ###
3     @#
';
$res[3] = 0;

$map[4] = '
 12345678
1#@#    #
2# #    #
3# #    #
4##k  ###
';
$res[4] = 1;

$map[5] = '
 12345678
1#@#k   #
2#      #
3#      #
4##   ###
';
$res[5] = 0;

$map[6] = '
 12345678
1#@#    # 
2# #k   #
3#      #
4#    ###
';
$res[6] = 0;

$map[7] = '
 12345678
1#@..k  #
2#      #
3#      #
4#    ###
';
$res[7] = 1;

}

use Test::More tests => scalar(@map);

$i = 0;
for my $map (@map) {
	my @m;
	my ($x, $y, $cx, $cy, $tx, $ty);
	$y=0;
	for (split(/\n/, $map)) {
		next if /^$/;
		$x = 0;
		for (split(//, $_)) {
			if ($_ eq '@') {
				$cx = $x;
				$cy = $y;
				$m[$x][$y] = '.';
			} elsif ($_ eq 'k') {
				$tx = $x;
				$ty = $y;
				$m[$x][$y] = '.';
			}  else {
				$m[$x][$y] = $_;
			}
		++$x;
		}
		++$y;
	}

	my $r = Games::Roguelike::Area->new(noconsole=>1);
	my $c = Games::Roguelike::Mob->new($r, x=>$cx,y=>$cy,pov=>6);
	$r->{map} = \@m;
	$r->{w} = @m;
	$r->{h} = @{$m[0]};
	my $ok = $r->checkpov($c, $tx, $ty);
	ok($ok == $res[$i], "map $i pov");
	++$i;
}
