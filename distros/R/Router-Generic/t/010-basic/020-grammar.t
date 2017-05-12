#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Router::Generic');

ok(
  my $router = Router::Generic->new(),
  "Got router object"
);


EN_US_A: {
  my $router = Router::Generic->new();
  $router->add_route(
    name      => 'LangLocale1',
    path      => '/{langLocale:[a-z]{2}\-[a-z]{2}}/',
    target    => '/wiki.asp'
  );
  
  is(
    $router->match('/en-us/'),
    '/wiki.asp?langLocale=en-us',
    '/en-us/ (A)'
  );
};


EN_US_B: {
  my $router = Router::Generic->new();
  $router->add_route(
    name      => 'LangLocale1',
    path      => '/:lang/:locale/',
    target    => '/wiki.asp'
  );
  
  is(
    $router->match('/en/us/'),
    '/wiki.asp?lang=en&locale=us',
    '/en/us/ (B)'
  );
};


GROUP_A: {
  $router->add_route(
    name      => "Categories",
    path      => '/categories/{*Category}',
    target    => '/category.asp',
    defaults  => {
      Category  => 'All',
    }
  );

  is(
    $router->match('/categories/') => '/category.asp?Category=All',
    '/categories/ (A)'
  );

  is(
    $router->match('/categories/Trucks/') => '/category.asp?Category=Trucks',
    '/categories/Trucks/ (B)'
  );

  is(
    $router->match('/categories/Trucks') => '/category.asp?Category=Trucks',
    '/categories/Trucks (C)'
  );

  is(
    $router->match('/categories/Trucks/with/stuff') => '/category.asp?Category=Trucks%2Fwith%2Fstuff',
    '/categories/Trucks/with/stuff (C)'
  );
};


GROUP_B: {
  $router->add_route(
    name      => "Products",
    path      => '/products/{Category}/{Product}',
    target    => '/product.asp',
    defaults  => {
      Product  => 'All',
    }
  );
  
  is(
    $router->match('/products/Trucks/') => '/product.asp?Category=Trucks&Product=All',
    '/products/Trucks/'
  );
  
  is(
    $router->match('/products/Trucks/F-150/') => '/product.asp?Category=Trucks&Product=F-150',
    '/products/Trucks/F-150/'
  );
};


GROUP_B: {
  $router->add_route(
    name      => "Foo",
    path      => '/foo/{*Bar}',
    target    => '/foo.asp'
  );
  
  is(
    $router->match('/foo/') => '/foo.asp',
    '/foo/ (A)'
  );
  
  is(
    $router->match('/foo/bar') => '/foo.asp?Bar=bar',
    '/foo/bar (B)'
  );
  
  is(
    $router->match('/foo/bar/') => '/foo.asp?Bar=bar',
    '/foo/bar/ (C)'
  );
  
  is(
    $router->match('/foo/bar/baz') => '/foo.asp?Bar=bar%2Fbaz',
    '/foo/bar/baz (D)'
  );
  
  is(
    $router->match('/foo/bar/baz/') => '/foo.asp?Bar=bar%2Fbaz',
    '/foo/bar/baz/ (D)'
  );
};



GROUP_C: {
  $router->add_route(
    name      => "Pages",
    path      => '/pages/{page:\d*}',
    target    => '/page.asp',
    defaults  => { page => 1 },
  );
  
  is(
    $router->match('/pages/') => '/page.asp?page=1',
    '/pages/ (A)'
  );
  
  is(
    $router->match('/pages/1') => '/page.asp?page=1',
    '/pages/1 (B)'
  );
  
  is(
    $router->match('/pages/1/') => '/page.asp?page=1',
    '/pages/1/ (C)'
  );
  
  is(
    $router->match('/pages/sdf/') => undef,
    '/pages/sdf/ (C)'
  );
};


GROUP_D: {
  $router->add_route(
    name      => "ProductReviews",
    path      => '/shop/:cat/{Product}/reviews/{reviewPage:\d+}',
    target    => '/product-reviews.asp'
  );
  
  is(
    $router->match('/shop/dogs/Huskie/reviews/7/') =>
      '/product-reviews.asp?cat=dogs&Product=Huskie&reviewPage=7',
    '/shop/dogs/Huskie/reviews/7/'
  );
};



# Extra:
$router->add_route(
  name      => 'Simple',
  path      => '/Foo/bar',
  target    => '/foobar.asp',
);
is( $router->match('/Foo/bar/') => '/foobar.asp', 'Simplest route works' );

$router->add_route(
  name      => 'Zipcodes1',
  path      => '/zip/:code',
  target    => '/zipcode.asp',
);

$router->add_route(
  name      => 'Zipcodes2',
  path      => '/zip/:code/hospitals/',
  target    => '/zipcode-hospitals.asp',
);

$router->add_route(
  name      => 'Zipcodes3',
  path      => '/zip/:code/banks/',
  target    => [ '/zipcode-[:code:].asp', '/zip-[:code:].asp' ],
);

is(
  $router->match('/zip/90210/') => '/zipcode.asp?code=90210',
  'Plain zipcode',
);

is(
  $router->match('/zip/90210/hospitals/') => '/zipcode-hospitals.asp?code=90210',
  'Zipcode with hospitals'
);

