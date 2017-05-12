#!/usr/bin/perl -w

our $exts =
{
  h => 1,
  c => 1,
  xs => 1,
  pl => 1,
  pm => 1,
  pod => 1,
  ppd => 1,
  ppm => 1,
  mak => 1,
  nff => 1,
  yml => 1,
  arb => 1,
  cg => 1,
  glsl => 1,
  txt => 1
};

my($path) = @ARGV;
die qq
{
  USAGE: cleanup.pl FILE_PATH | DIRECTORY

} if (!$path);

clean_path($path);
exit 0;


sub clean_path
{
  my($dir) = @_;

  if (!-d $dir)
  {
    clean_file($dir);
    return;
  }
  return if (!opendir(DIR,$dir));

  foreach my $file (readdir(DIR))
  {
    next if ($file =~ m|^\.|);
    my $path = "$dir/$file";
    clean_path($path);
  }
  closedir(DIR);
}

sub clean_file
{
  my($path) = @_;

  if ($path =~ m|~$|)
  {
    unlink($path);
    return;
  }

  if ($path =~ m|\.([^/\.]+)$|)
  {
    my $ext = lc($1);
    return if (!$exts->{$ext} &&
      $path !~ m|Makefile$| &&
      $path !~ m|readme\.$ext|i);
  }

  if (!open(FILE,$path))
  {
    print "Unable to read '$path'\n";
    return;
  }

  my @data = <FILE>;
  close(FILE);

  my $data;
  foreach my $line (@data)
  {
    $line =~ s|[\n\r]+||gs;
    $data .= "$line\n";
  }

  die "Unable to write to $path\n" if (!open(FILE,">$path"));
  print FILE $data;
  close(FILE);
  print "Cleaned '$path'\n";
}
