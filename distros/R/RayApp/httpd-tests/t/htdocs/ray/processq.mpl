
sub handler {
	my $q = shift;
	my $id = $q->param('id');
	my $value = $q->param('value');

	if (not defined $id
		and not defined $value
		and defined $q->body) {
		$value = $q->body;
	}
	my $bad = $q->param('bad');
	return {
		out_id => $id,
		out_value => $value,
		( defined($bad) ? ( out_bad => $bad ) : () ),
	}
}

1;

