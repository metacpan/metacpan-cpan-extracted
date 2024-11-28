use Perlmazing qw(croak);

sub main {
	my $file = shift;
	my $binary = shift;
	croak "File '$file' cannot be read: $!" unless open my $in, '<', $file;
	binmode $in if -B $file or $binary;
  if (wantarray) {
    my @data = <$in>;
    close $in;
    return @data;
  } else {
    local $/ = undef;
    my $data = <$in>;
    close $in;
    return $data;
  }
}

1;