use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract', qw(:flags) ); }

my $pc = new_ok( 'Solaris::ProcessContract' );

ok( my $template = $pc->get_template, 'get new template' );

isa_ok( $template, 'Solaris::ProcessContract::Template' );

ok( ( my $parameters_default         = $template->get_parameters         ) > -1,  'get_parameters default' );
ok( ( my $informative_events_default = $template->get_informative_events ) > -1,  'get_informative_events default' );
ok( ( my $fatal_events_default       = $template->get_fatal_events       ) > -1,  'get_fatal_events default' );
ok( ( my $critical_events_default    = $template->get_critical_events    ) > -1,  'get_critical_events default' );

is( $template->set_parameters( CT_PR_PGRPONLY ), undef, 'set_parameters' );
is( $template->get_parameters, CT_PR_PGRPONLY,          'get_parameters' );

is( $template->set_informative_events( CT_PR_EV_FORK ), undef, 'set_informative_events' );
is( $template->get_informative_events, CT_PR_EV_FORK,          'get_informative_events' );

is( $template->set_fatal_events( CT_PR_EV_HWERR ), undef, 'set_fatal_events' );
is( $template->get_fatal_events, CT_PR_EV_HWERR,          'get_fatal_events' );

is( $template->set_critical_events( CT_PR_EV_HWERR ), undef, 'set_critical_events' );
is( $template->get_critical_events, CT_PR_EV_HWERR,          'get_critical_events' );

is( $template->activate, undef, 'activate');
is( $template->clear, undef,    'clear');
is( $template->reset, undef,    'reset');

is( $template->get_parameters, $parameters_default,                 'get_parameters after reset' );
is( $template->get_informative_events, $informative_events_default, 'get_informative_events after reset' );
is( $template->get_fatal_events, $fatal_events_default,             'get_fatal_events after reset' );
is( $template->get_critical_events, $critical_events_default,       'get_critical_events after reset' );


done_testing();
