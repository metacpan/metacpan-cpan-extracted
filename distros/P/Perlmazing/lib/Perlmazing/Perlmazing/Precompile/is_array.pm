use Perlmazing qw(_is_ref);

sub main ($) {
	_is_ref('ARRAY', $_[0]);
}

