package Point;

use Quaint;

num req default {
	0
} qw/x y/;

function {
	$_[0]->x($_[1]);
	$_[0]->y($_[2]);
} "move";

1;
