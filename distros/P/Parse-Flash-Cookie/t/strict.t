# strict.t

use warnings;
use strict;
use Test::More;

eval "use Test::Strict";
if ($@) {
	plan skip_all => "Test::Strict required for testing strictures" if $@;
} else {
	plan tests => 3;
}

syntax_ok( 'lib/Parse/Flash/Cookie.pm' );
strict_ok( 'Parse::Flash::Cookie', "use strict; in Parse::Flash::Cookie" );
warnings_ok( 'lib/Parse/Flash/Cookie.pm' );

__END__

