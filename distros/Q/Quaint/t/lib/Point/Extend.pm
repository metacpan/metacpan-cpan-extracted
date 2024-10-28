package Point::Extend;

use Quaint;

extends 'Point';

function {
	return sprintf "A point at (%s, %s)\n", $_[0]->x, $_[0]->y;
} qw/describe stringify/;

1;
