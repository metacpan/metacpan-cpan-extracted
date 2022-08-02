# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
};

BEGIN
{
    use_ok( 'Storable::Improved' );
}

use strict;
use warnings;

can_ok( 'Storable::Improved', 'freeze' );
can_ok( 'Storable::Improved', 'thaw' );

done_testing();

__END__


