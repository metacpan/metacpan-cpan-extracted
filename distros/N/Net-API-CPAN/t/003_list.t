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
    use_ok( 'Net::API::CPAN::List' ) || BAIL_OUT( "Uanble to load Net::API::CPAN::List" );
    use_ok( 'Net::API::CPAN::Filter' ) || BAIL_OUT( "Uanble to load Net::API::CPAN::Filter" );
};

# The sample data is auto-generated
my $raw = join( '', <DATA> );
my $data = eval( $raw );
BAIL_OUT( "Unable to load sample data: $@" ) if( $@ );
my $items = $data->{hits}->{hits};
# diag( "ok" );
# require Data::Pretty;
# diag( Data::Pretty::dump( $data ) );
my $filter = Net::API::CPAN::Filter->new( match_all => 1, debug => $DEBUG );
isa_ok( $filter => 'Net::API::CPAN::Filter' );
BAIL_OUT( Net::API::CPAN::Filter->error ) if( !defined( $filter ) );

my $list = Net::API::CPAN::List->new( filter => $filter, debug => $DEBUG );
isa_ok( $list => 'Net::API::CPAN::List' );
BAIL_OUT( Net::API::CPAN::List->error ) if( !defined( $list ) );

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/List.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$list, ''$m'' );"'
can_ok( $list, 'api' );
can_ok( $list, 'container' );
can_ok( $list, 'data' );
can_ok( $list, 'filter' );
can_ok( $list, 'get' );
can_ok( $list, 'has_more' );
can_ok( $list, 'items' );
can_ok( $list, 'length' );
can_ok( $list, 'load' );
can_ok( $list, 'load_data' );
can_ok( $list, 'next' );
can_ok( $list, 'offset' );
can_ok( $list, 'page' );
can_ok( $list, 'page_type' );
can_ok( $list, 'pop' );
can_ok( $list, 'pos' );
can_ok( $list, 'postprocess' );
can_ok( $list, 'prev' );
can_ok( $list, 'push' );
can_ok( $list, 'request' );
can_ok( $list, 'shift' );
can_ok( $list, 'size' );
can_ok( $list, 'size_prop' );
can_ok( $list, 'timed_out' );
can_ok( $list, 'took' );
can_ok( $list, 'total' );
can_ok( $list, 'type' );
can_ok( $list, 'unshift' );

my $rv = $list->load_data( $data );
ok( $rv, 'load_data' );
BAIL_OUT( $list->error ) if( !defined( $rv ) );
isa_ok( $rv => 'Net::API::CPAN::List' );

my $api = $list->api;
isa_ok( $api => 'Net::API::CPAN', 'api returns an Net::API::CPAN object' );
$rv = $list->container;
is( $rv, 'hits', 'container' );
$rv = $list->filter;
ok( $rv, 'filter' );
$rv = $list->get(0);
ok( $rv, 'get' );
isa_ok( $rv => 'Net::API::CPAN::Author', '$list->get returns an object' );
$rv = $list->has_more;
ok( $rv, 'has_more' );
$rv = $list->items;
ok( $rv, 'items' );
isa_ok( $rv => 'Module::Generic::Array' );
is( $rv->length, scalar( @$items ), 'items total' );
is( $list->length, 10, 'length' );
$rv = $list->next;
isa_ok( $rv => 'Net::API::CPAN::Author', 'next -> Net::API::CPAN::Author object' );
is( $rv->pauseid, $items->[0]->{_source}->{pauseid}, 'next value' );
$rv = $list->offset;
isa_ok( $rv => 'Module::Generic::Number', 'offset returns a Module::Generic::Number object' );
is( "$rv", 0, 'offset value -> 0' );
$rv = $list->page;
isa_ok( $rv => 'Module::Generic::Number', 'page returns a Module::Generic::Number object' );
is( "$rv", 1, 'page value -> 1' );
$rv = $list->page_type;
isa_ok( $rv => 'Module::Generic::Scalar', 'page_type returns a Module::Generic::Scalar object' );
$rv = $list->pos;
ok( !ref( $rv ), 'pos returns a regular string' );
is( $rv, 0, 'pos -> 0' );
$rv = $list->next;
is( $rv->pauseid, $items->[1]->{_source}->{pauseid}, 'next value' );
$rv = $list->offset;
is( "$rv", 1, 'next increases offset value -> 1' );
is( $rv, 1, 'pos -> 0' );
$rv = $list->prev;
is( $rv->pauseid, $items->[0]->{_source}->{pauseid}, 'next value' );
isa_ok( $rv => 'Net::API::CPAN::Author', 'prev -> Net::API::CPAN::Author object' );
$rv = $list->postprocess;
ok( ref( $rv ) eq 'CODE', 'postprocess' );
$rv = $list->request;
is( $rv, undef, 'request' );
$rv = $list->size_prop;
isa_ok( $rv => 'Module::Generic::Scalar', 'page_type returns a Module::Generic::Scalar object' );
is( $rv, 'size', 'size_prop' );
ok( !$list->timed_out, 'timed_out' );
is( $list->took, $data->{took}, 'took' );
is( $list->total, $data->{hits}->{total}, 'total' );
is( $list->type, 'author', 'type -> "author"' );

done_testing();

