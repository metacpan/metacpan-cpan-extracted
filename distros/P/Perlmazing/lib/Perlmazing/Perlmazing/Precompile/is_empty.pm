use Perlmazing qw(not_empty);

sub main ($) {
	not_empty($_[0]) ? 0 : 1;
}

