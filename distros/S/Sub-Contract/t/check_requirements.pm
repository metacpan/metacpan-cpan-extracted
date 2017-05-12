#
#   $Id: check_requirements.pm,v 1.4 2009/06/01 20:43:06 erwan_lemonnier Exp $
#
#   check that all required modules are available
#

eval "use accessors"; plan skip_all => "missing module 'accessors'" if ($@);
eval "use Sub::Name"; plan skip_all => "missing module 'Sub::Name'" if ($@);
1;
