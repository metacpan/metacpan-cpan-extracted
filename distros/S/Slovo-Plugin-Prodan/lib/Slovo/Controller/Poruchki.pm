package Slovo::Controller::Poruchki;
use Mojo::Base 'Slovo::Controller', -signatures;
use Mojo::Util qw(dumper decode );

use Mojo::JSON qw(true false from_json to_json);

# POST /poruchki
# Create and store a new order.
# Invoked via OpenAPI by cart.js
sub store ($c) {
  $c->debug('Request body' => Mojo::Util::decode('utf8' => $c->req->body));
  $c->openapi->valid_input or return;

  # Why ->{Poruchka}{Poruchka} ????
  my $o        = $c->validation->output->{Poruchka}{Poruchka};
  my $order_id = $c->_create_order($o)
    || return;    # error is logged and a message is rendered to the user
  $c->_create_way_bill($o, $order_id)
    || return;    # error is logged and a message is rendered to the user
  $c->debug('poruchka' => $o);
  return $c->render(openapi => $o, status => 201);
}

sub _create_order ($c, $o) {

  state $shop = $c->config->{shop};
  state $app  = $c->app;
  my $orders = $c->poruchki;

  # POST to Econt to create order
  my $_order_struct = $c->_order_struct($o);
  my $eco_res       = $app->ua->request_timeout(5)->post(
    $shop->{crupdate_order_endpoint} =>
      {'Content-Type' => 'application/json', Authorization => $shop->{private_key}},
    json => $_order_struct
  )->res;
  $c->debug(
    'req_url: '        => $shop->{crupdate_order_endpoint},
    ' $_order_struct:' => $_order_struct
  );
  $c->debug('$eco_res->json:' => $eco_res->json);
  if ($eco_res->is_success) {
    $o->{deliverer_id} = $eco_res->json->{id} + 0;
    $o->{created_at}   = $o->{tstamp} = time;

    # Store in our database
    # TODO: Implement control panel for orders, invoices, products
    my $id = $orders->add({
      poruchka => to_json($o),
      map { $_ => $o->{$_} }
        qw(deliverer_id deliverer name email phone city_name created_at tstamp)
    });
    return $id;
  }

  # Something is wrong if we get to here. Log the error and inform the user
  # that something is wrong with the communication between us and Econt.
  $app->log->error('Error from _create_order($c,$o): Econt Status:'
      . $eco_res->code
      . $/
      . 'Econt Response:'
      . decode(utf8 => $eco_res->body)
      . $/
      . __FILE__ . ':'
      . __LINE__);

  $c->render(
    openapi => {
      errors => [{
        path    => $c->url_for . '',
        message => 'Изпращането на поръчката към доставчика се провали.'
          . $/
          . 'Състояние: '
          . $eco_res->code
          . $/
          . 'Опитваме се да се поправим. Извинете за неудобството.'
      }]
    },
    status => 418
  );

  return;
}

sub _create_way_bill ($c, $o, $id) {

  state $shop = $c->config->{shop};
  state $app  = $c->app;
  my $orders = $c->poruchki;

  # $c->debug('Poruchka:' => $o);
  # POST to Econt to create order
  my $_order_struct = $c->_order_struct($o);
  my $eco_res       = $c->app->ua->request_timeout(5)->post(
    $shop->{create_awb_endpoint} =>
      {'Content-Type' => 'application/json', Authorization => $shop->{private_key}},
    json => $_order_struct
  )->res;
  $c->debug(
    'req_url: '        => $shop->{create_awb_endpoint},
    ' $_order_struct:' => $_order_struct
  );
  my $way_bill = $eco_res->json;
  $c->debug('товарителница $eco_res->json:' => $way_bill);
  if ($eco_res->is_success) {
    $o->{tstamp}      = time;
    $o->{way_bill_id} = $way_bill->{shipmentNumber};

    # update in our database
    # TODO: Implement control panel for orders, invoices, products
    $orders->save(
      $id,
      {
        way_bill => to_json($way_bill),
        poruchka => to_json($o),
        map { $_ => $o->{$_} } qw(tstamp way_bill_id)
      },

    );
    return 1;
  }

  $app->log->error('Error from _create_way_bill($c,$o): Econt Status:'
      . $eco_res->code
      . $/
      . 'Econt Response:'
      . decode(utf8 => $eco_res->body)
      . $/
      . __FILE__ . ':'
      . __LINE__);

  $c->render(
    openapi => {
      errors => [{
        path    => $c->url_for . '',
        message => "Създаването на товарителница се провали, но поръчката ви "
          . "($o->{deliverer_id}) е приета."
          . " Ще се свържем с вас на предоствения от вас телефон."
          . $/
          . 'Състояние: '
          . $eco_res->code
          . $/
          . 'Опитваме се да се поправим. Извинете за неудобството.'
      }]
    },
    status => 418
  );

  return;
}

