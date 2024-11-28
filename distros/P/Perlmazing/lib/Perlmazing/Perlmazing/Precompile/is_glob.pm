use Perlmazing qw(_is_ref);

sub main ($) {
	_is_ref('GLOB', $_[0]);
}

