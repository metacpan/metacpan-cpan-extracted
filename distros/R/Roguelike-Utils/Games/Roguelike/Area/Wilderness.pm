package Games::Roguelike::Area::Wilderness;

use base 'Games::Roguelike::Area';

use strict;
use Carp;
use Games::Roguelike::Utils qw(:all);

=head1 NAME

 Games::Roguelike::Area::Wilderness

=head1 SYNOPSIS

 use Games::Roguelike::World;

 $w = new Games::Roguelike::World(w=>40, h=>20);;
 $a = new Games::Roguelike::Area(world=>$w, name=>'upland');
 $a->generate('wilderness',
                {sym=>'T', color=>'green on black', weight=>2},
                {sym=>'"', color=>'white on green', weight=>2},
                {sym=>'~', color=>'white on blue', weight=>1},
                {sym=>'*', color=>'red on black', city=>1},
                city=>4
 );
 $w->drawmap();
 $w->getch();

=head1 DESCRIPTION

Area "generator" module.

Each argument to generate(...) is a terrain reference containing:

 sym => symbol to use for that terrain
 color => color to use for that terrain

And optionally:

 weight => weight of that terrain element in the generator, default 1, must be an integer
 ckey => elements with same numbers support each other's presence)

=head1 SEE ALSO

<L>Games::Roguelike::Area

=cut

sub generate {
	my $self = shift;
	my @terrain = @_;
	
	croak "terrain must be supplied" unless @terrain;
	
	my %opts;
	for (my $i=0; $i < @terrain; ++$i) {
		if (!ref($terrain[$i])) {
			my ($a, $b) = splice(@terrain, $i, 2);
			$opts{$a} = $b;
		}
	}
	
	
	# don't autoexplore over mountains and water
	$self->{nomove} = '~^';

	my $edge = $terrain[0];

	# this algorithm only works on up to 7 distinct terrain ckey's

	my @exterr;

	my $map = [];

	my $dex = 0;
	my %ck;
	for (@terrain) {
		$_->{index} = $dex++;
		$_->{ckey} = $_->{index};
		$_->{weight} ||= 1;
		$_->{weight} = 0 if $_->{city};
		for (my $i = 0; $i < $_->{weight}; ++$i) {
			push @exterr, $_;
		}
		$ck{$_->{ckey}} = 1;
	};

	my $numck = keys(%ck);

	my $terr_count = @exterr; 

	# random weighted terrain
	for (my $x = 0; $x < $self->{w}; ++$x) {
	for (my $y = 0; $y < $self->{h}; ++$y) {
		my $t = $exterr[int(rand()*$terr_count)];
		$map->[$x][$y] = {%{$t}};
	}
	}	

	# clustering algorithm
	my $iter = 3;
	for (1..$iter) {
        for (my $x = 1; $x < ($self->{w}-1); ++$x) {
        for (my $y = 1; $y < ($self->{h}-1); ++$y) {
                my $t = $map->[$x][$y];
		my $cnt = 0;
		my %cnt;
		for (@DD[0..7]) {
			my ($tx, $ty) = ($x, $y);
			my ($dx, $dy) = @$_;
			$tx += $dx;
			$ty += $dy;
			$cnt += 1 if $map->[$tx][$ty]->{ckey} == $t->{ckey};
			++$cnt{$map->[$tx][$ty]->{index}};
		}

		# sorted by most popular in region
		my @pop = sort {$cnt{$a}<=>$cnt{$b}} (keys(%cnt));

		# fewer than 8/num-unique-ckeys?
		if ($cnt < (8/$numck)) {
			$map->[$x][$y] = $terrain[$pop[$#pop]];	
		}
        }
        }
	}

	# copy to self->map
	# some day this should be redundant
        for (my $x = 0; $x < $self->{w}; ++$x) {
        for (my $y = 0; $y < $self->{h}; ++$y) {
		if (!$x || !$y || $x == ($self->{w}-1) || $y == ($self->{h}-1)) {
			$self->setmap($x, $y, $edge);
		}

		$self->setmap($x, $y, $map->[$x][$y]);
        }
        }

	if ($opts{city}) {
	  my ($water, $city, $city_color) = ('~', '*');
	  for (@terrain) {
		$water = $_->{sym} if $_->{water};
		$city = $_->{sym} if $_->{city};
		$city_color = $_->{color} if $_->{city};
	  }
	# todo: document this
	   for (1..$opts{city}) {
		my ($x, $y) = $self->findrandmap($water);
		my $dx = $self->{w}/2 - $x;
		my $dy = $self->{h}/2 - $y;
		$dx = $dx/abs($dx) if $dx;
		$dy = $dy/abs($dy) if $dy;

		while ($self->{map}->[$x][$y] eq $water) {
			$x+=$dx;
			$y+=$dy;
		}

		$self->addfeature($city, $x, $y);
		$self->setmap($x, $y, $city, $city_color);
	   }
	}
}

1;
