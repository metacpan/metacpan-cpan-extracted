my $file = 'opengl32.txt';
die "Unable to read '$file'" if (!open(FILE,$file));

my $exports = 'exports.txt';
die "Unable to write '$exports'" if (!open(EXPORTS,">$exports"));
binmode EXPORTS;

foreach my $line (<FILE>)
{
  next if ($line !~ m|\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+ (gl[\w]+)|);
  print EXPORTS "$1\n";
}
close(EXPORTS);
close(FILE);
