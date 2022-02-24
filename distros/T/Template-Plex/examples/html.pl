use strict;
use warnings;
use feature ":all";
use File::Basename qw<dirname>;

use Template::Plex;

my $root=dirname __FILE__;

my %hash=(title=>"hello");

my $template=plex "html.plex"=>\%hash, root=>$root;

say "Original base/lexical value and field value";
say $template->render({title=>"Jacky"});

#Updated base/lexical variable
$hash{title}="goodbye";

#rendered with updated field values
say "\n" x 2;
say "Updated base/lexical values and field values";
say $template->render({title=>"Johny"});
