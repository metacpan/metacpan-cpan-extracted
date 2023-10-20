#!perl
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Net::API::CPAN::Scroll' ) || BAIL_OUT( "Uanble to load Net::API::CPAN::Scroll" );
};

done_testing();

__END__