is_deeply
  [qw( /zipcode-20202.asp?code=20202 /zip-20202.asp?code=20202 )], scalar( $router->match('/zip/20202/banks/') ), "Matched list of targets in scalar context";

my @matches = $router->match('/zip/20202/banks/');
is_deeply [qw( /zipcode-20202.asp?code=20202 /zip-20202.asp?code=20202 )], \@matches, "Matched list of targets in list context";

METHODS: {
  my $router = Router::Generic->new();
  
  $router->add_route(
    name  => 'CreatePage',
    path  => '/main/:type/create',
    target  => '/pages/[:type:].create.asp',
    method  => 'GET'
  );
  
  $router->add_route(
    name  => 'Create',
    path  => '/main/:type/create',
    target  => '/handlers/dev.[:type:].create',
    method  => 'POST'
  );
  
  $router->add_route(
    name  => 'View',
    path  => '/main/:type/{id:\d+}',
    target  => '/pages/[:type:].view.asp',
    method  => '*',
  );
  
  $router->add_route(
    name  => 'List',
    path  => '/main/:type/list/{page:\d+}',
    target  => '/pages/[:type:].list.asp',
    method  => '*',
    defaults  => { page => 1 }
  );
  
  $router->add_route(
    name  => 'Delete',
    path  => '/main/:type/delete/{id:\d+}',
    target  => '/handlers/dev.[:type:].delete',
    method  => 'POST'
  );
  
  is(
    $router->uri_for('CreatePage', { type => 'truck' }) => '/main/truck/create/',
    "CreatePage uri is correct"
  );

  is(
    $router->match('/main/truck/create/') => '/pages/truck.create.asp?type=truck',
    "CreatePage is matched properly."
  );
  
  is(
    $router->uri_for('Create', { type => 'truck' }) => '/main/truck/create/',
    "Create uri is correct"
  );

  is(
    $router->match('/main/truck/create/', 'POST') => '/handlers/dev.truck.create?type=truck',
    "Create uri matched correctly"
  );
  
  is(
    my $view_page = $router->uri_for('View', {type => 'truck', id => 123}) => '/main/truck/123/',
    "View uri for truck is correct"
  );
  
  is(
    $router->match($view_page) => '/pages/truck.view.asp?id=123&type=truck',
    "View uri matched correctly"
  );
  
  is(
    my $list_page = $router->uri_for('List', {type => 'truck'}) => '/main/truck/list/1/',
    "List uri for truck is correct"
  );
  
  is(
    $router->match($list_page) => '/pages/truck.list.asp?page=1&type=truck',
    "List uri matched correctly"
  );
  
  is(
    my $delete_page = $router->uri_for('Delete', {type => 'truck', id => 123}) => '/main/truck/delete/123/',
    "Delete uri for truck is correct"
  );
  
  is(
    $router->match($delete_page) => '/handlers/dev.truck.delete?id=123&type=truck',
    "Delete uri matched correctly"
  );
  
};


MULTI: {
  my $router = Router::Generic->new();
  
  $router->add_route(
    name    => 'Colon-Colon',
    path    => '/:lang-:locale/{*page}',
    target  => '/[:lang:]/[:locale:]/[:page:].asp',
    defaults  => {
      lang    => 'en',
      locale  => 'us',
      page    => 'index'
    }
  );
  
  $router->add_route(
    name    => 'Curly-Curly',
    path    => '/wiki/{lang}-{locale}/{*page}',
    target  => '/[:lang:]/[:locale:]/[:page:].asp',
    defaults  => {
      lang    => 'en',
      locale  => 'us',
      page    => 'index'
    }
  );
  
  $router->add_route(
    name    => 'Colon-Curly',
    path    => '/wikiA/:lang-{locale}/{*page}',
    target  => '/[:lang:]/[:locale:]/[:page:].asp',
    defaults  => {
      lang    => 'en',
      locale  => 'us',
      page    => 'index'
    }
  );
  
  $router->add_route(
    name    => 'Curly-Colon',
    path    => '/wikiB/{lang}-:locale/{*page}',
    target  => '/[:lang:]/[:locale:]/[:page:].asp',
    defaults  => {
      lang    => 'en',
      locale  => 'us',
      page    => 'index'
    }
  );
  
  is( $router->match('/en-us/trucks/') => '/en/us/trucks.asp?lang=en&locale=us&page=trucks', "Colon-Colon" );
  is( $router->uri_for('Colon-Colon') => '/en-us/index/', "uri for Colon-Colon" );
  
  is( $router->match('/wiki/en-us/trucks/') => '/en/us/trucks.asp?lang=en&locale=us&page=trucks', "Curly-Curly" );
  is( $router->uri_for('Curly-Curly') => '/wiki/en-us/index/', "uri for Curly-Curly" );
  
  is( $router->match('/wikiA/en-us/trucks/') => '/en/us/trucks.asp?lang=en&locale=us&page=trucks', "Colon-Curly" );
  is( $router->uri_for('Colon-Curly') => '/wikiA/en-us/index/', "uri for Colon-Curly" );
  
  is( $router->match('/wikiB/en-us/trucks/') => '/en/us/trucks.asp?lang=en&locale=us&page=trucks', "Curly-Colon" );
  is( $router->uri_for('Curly-Colon') => '/wikiB/en-us/index/', "uri for Curly-Colon" );
};




