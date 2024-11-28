use Perlmazing qw(_isa_ref);

sub main ($) {
	_isa_ref('GLOB', $_[0]);
}

