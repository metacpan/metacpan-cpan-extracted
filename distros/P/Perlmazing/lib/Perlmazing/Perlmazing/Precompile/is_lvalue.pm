use Perlmazing qw(_is_ref);

sub main ($) {
	_is_ref('LVALUE', $_[0]);
}

