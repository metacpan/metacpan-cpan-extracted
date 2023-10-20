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
    use_ok( 'Net::API::CPAN::Filter' ) || BAIL_OUT( "Uanble to load Net::API::CPAN::Filter" );
};

my $filter = Net::API::CPAN::Filter->new( debug => $DEBUG );
isa_ok( $filter => 'Net::API::CPAN::Filter' );
BAIL_OUT( Net::API::CPAN::Filter->error ) if( !defined( $filter ) );

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Filter.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$filter, ''$m'' );"'
can_ok( $filter, 'aggregations' );
can_ok( $filter, 'aggs' );
can_ok( $filter, 'apply' );
can_ok( $filter, 'as_hash' );
can_ok( $filter, 'as_json' );
can_ok( $filter, 'es' );
can_ok( $filter, 'fields' );
can_ok( $filter, 'filter' );
can_ok( $filter, 'from' );
can_ok( $filter, 'match_all' );
can_ok( $filter, 'name' );
can_ok( $filter, 'query' );
can_ok( $filter, 'reset' );
can_ok( $filter, 'size' );
can_ok( $filter, 'sort' );
can_ok( $filter, 'source' );

done_testing();

__END__
