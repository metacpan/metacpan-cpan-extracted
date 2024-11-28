use Perlmazing qw(is_blessed define _is_ref);

sub main {
	my ($type, $val) = @_;
	if (is_blessed $val) {
		define $val->isa($type);
	} else {
		define _is_ref $type, $val;
	}
}
