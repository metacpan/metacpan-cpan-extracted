use v5.12;
use warnings;

my $path_tiny_min = "0.054";
my $pod_markdown_min = "3.100";
my $have_prereqs = eval {
  require Path::Tiny;
  require Pod::Markdown;
  Path::Tiny->VERSION($path_tiny_min) && Pod::Markdown->VERSION($pod_markdown_min)
};

unless ($have_prereqs) {
  printf "Don't have Path::Tiny %s and Pod::Markdown %s; skipping pod2md.PL\n",
    $pod_markdown_min, $path_tiny_min;
  exit 0;
}
Path::Tiny->import;

# write POD as <Module>.md in relevant lib/ subdirs
my $pm = path(shift);
exit unless $pm->basename =~ /\.pm$/;
my $md = "$pm";
$md =~ s/pm$/md/;
$md = path($md);

my $mdstr = '';
my $p2m = Pod::Markdown->new();
$p2m->local_module_url_prefix('github::');
$p2m->local_module_re(qr/^Neo4j::Bolt(?:$|::)/);
$p2m->output_string(\$mdstr);
$p2m->parse_file("$pm");

$mdstr =~ s/%3A%3A/::/g;
$mdstr =~ s{(\][(]github::[^)]*[)])}
	   {
	     $_ = $1;
	     s|github::|/lib/|;
	     s|::|/|g;
	     s|[)]$|.md)|;
	     $_
	   }eg;
if (length $mdstr > 1) {
  my $fh = $md->openw();
  print $fh $mdstr;
}

1;
