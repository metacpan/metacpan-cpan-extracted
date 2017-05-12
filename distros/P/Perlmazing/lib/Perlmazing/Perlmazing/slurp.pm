use Perlmazing;

sub main {
	my $file = shift;
	local $/ = undef;
	croak "File '$file' cannot be read: $!" unless open my $in, '<', $file;
	binmode $in;
	my $data = <$in>;
	close $in;
	$data;
}

1;