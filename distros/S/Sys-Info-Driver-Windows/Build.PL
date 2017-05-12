use strict;
use warnings;
use lib qw( builder );
use My;

my $mb = My->new;
$mb->change_versions(1);
$mb->copyright_first_year( '2006' );
$mb->add_pod_author_copyright_license(1);
$mb->initialization_hook( <<'HOOK' );
    require My::Util;
    My::Util::write_detect_h();
HOOK
$mb->create_build_script;

1;
