# t/003_cart - test the server-side of the shopping cart. TODO: test the browser-side too.
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(path tempdir);
use Mojo::Util qw(decode encode);

unless ($ENV{TEST_AUTHOR}) {
  plan( skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value.'
      . $/
      . 'Set SLOVO_PRODAN_SHOP_ID to your shop id, generated for you on https://delivery.econt.com'
      . $/
      . 'Set SLOVO_PRODAN_PRIVATE_KEY for your shop, generated also there.');
}

BEGIN {
  $ENV{MOJO_CONFIG} = path(__FILE__)->dirname->to_abs->child('slovo.conf');
};
note 'using ' . $ENV{MOJO_CONFIG};
my $install_root = tempdir('slovoXXXX', TMPDIR => 1, CLEANUP => 1);
my $t            = Test::Mojo->with_roles('+Slovo')->install(

# from => to
  undef() => $install_root,

# 0777
)->new('Slovo');
my $app  = $t->app;
my $shop = $app->config->{shop};
is $shop->{shop_id}     => $ENV{SLOVO_PRODAN_SHOP_ID},     'right shop id';
is $shop->{private_key} => $ENV{SLOVO_PRODAN_PRIVATE_KEY}, 'right private key';

# /api/shop endpoind is accessed by function get_set_shop_data() in cart.js
$t->get_ok('/api/shop')->status_is(200)->json_is('',
  {map { $_ eq 'private_key' ? () : ($_ => $shop->{$_}) } keys %$shop} =>
    'no private key for the browser');

# The user collects product items. Opens the Econt form which is shown in a
# iframe similarly to as described in Econt integration documentation and
# clicks on OK of the confirm dialog. The JavaScript form of the cart makes
# the following request. The order data structure comes from th econt iframe
# and is slightly modified by our cart.js
# POST /api/poruchki
# Body fo the request:
my $json_request_body = <<'JSON';
{"Poruchka":{"name":"Перко Наумов","face":null,"phone":"0700111222333","email":"",
"id_country":"1033","country_name":"България","city_name":"Бяла Слатина","post_code":"3200",
"office_code":"3201","office_name":"3201 - Бяла Слатина","zip":"","address":"3201 - Бяла Слатина",
"id":"6209309b59fed3fe091ed390dbec706c","shipping_price_currency_sign":"лв",
"shipping_price_currency":"BGN","shipping_price":4,"shipping_price_cod":4,
"shipping_price_cod_e":4,"country_code":"BGR",
"items":[{"sku":9786199169001,"title":"Житие на света Петка Българска от свети патриарх Евтимий"
,"quantity":2,"weight":0.5,"price":"7.00"},{"sku":9786199169025,
"title":"Лечителката и рунтавата ѝ котка","quantity":1,"weight":0.3,"price":"14.00"}],
"deliverer":"econt","sum":28,"weight":1.3}}
JSON

# The response contains the way bill id. We only have to bring the items packed
# together to the econt office, configured in our virtual shop.
my $json_response_body = <<'JSON';
{"address":"3201 - Бяла Слатина","city_name":"Бяла Слатина","country_code":"BGR","country_name":"България",
"created_at":1644769443,"deliverer":"econt","deliverer_id":1603834,"email":"","face":null,
"id":"6209309b59fed3fe091ed390dbec706c","id_country":"1033","items":[{"price":7.0,"quantity":2,
"sku":"9786199169001","title":"Житие на света Петка Българска от свети патриарх Евтимий","weight":0.5},
{"price":14,"quantity":1,"sku":"9786199169025","title":"Лечителката и рунтавата ѝ котка","weight":0.3}],
"name":"Перко Наумов","office_code":"3201","office_name":"3201 - Бяла Слатина","phone":"0700111222333",
"post_code":"3200","shipping_price":4,"shipping_price_cod":4,"shipping_price_cod_e":4,
"shipping_price_currency":"BGN","shipping_price_currency_sign":"лв","sum":28,"tstamp":1644769444,"way_bill_id":"1054243681518","weight":1.3,"zip":""}
JSON

my $json_struct = Mojo::JSON::from_json($json_response_body);
my $json_res
  = $t->post_ok('/api/poruchki' => {} => encode(UTF8 => $json_request_body))
  ->status_is(201)->json_is('/office_name' => $json_struct->{office_name})
  ->json_is('/shipping_price' => $json_struct->{shipping_price})
  ->json_like('/way_bill_id' => qr/^\d{13}$/)->tx->res->json;

# these values are stored in the database and in the orders for $ENV{SLOVO_PRODAN_SHOP_ID}
# https://delivery.econt.com/orders.php?id_shop=$ENV{SLOVO_PRODAN_SHOP_ID}
my $order
  = $app->dbx->db->select(orders => '*', {deliverer_id => $json_res->{deliverer_id}})
  ->hash;
is $order->{deliverer_id} => $json_res->{deliverer_id} => 'right deliverer_id '
  . $order->{deliverer_id};
is $order->{way_bill_id} => $json_res->{way_bill_id} => 'right way_bill_id '
  . $order->{way_bill_id};


done_testing();

