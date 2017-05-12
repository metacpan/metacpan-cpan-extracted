use strict;
use warnings;
use Test::More;
use Moose 2.1604;
use Test::Moose 2.1604;

BEGIN { use_ok('Term::YAP') }

foreach my $attrib (qw(size start_time usleep name rotatable time running)) {

    has_attribute_ok( 'Term::YAP', $attrib );

}

can_ok( 'Term::YAP',
    qw(get_size _set_start _set_start _get_usleep BUILD start _is_enough _keep_pulsing stop _report is_running _set_running)
);

done_testing();
