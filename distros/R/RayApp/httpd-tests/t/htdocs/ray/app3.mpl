
sub handler {
	my $q = shift;

	# my $m = scalar($q->param('m'));
	# use Data::Dumper; print STDERR Dumper $q, $m;

	return {
		id => 13,
		data => $ENV{RAYAPP_ENV_DATA},
		m => scalar($q->param('m')),
		n => scalar($q->param('n')),
	};
}

1;

