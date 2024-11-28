use Perlmazing;
use Time::Precise 'is_leap_year';

sub main ($) {
	define is_leap_year($_[0]);
}