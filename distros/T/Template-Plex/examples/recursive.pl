use strict;
use warnings;
use feature ":all";

use File::Basename qw<dirname>;

use Template::Plex;

my %hash=(title=>"hello");

my $root=dirname __FILE__;

my @options=(root=>$root);

my $template=Template::Plex->load( "recursive-top.plex", {}, @options);

$hash{title}="goodbye";
say $template->render;
#say $template->render({title=>"jacky"});


