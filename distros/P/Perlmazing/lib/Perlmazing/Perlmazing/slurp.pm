use Perlmazing qw(croak);

sub main {
	my $file = shift;
	my $binary = shift;
  my $encoding;
  {
    no warnings 'numeric';
    if ($binary and ($binary + 0) == 0) {
      $encoding = $binary;
      undef $binary;
    }
  }
	croak "File '$file' cannot be read: $!" unless open my $in, '<'.($encoding ? ":encoding($encoding)" : ''), $file;
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