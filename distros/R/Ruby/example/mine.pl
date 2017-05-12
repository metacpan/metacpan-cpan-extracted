#!/usr/bin/perl
# a simple minesweeper implement, ported from $ruby_source/sample/mine.rb

use strict;
use warnings;

use Ruby -all;

my $bd = Board->new(
	10, # hight
	10, # width
	10, # num of bombs
);

system "stty raw -echo";

while(true){
	$_ = getc;

	if($_ eq 'n'){
		$bd->reset;
	}
	elsif($_ eq 'm'){
		$bd->mark;
	}
	elsif($_ eq 'j'){
		$bd->down;
	}
	elsif($_ eq 'k'){
		$bd->up;
	}
	elsif($_ eq 'h'){
		$bd->left;
	}
	elsif($_ eq 'l'){
		$bd->right;
	}
	elsif($_ eq ' '){
		$bd->open;
	}
	elsif($_ eq 'q'){
		$bd->quit;
		last;
	}

	if($bd->is_over){
		my $c;
		print "\nquit?(y/n) ";
		1 while(($c = lc getc) !~ /^[yn]/);

		$c eq 'y' and last;

		$bd->reset;
	}
}

puts;

END{
	system "stty -raw echo";
}


BEGIN{
	package Board;
	use Ruby; # import symbols
	use Ruby -base => 'Object';

	Array->alias('aref', '[]');
	Array->alias('aset', '[]=');

	# colors
	our $Default = 46;
	our $Opened  = 43;
	our $Over    = 45;

	our @CHR = ('. ', '1 ', '2 ', '3 ', '4 ', '5 ', '6 ', '7 ', '8 ', 'M ', 'B ', '@ ');

	__PACKAGE__->attr_accessor(qw(_hi _wi _m _ms _total
		_cx _cy _mc _over _data _state));

	sub info{
		my($self) = @_;

		$self->pos(0, $self->{'_hi'});
		print "the rest: ", $self->{'_mc'}, "/", $self->{'_total'}, "    ";
		$self->pos();
	}

	sub clr{
		my($self) = @_;
		print "\e[2J";
	}

	sub pos{
		my($self, $x, $y) = @_;
		$x ||= $self->{'_cx'};
		$y ||= $self->{'_cy'};
		printf "\e[%d;%dH", $y+1, $x*2+1;
	}
	sub colorstr{
		my($self, $id, $s) = @_;
		printf "\e[%dm%s\e[0m", $id, $s;
	}

	sub put{
		my($self, $x, $y, $col, $str) = @_;

		$self->pos($x, $y);
		$self->colorstr($col, $str);
		$self->info();
	}

	sub new{
		my($class, $h, $w, $m) = @_;

		my $self = $class->SUPER::new();

		$self->{'_hi'} = $h;
		$self->{'_wi'} = $w;
		$self->{'_m'}  = $m;

		$self->reset;

		return $self;
	}

	sub reset{
		my($self) = @_;

		Kernel->srand();

		$self->{'_cx'} = 0;
		$self->{'_cy'} = 0;
		$self->{'_mc'} = $self->{'_m'};
		$self->{'_over'} = false;
		$self->{'_data'}  = Array->new($self->{'_hi'} * $self->{'_wi'});
		$self->{'_state'} = Array->new($self->{'_hi'} * $self->{'_wi'});
		$self->{'_total'} = $self->{'_hi'} * $self->{'_wi'};
		$self->{'_total'}->times(sub{
			my($i) = @_;
			$self->{'_data'}->aset($i, 0);
		});

		$self->{'_m'}->times(sub{
			while(true){
				my $j = Kernel->rand($self->{'_total'} - 1);
				if($self->{'_data'}->aref($j) == 0){
					$self->{'_data'}->aset($j, 1);
					last;
				}
			}
		});

		$self->clr;
		$self->pos(0, 0);
		$self->{'_hi'}->times(sub{
			my($y) = @_;
			$self->pos(0, $y);
			$self->colorstr($Default, $CHR[0] * $self->{'_wi'});
		});

		$self->info();
	}

	sub mark{
		my($self) = @_;

		my $ix = $self->{'_wi'} * $self->{'_cy'} + $self->{'_cx'};
		my $s = $self->{'_state'}->aref($ix);
		if($s == nil){
			$self->{'_state'}->aset($ix, "MARK");

			$self->{'_mc'}    -= 1;
			$self->{'_total'} -= 1;
			$self->put($self->{'_cx'}, $self->{'_cy'}, $Opened, $CHR[9]);
		}
		elsif($s == "MARK"){
			$self->{'_state'}->aset($ix, nil);

			$self->{'_mc'}    += 1;
			$self->{'_total'} += 1;

			$self->put($self->{'_cx'}, $self->{'_cy'}, $Default, $CHR[0]);
		}
		elsif($s == "OPEN"){
			return;
		}
	}

	sub open{
		my($self, $x, $y) = @_;
		$x ||= $self->{'_cx'};
		$y ||= $self->{'_cy'};

		my $wi = $self->{'_wi'};
		my $hi = $self->{'_hi'};
		my $state = $self->{'_state'};

		if($state->aref($wi * $y + $x) == "OPEN"){ return 0 }
		if($state->aref($wi * $y + $x) == nil) {
			$self->{'_total'} -= 1;
		}
		if($state->aref($wi * $y + $x) == "MARK"){
			$self->{'_mc'} += 1;
		}

		$self->{'_state'}->aset($wi * $y + $x, "OPEN");

		if($self->fetch($x, $y) == 1){
			$self->{'_over'} = 1;
			return;
		}

		my $c = $self->count($x, $y);
		$self->put($x, $y, $Opened, $CHR[$c]);

		return if $c != 0;

		if($x > 0 && $y > 0)        { $self->open($x-1, $y-1) }
		if($y > 0)                  { $self->open($x,   $y-1) }
		if($x < $wi-1 && $y > 0)    { $self->open($x+1, $y-1) }
		if($x > 0)                  { $self->open($x-1, $y)   }
		if($x < $wi-1)              { $self->open($x+1, $y)   }
		if($x > 0 && $y < $hi-1)    { $self->open($x-1, $y+1) }
		if($y < $hi-1)              { $self->open($x,   $y+1) }
		if($x < $wi-1 && $y < $hi-1){ $self->open($x+1, $y+1) }

		$self->pos();
	}

	sub fetch{
		my($self, $x, $y) = @_;

		if($x < 0)             { return 0 }
		elsif($x >= $self->{'_wi'}){ return 0 }
		elsif($y < 0)          { return 0 }
		elsif($y >= $self->{'_hi'}){ return 0 }
		else{
			$self->{'_data'}->aref($y * $self->{'_wi'} + $x);
		}
	}
	sub count{
		my($self, $x, $y) = @_;

		$self->fetch($x-1, $y-1) + $self->fetch($x,   $y-1) + $self->fetch($x+1, $y-1) +
		$self->fetch($x-1, $y)   +                          + $self->fetch($x+1, $y)   +
		$self->fetch($x-1, $y+1) + $self->fetch($x,   $y+1) + $self->fetch($x+1, $y+1);
	}

	sub over{
		my($self, $win) = @_;

		$self->quit();
		unless($win){
			$self->pos();
			print $CHR[11];
		}
		$self->pos(0, $self->{'_hi'});

		if($win){
			print "*** YOU WIN ! ***";
		}
		else{
			print "*** GAME OVER ***";
		}
	}

	sub is_over{
		my($self) = @_;
		my $remain = ($self->{'_mc'} + $self->{'_total'} == 0);

		if($self->{'_over'} || $remain){
			$self->over($remain);
			return true;
		}
		else{
			return false;
		}
	}

	sub quit{
		my($self) = @_;

		$self->{'_hi'}->times(sub{ my($y) = @_;
			$self->pos(0, $y);
			$self->{'_wi'}->times(sub{ my($x) = @_;
			
				$self->colorstr(
					$self->{'_state'}->aref($y*$self->{'_wi'}+$x) == "MARK"
						? $Default : $Over,
					$self->fetch($x, $y) == 1
						? $CHR[10] : $CHR[ $self->count($x, $y) ]);
			});
		});
	}
	sub down
	{
		my($self) = @_;

		if($self->{'_cy'} < $self->{'_hi'}-1){
			$self->{'_cy'} += 1;
			$self->pos();
		}
	}
	sub up
	{
		my($self) = @_;

		if($self->{'_cy'} > 0){
			$self->{'_cy'} -= 1;
			$self->pos();
		}
	}
	sub left
	{
		my($self) = @_;

		if($self->{'_cx'} > 0){
			$self->{'_cx'} -= 1;
			$self->pos();
		}
	}
	sub right
	{
		my($self) = @_;
		if($self->{'_cx'} < $self->{'_wi'}-1){
			$self->{'_cx'} += 1;
			$self->pos();
		}
	}
}
