#!perl -T

use Test::More tests => 13;

BEGIN {
	use_ok( 'SIOC' );
    use_ok( 'SIOC::Community');
    use_ok( 'SIOC::Container');
    use_ok( 'SIOC::Exporter');
    use_ok( 'SIOC::Forum');
    use_ok( 'SIOC::Item');
    use_ok( 'SIOC::Post');
    use_ok( 'SIOC::Role');
    use_ok( 'SIOC::Site');
    use_ok( 'SIOC::Space');
    use_ok( 'SIOC::Thread');
    use_ok( 'SIOC::User');
    use_ok( 'SIOC::Usergroup');
}
