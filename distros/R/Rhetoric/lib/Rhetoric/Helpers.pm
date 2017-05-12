package Rhetoric::Helpers;
use base 'Exporter';
use common::sense;
use aliased 'Squatting::H';
use Data::Page;
use Rhetoric::Formatters;
use IO::All;

our $F = $Rhetoric::Formatters::F;
our @EXPORT_OK   = qw(now slug rl wl file_owner $F);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# y m d h m s
sub now {
  my @d = localtime;
  return (
    $d[5]+1900,
    $d[4]+1,
    $d[3],
    $d[2],
    $d[1],
    $d[0]
  );
}

# make a url-friendly slug out of a post title
sub slug {
  # FIXME - protect against duplicate y-m-slug combinations
  my $title = shift;
  $title =~ s/^\W+//;
  $title =~ s/\W+$//;
  $title =~ s/\W+/-/g;
  return $title;
}

# read line
sub rl {
  my $file = shift;
  io($file)->chomp->getline();
}

# write line
sub wl {
  my $file = shift;
  my $line = shift;
  io($file) < "$line\n";
}

# owner of file
sub file_owner {
  my $file = shift;
  getpwuid( (stat($file))[4] );
}

1;
