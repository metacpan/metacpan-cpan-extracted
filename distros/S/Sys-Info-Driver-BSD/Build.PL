use strict;
use warnings;
use lib qw( builder );
use Build;

my $mb = Build->new;
$mb->change_versions(1);
$mb->copyright_first_year( '2009' );
$mb->add_pod_author_copyright_license(1);
$mb->create_build_script;

1;
