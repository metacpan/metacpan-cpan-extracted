use feature ":all";
use strict;
use warnings;
#use strict;
#no warnings "uninitialized";
use Template::Plex;
use Data::Dumper;
use File::Basename qw<dirname>;

my @items=qw<eggs watermellon hensteeth>;
my $hash={
	title=>"Mr",
	surname=>"chick",
	items=>\@items
};

my $root=dirname __FILE__;

my $template=Template::Plex->load("external.plex", $hash, root=>$root, no_include=>0);

say $template->render();
