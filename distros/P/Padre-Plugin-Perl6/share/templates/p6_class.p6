use v6;

=begin Pod
	An example of a Perl 6 class
=end Pod
class Point {
	# attributes; 
	# note that variable initialization is not automatic in Perl 6
	has Num $.x = 0;
	has Num $.y = 0;

	# a method to move to a new location
	method move(Num $new_x, Num $new_y) {
		$.x = $new_x;
		$.y = $new_y;
	}
	
	method to_string() {
		return $.x ~ "," ~ $.y; 
	}
}

# Create a point and initializes its attributes
my $pt1 = Point.new();
my $pt2 = Point.new(:x(7), :y(8));
say $pt1.to_string;
say $pt2.to_string;