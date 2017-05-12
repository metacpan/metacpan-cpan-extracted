#!perl

use strict;
use warnings;

use Test::More;

my $non_Moo_pkg = q{
package MyTest;
#use MooX::Role::Reconstruct;
with qw( MooX::Role::Reconstruct );
1;
};

eval $non_Moo_pkg;
like( $@, qr/syntax error/, 'rejects non-Moo package' );

my $Moo_after_pkg = q{
package MyTest;
with qw( MooX::Role::Reconstruct );
use Moo;
1;
};

eval $Moo_after_pkg;
like( $@, qr/syntax error/, 'Moo must be present first' );

my $Moo_before_pkg = q{
package MyTest;
use Moo;
with qw( MooX::Role::Reconstruct );
1;
};

eval $Moo_before_pkg;
is( $@, '', 'accepts Moo first being used' );

done_testing();

exit;

__END__