# Returns a structure for JSON body for a create/update query and a way bill (товарителница) to Econt.
# First time this is passed without id to create one at deliverer site.
# Second time the deliverer_id is passed as id.
# 1. $shop->{crupdate_order_endpoint}
# 2. $shop->{create_awb_endpoint}
sub _order_struct ($c, $o) {
  my $items = $o->{items};
  return {

    ($o->{deliverer_id} ? (id => $o->{deliverer_id}) : ()),

    #id => $o->{id},
    #orderNumber         => $o->{id},
    cod => 1,

    # NOTE!!! TODO: Implement automatic Invoice creation from order!
    # Which field is for "invoice_num" as reported in the error from Econt???
    declaredValue => $o->{sum},
    currency      => $o->{shipping_price_currency},

    # TODO: implement product types as started in table products column type.
    shipmentDescription => (
      'книг' . (@$items > 1 ? 'и' : 'а') . ' ISBN: ' . join ';',
      map {"$_->{sku}: $_->{quantity}бр."} @$items
    ),
    receiverShareAmount => $o->{shipping_price_cod} || 0,
    customerInfo        => {
      name        => $o->{name},
      face        => $o->{face},
      phone       => $o->{phone},
      email       => $o->{email},
      countryCode => $o->{id_country},
      cityName    => $o->{city_name},
      postCode    => $o->{post_code},
      officeCode  => $o->{office_code},
      address     => ($o->{office_code} ? "" : $o->{address}),
      quarter     => $o->{quarter},
      street      => $o->{street},
      num         => $o->{num},
      other       => $o->{other},
    },
    items => [
      map { {
        name        => $_->{title},
        SKU         => $_->{sku},
        count       => $_->{quantity},
        hideCount   => 0,
        totalPrice  => ($_->{quantity} * $_->{price}),
        totalWeight => ($_->{quantity} * $_->{weight}),
      } } @$items
    ]};
}

# GET /poruchka/:deliverer/:id
# show an order by given :deliverer and :id with that deliverer.
# Invoked via OpenAPI by cart.js
sub show ($c) {
  $c->openapi->valid_input or return;
  my $deliverer    = $c->param('deliverer');
  my $deliverer_id = $c->param('deliverer_id');

  # Initially generated checksum by the econt order form. Only a user having
  # the order in his localStorage has it. If the user clears it's cache in
  # the browser, the order and this checksum is lost. The 'id' query
  # parameter is to prevent from brute force guessing.
  my $id = $c->param('id');

  my $order = $c->poruchki->find_where({
    deliverer    => $deliverer,
    deliverer_id => $deliverer_id,
    poruchka     => {-like => qq|%"id":"$id"%|}});

  return $c->render(
    openapi => {errors => [{path => $c->url_for . '', message => 'Not Found'}]},
    status  => 404
  ) unless $order;

  # TODO: check for changes on econt side each two ours or more. If there is
  # a way_bill_id, store the updated order and show it to the user.

  $order->{poruchka} = from_json($order->{poruchka});
  return $c->render(openapi => $order->{poruchka});
}

# GET /api/shop
# provides shipment data to the page on which the form for shipping the
# collected goods in the cart is called.
sub shop ($c) {

  # TODO: some logic to use the right shop. We may have multiple
  # shops(physical stores) from which we send the orders.  For example we may
  # choose the shop depending on the IP-location of the user. We want to use
  # the closest store to the user to minimise delivery expenses.

  # Copy data without private_key.
  state $shop = {map { $_ eq 'private_key' ? () : ($_ => $c->config->{shop}{$_}) }
      keys %{$c->config->{shop}}};
  return $c->render(openapi => $shop);
}

# GET /api/gdpr_consent
# Provides various settings to the client side like the url for the page where
# are described the detailed conditions to use the site and the cookies policy
# - GDPR.
sub consents ($c) {
  state $consents = $c->config('consents');
  $consents->{ihost} //= $c->ihost_only;
  return $c->render(openapi => $consents);
}

1;

