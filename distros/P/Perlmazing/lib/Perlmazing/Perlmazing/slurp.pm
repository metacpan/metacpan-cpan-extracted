use Perlmazing;

sub main {
	my $file = shift;
	my $binary = shift;
	local $/ = undef;
	croak "File '$file' cannot be read: $!" unless open my $in, '<', $file;
	binmode $in if -B $file or $binary;
	my $data = <$in>;
	close $in;
	$data;
}

1;