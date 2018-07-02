use lib qw(%PATH%/lib);
##################################################################################
#      path is set during make                                                    #
###############################################################################
use MySQL::Admin qw(:all);
use MySQL::Admin::Settings;
use DBI::Library qw(:all);
use DBI::Library::Database qw(:all);
loadSettings("%PATH%/config/settings.pl");
init("%PATH%/config/settings.pl");
### 3party
use URI::Escape;

# Apache2 mod perl stuff
# enable if the mod_perl 1.0 compatibility is needed
# use Apache2::compat ();
# preload all mp2 modules
use ModPerl::MethodLookup;
ModPerl::MethodLookup::preload_all_modules();
use ModPerl::Util        ();    #for CORE::GLOBAL::exit
use Apache2::RequestRec  ();
use Apache2::RequestIO   ();
use Apache2::RequestUtil ();
use Apache2::ServerUtil  ();
use Apache2::Connection  ();
use Apache2::Log         ();
use APR::Table           ();
use ModPerl::Registry    ();
use APR::Const -compile     => qw(:error SUCCESS);
use Apache2::Const -compile => qw(:log);
use Apache2::ServerRec qw(warn);
1;
