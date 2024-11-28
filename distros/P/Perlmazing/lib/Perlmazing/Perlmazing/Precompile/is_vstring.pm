use Perlmazing qw(_is_ref);

sub main ($) {
	_is_ref('VSTRING', $_[0]);
}
