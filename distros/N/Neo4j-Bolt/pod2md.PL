use v5.10;
use Try::Tiny;
use strict;
use warnings;

my $have_p2m = eval "require Pod::Markdown; 1";

unless ($have_p2m) {
  print "Don't have Pod::Markdown; skipping pod2md.PL\n";
  exit 0;
}
require Path::Tiny;
Path::Tiny->import;

# write POD as <Module>.md in relevant lib/ subdirs
my $pm = path(shift);
return unless $pm->basename =~ /\.pm$/;
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
