use strict;
use warnings;
use feature ":all";

use Template::Plex;

my %hash=(title=>"hello");
my $template=plex "examples/html.plex"=>\%hash;
say $template->render({title=>"jacky"});
$hash{title}="goodbye";
say $template->render({title=>"jacky"});