__END__
{
    _shards => { failed => 0, successful => 3, total => 3 },
    hits => {
        hits => [
            {
                _id => "CHIRADETADULADEJ",
                _index => "cpan_v1_01",
                _score => 1.79900168287061,
                _source => {
                    asciiname => "Chiradet Aduladej",
                    city => "Bangkok",
                    country => "TH",
                    email => ["chiradet.aduladej\@example.th"],
                    gravatar_url => "https://secure.gravatar.com/avatar/Idw1IwNyNygsTYDMEWecAa117IK3uu8z?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Chiradet Aduladej",
                    pauseid => "CHIRADETADULADEJ",
                    profile => [{ id => 20731.018977305, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "LANDONWOOD",
                _index => "cpan_v1_01",
                _score => 0.559826898742024,
                _source => {
                    asciiname => "Landon Wood",
                    city => "Los Angeles",
                    country => "US",
                    email => ["landon.wood\@example.us"],
                    gravatar_url => "https://secure.gravatar.com/avatar/0zxM662ARNqS8XMXAP6jB0NoWjTG5qW3?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Landon Wood",
                    pauseid => "LANDONWOOD",
                    profile => [{ id => 386444.635324954, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "HEOCHAEHYUN",
                _index => "cpan_v1_01",
                _score => 4.12751090292518,
                _source => {
                    asciiname => "Heo Chaehyun",
                    city => "Busan",
                    country => "KR",
                    email => ["heo.chaehyun\@example.kr"],
                    gravatar_url => "https://secure.gravatar.com/avatar/jFv3HA8H7DMTuIUzNxwayZBY6SEhFNoB?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Heo Chaehyun",
                    pauseid => "HEOCHAEHYUN",
                    profile => [{ id => 725687.104897769, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "PAULWILSON",
                _index => "cpan_v1_01",
                _score => 3.67306625925742,
                _source => {
                    asciiname => "Paul Wilson",
                    city => "Gibraltar",
                    country => "UK",
                    email => ["paul.wilson\@example.uk"],
                    gravatar_url => "https://secure.gravatar.com/avatar/iBxmZC2PiyoMdhPD1kvSBdpP7dcDYXPd?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Paul Wilson",
                    pauseid => "PAULWILSON",
                    profile => [{ id => 590115.049034598, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "YANGJAEHO",
                _index => "cpan_v1_01",
                _score => 1.57795182656278,
                _source => {
                    asciiname => "Yang Jaeho",
                    city => "Daegu",
                    country => "KR",
                    email => ["yang.jaeho\@example.kr"],
                    gravatar_url => "https://secure.gravatar.com/avatar/28Ap48CrAVlkRyNH3p8LNNl3Wqwz3vIe?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Yang Jaeho",
                    pauseid => "YANGJAEHO",
                    profile => [{ id => 487018.044069942, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "TEDDYSAPUTRA",
                _index => "cpan_v1_01",
                _score => 0.582441718097151,
                _source => {
                    asciiname => "Teddy Saputra",
                    city => "Jakarta",
                    country => "ID",
                    email => ["teddy.saputra\@example.id"],
                    gravatar_url => "https://secure.gravatar.com/avatar/VCvadMNcAvrP88m8pGau40i3SHfLyvu7?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Teddy Saputra",
                    pauseid => "TEDDYSAPUTRA",
                    profile => [{ id => 814410.886475565, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "ENGYONGCHANG",
                _index => "cpan_v1_01",
                _score => 0.195135238728117,
                _source => {
                    asciiname => "Eng Yong Chang",
                    city => "Singapore",
                    country => "SG",
                    email => ["eng.yong.chang\@example.sg"],
                    gravatar_url => "https://secure.gravatar.com/avatar/0qzKXrfel3xbvjwoPrr4EzmS4t83BThI?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Eng Yong Chang",
                    pauseid => "ENGYONGCHANG",
                    profile => [{ id => 70064.8571762778, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "ADRIANCARTER",
                _index => "cpan_v1_01",
                _score => 1.19471323673167,
                _source => {
                    asciiname => "Adrian Carter",
                    city => "Los Angeles",
                    country => "US",
                    email => ["adrian.carter\@example.us"],
                    gravatar_url => "https://secure.gravatar.com/avatar/oarF7hbWKHO9MxEuETOjiW9NGaD9vYoG?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Adrian Carter",
                    pauseid => "ADRIANCARTER",
                    profile => [{ id => 511439.549177453, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "TONGSHUHUI",
                _index => "cpan_v1_01",
                _score => 2.72889024786648,
                _source => {
                    asciiname => "Tong Shu Hui",
                    city => "Singapore",
                    country => "SG",
                    email => ["tong.shu.hui\@example.sg"],
                    gravatar_url => "https://secure.gravatar.com/avatar/2NR1fqOn5pzWoh9l8yroqNusHRjsK4mS?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Tong Shu Hui",
                    pauseid => "TONGSHUHUI",
                    profile => [{ id => 998343.115456378, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
            {
                _id => "MATHILDECATTIN",
                _index => "cpan_v1_01",
                _score => 0.632386423942002,
                _source => {
                    asciiname => "Mathilde Cattin",
                    city => "Paris",
                    country => "FR",
                    email => ["mathilde.cattin\@example.fr"],
                    gravatar_url => "https://secure.gravatar.com/avatar/9jM8ZMhbhAXofNRJ0738NhHexOOY7Vfm?s=130&d=identicon",
                    is_pause_custodial_account => 0,
                    name => "Mathilde Cattin",
                    pauseid => "MATHILDECATTIN",
                    profile => [{ id => 622560.336289786, name => "stackoverflow" }],
                    updated => "2023-08-10T11:08:24",
                },
                _type => "author",
            },
        ],
        max_score => 4.12751090292518,
        total => 30,
    },
    timed_out => 0,
    took => 11,
}
