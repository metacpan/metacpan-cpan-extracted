use strict;
use warnings;
use File::Find;

my @list = ([]);

my $count = 1;
find(sub {
  /\.pc$/ && do {
    push @{ $list[-1] }, $File::Find::name;
    push @list, [] if @{ $list[-1] } == 50;
  }
}, 't/data/usr');

my $template = do {
  open my $fh, '<', 't/data/iterfiles_template';
  local $/;
  <$fh>;
};

my $i = 0;
foreach my $list (@list)
{
  my $fn = sprintf "t/02-iterfiles-FLISTa%s.t", chr(ord('a')+$i++);
  print "$fn\n";
  
  my $content = "$template";
  $content =~ s{#LIST}{join("\n", @$list)}e;
  open my $fh, '>', $fn;
  print $fh $content;
  close $fh;
}
