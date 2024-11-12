use Template::Plex;
use File::Basename qw<basename dirname>;
use File::Path qw<mkpath>;
use feature qw<:all>;
use Data::Dumper;

#Modes are:	preprocess
#		process

use feature ":all";
local $"="\n";

my $output="/dev/null";
my %page=(
	site=>"Site name",
	category=>"Category1",
	title=>"Page title",
	content=> $ARGV[1],
	html_root=>'site',
	stylesheets=>["stylesheets/common.css"],
	YEAR=>2022,
	output=>$output,
	mode=>"process",
);

my $dir= dirname __FILE__;

my $result=plx $ARGV[0], \%page, root=>$dir."/../";

say $output;
say $page{output};

$dir = dirname $page{output};
$dir= "$page{html_root}/$dir";

my $file= "$page{html_root}/$page{output}";

say "output dir: ", $dir;
mkpath $dir;

say "output file: ", $file;
open my $fh, ">", $file;

print $fh $result;

say "Page: ", Dumper \%page;
