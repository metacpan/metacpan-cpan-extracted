use Perlmazing qw(croak);

sub main {
  my $filename = shift;
  my $data = shift;
  my $binmode = shift;
  my $encoding;
  {
    no warnings 'numeric';
    if ($binmode and ($binmode + 0) ne '1') {
      $encoding = $binmode;
      undef $binmode;
    }
  }
  open my $out, '>'.($encoding ? ":encoding($encoding)" : ''), $filename or croak "Cannot write to $filename: $!";
  binmode($out) if $binmode;
  print $out $data;
  close $out;
}

1;