use strict;
use warnings;
use feature ":all";

use Template::Plex;

my %hash=(title=>"hello");
my @options=(root=>"examples");
my $template=plex "recursive-top.plex";#, "";#, {};#\%hash;#, @options;

$hash{title}="goodbye";
say $template;
#say $template->render({title=>"jacky"});


