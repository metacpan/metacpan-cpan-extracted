use strict;
use warnings;

use Test::More;


{
  package Local::Test::Exports::Default;
  ::use_ok( 'Solaris::ProcessContract', qw() );
  ::ok( exists &Solaris::ProcessContract::CT_PR_INHERIT, 'param flag is really there');
  ::ok( exists &Solaris::ProcessContract::CT_PR_EV_CORE, 'event flag is really there');
  ::ok( ! exists &CT_PR_INHERIT, 'param flag not exported by default');
  ::ok( ! exists &CT_PR_EV_CORE, 'event flag not exported by default');
}

{
  package Local::Test::Exports::Flags;
  ::use_ok( 'Solaris::ProcessContract', qw(:flags) );
  ::ok( exists &CT_PR_INHERIT, 'param flag exported by :flags');
  ::ok( exists &CT_PR_EV_CORE, 'event flag exported by :flags');
}

{
  package Local::Test::Exports::ParamFlags;
  ::use_ok( 'Solaris::ProcessContract', qw(:param_flags) );
  ::ok( exists &CT_PR_INHERIT,   'param flag exported by :param_flags');
  ::ok( ! exists &CT_PR_EV_CORE, 'event flag not exported by :param_flags');
}

{
  package Local::Test::Exports::EventFlags;
  ::use_ok( 'Solaris::ProcessContract', qw(:event_flags) );
  ::ok( ! exists &CT_PR_INHERIT, 'param flag not exported by :event_flags');
  ::ok( exists &CT_PR_EV_CORE,   'event flag exported by :event_flags');
}


done_testing();

