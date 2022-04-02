#Import C<plex> and C<plx> into you package:
#
use Template::Plex;

#Setup variables/data you want to alias:
#
my $vars={
	size=>"large",
	slices=>8,
	people=>[qw<Kim Sam Harry Sally>
	]
};

local $"=", ";

#Load a template from __DATA__
#
my $template=plex \*DATA, $vars;

#Render it:
#
my $output=$template->render;

print $output;
print "\n";

#Change values and render it again:
#
$vars->{size}="extra large";
$vars->{slices}=12;

$output=$template->render;
print $output;
print "\n";



#Write a template:
__DATA__
Ordered a $size pizza with $slices slices to share between @$people and myself.
That averages @{[ $slices/(@$people+1)]} slices each.
