use Perlmazing;

sub main {
	my ($type, $val) = @_;
	if (is_blessed $val) {
		$val->isa($type);
	} else {
		_is_ref $type, $val;
	}
}
