use Perlmazing;
use Time::Precise 'is_valid_date';

sub main ($) {
	define is_valid_date($_[0]);
}