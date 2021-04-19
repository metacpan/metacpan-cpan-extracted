sub main ($) {
	my @call = caller;
	my $line = $call[2] - 1;
    my $header = qq[# line $call[2] "$call[1]"\n];
	my @r;
	my $e;
	{
		local $@;
		if (wantarray) {
			$r[0] = eval $_[0];
		} else {
			@r = eval $_[0];
		}
		if ($@) {
			$e = $@;
			$e .= "...called in eval_string at $call[1] line $call[2].";
		}
	}
	$@ = $e if $e;
	return wantarray ? @r : $r[0];
}