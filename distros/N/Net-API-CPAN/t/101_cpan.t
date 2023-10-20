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
    use_ok( 'Net::API::CPAN' ) || BAIL_OUT( "Uanble to load Net::API::CPAN" );
};

my $cpan = Net::API::CPAN->new( debug => $DEBUG );
isa_ok( $cpan => 'Net::API::CPAN' );
BAIL_OUT( Net::API::CPAN->error ) if( !defined( $cpan ) );

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$cpan, ''$m'' );"'
can_ok( $cpan, 'activity' );
can_ok( $cpan, 'api_uri' );
can_ok( $cpan, 'api_version' );
can_ok( $cpan, 'author' );
can_ok( $cpan, 'autocomplete' );
can_ok( $cpan, 'cache_file' );
can_ok( $cpan, 'changes' );
can_ok( $cpan, 'clientinfo' );
can_ok( $cpan, 'contributor' );
can_ok( $cpan, 'cover' );
can_ok( $cpan, 'diff' );
can_ok( $cpan, 'distribution' );
can_ok( $cpan, 'download_url' );
can_ok( $cpan, 'favorite' );
can_ok( $cpan, 'fetch' );
can_ok( $cpan, 'file' );
can_ok( $cpan, 'first' );
can_ok( $cpan, 'http_request' );
can_ok( $cpan, 'http_response' );
can_ok( $cpan, 'history' );
can_ok( $cpan, 'json' );
can_ok( $cpan, 'mirror' );
can_ok( $cpan, 'module' );
can_ok( $cpan, 'new_filter' );
can_ok( $cpan, 'package' );
can_ok( $cpan, 'permission' );
can_ok( $cpan, 'pod' );
can_ok( $cpan, 'rating' );
can_ok( $cpan, 'release' );
can_ok( $cpan, 'reverse' );
can_ok( $cpan, 'search' );
can_ok( $cpan, 'source' );
can_ok( $cpan, 'suggest' );
can_ok( $cpan, 'top_uploaders' );
can_ok( $cpan, 'ua' );
can_ok( $cpan, 'web' );

my $rv;
$rv = $cpan->api_uri;
isa_ok( $rv => 'URI', 'api_uri' );
is( $cpan->api_version, 1, 'api_version' );

$rv = $cpan->ua;
isa_ok( $rv => 'HTTP::Promise', 'ua' );

done_testing();

__END__
