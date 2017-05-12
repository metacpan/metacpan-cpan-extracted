#!/usr/bin/perl -w

use strict;

use Test::More tests => 1627;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
  use_ok('Rose::DB::Object::Helpers');
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

our %Have;

#
# Tests
#

use Rose::DB::Object::Constants qw(STATE_SAVING);

#$Rose::DB::Object::Manager::Debug = 1;

if(defined $ENV{'RDBO_NESTED_JOINS'} && Rose::DB::Object::Manager->can('default_nested_joins'))
{
  Rose::DB::Object::Manager->default_nested_joins($ENV{'RDBO_NESTED_JOINS'});
}

my $Include = 
  '^(?:' . join('|', qw(colors descriptions authors nicknames
                        description_author_map product_color_map
                        prices products vendors regions)) . ')$';
$Include = qr($Include);

foreach my $db_type (qw(sqlite mysql pg pg_with_schema informix))
{
  SKIP:
  {
    skip("$db_type tests", 325)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  Rose::DB::Object::Metadata->unregister_all_classes;

  # Test of the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(1)  if($db_type =~ /^pg/);

  my $db = Rose::DB->new;

  my $class_prefix = 
    ucfirst($db_type eq 'pg_with_schema' ? 'pgws' : $db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => $db,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => $Include);

  my $product_class = $class_prefix  . '::Product';
  my $manager_class = $product_class . '::Manager';

  Rose::DB::Object::Helpers->import(-target_class => $product_class, qw(as_tree new_from_tree init_with_tree));

  my $p1 = 
    $product_class->new(
      id     => 1,
      name   => 'Kite',
      vendor => { id => 1, name => 'V1', region => { id => 'DE', name => 'Germany' } },
      prices => 
      [
        { price => 1.25, region => { id => 'US', name => 'America' } }, 
        { price => 4.25, region => { id => 'DE', name => 'Germany' } },
      ],
      colors => 
      [
        {
          name => 'red',
          description => 
          {
            text => 'desc 1',
            authors => 
            [
              {
                name => 'john',
                nicknames => [ { nick => 'jack' }, { nick => 'sir' } ],
              },
              {
                name => 'sue',
                nicknames => [ { nick => 'sioux' } ],
              },
            ],
          },
        }, 
        {
          name => 'blue',
          description => 
          {
            text => 'desc 2',
            authors => 
            [
              { name => 'john' },
              {
                name => 'jane',
                nicknames => [ { nick => 'blub' } ],
              },
            ],
          }
        }
      ]);

  $p1->save;

  my $p2 = 
    $product_class->new(
      id     => 2,
      name   => 'Sled',
      vendor => { id => 2, name => 'V2', region_id => 'US', vendor_id => 1 },
      prices => [ { price => 9.25 } ],
      colors => 
      [
        { name => 'red' }, 
        {
          name => 'green',
          description => 
          {
            text => 'desc 3',
            authors => [ { name => 'tim' } ],
          }
        }
      ]);

  $p2->save;

  my $p3 = 
    $product_class->new(
      id     => 3,
      name   => 'Barn',
      vendor => { id => 3, name => 'V3', region => { id => 'UK', name => 'England' }, vendor_id => 2 },
      prices => [ { price => 100 } ],
      colors => 
      [
        { name => 'green' }, 
        {
          name => 'pink',
          description => 
          {
            text => 'desc 4',
            authors => [ { name => 'joe', nicknames => [ { nick => 'joey' } ] } ],
          }
        }
      ]);

  $p3->save;

  #local $Rose::DB::Object::Manager::Debug = 1;

  my $products = 
    $manager_class->get_products(
      db => $db,
      require_objects => [ 'vendor.vendor', 'vendor.region' ]);

  is(scalar @$products, 2, "require vendors 1 - $db_type");

  is($products->[0]{'vendor'}{'id'}, 2, "p2 - require vendors 1 - $db_type");
  is($products->[0]{'vendor'}{'vendor'}{'id'}, 1, "p2 - require vendors 2 - $db_type");
  is($products->[0]{'vendor'}{'region'}{'name'}, 'America', "p2 - require vendors 3 - $db_type");

  is($products->[1]{'vendor'}{'id'}, 3, "p3 - require vendors 1 - $db_type");
  is($products->[1]{'vendor'}{'vendor'}{'id'}, 2, "p3 - require vendors 2 - $db_type");
  is($products->[1]{'vendor'}{'region'}{'name'}, 'England', "p3 - require vendors 3 - $db_type");

  # No-op join override tests

  my $last_sql;
  my $i = 1;

  foreach my $pair ([ [], [ 'vendor.vendor', 'vendor.region' ] ], 
                    [ [], [ 'vendor!.vendor', 'vendor.region' ] ], 
                    [ [], [ 'vendor.vendor!', 'vendor.region' ] ], 
                    [ [], [ 'vendor.vendor!', 'vendor!.region' ] ], 
                    [ [], [ 'vendor.vendor!', 'vendor.region!' ] ], 
                    [ [], [ 'vendor!.vendor', 'vendor.region!' ] ], 
                    [ [], [ 'vendor.vendor!', 'vendor!.region' ] ], 
                    [ [], [ 'vendor!.vendor!', 'vendor!.region!' ] ])
  {
    my $sql = 
      $manager_class->get_objects_sql(
        db => $db,
        debug => 1,
        (@{$pair->[0]} ? (with_objects => $pair->[0]) : ()),
        (@{$pair->[1]} ? (require_objects => $pair->[1]) : ()));

    $sql =~ s/\s+/ /g;

    if($last_sql)
    {
      is($sql, $last_sql, "join override no-op $i - $db_type");
    }
    else
    {
      ok($sql, "join override $i - $db_type");
    }

    $last_sql = $sql;
    $i++;
  }

  $i = 1;

  # Override tests

  my $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      with_objects => [ 'vendor.region!' ]);

  cmp_sql($sql, <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t2.region_id,
  t2.vendor_id,
  t2.name,
  t2.id,
  t3.name,
  t3.id
FROM
  products t1 
  LEFT OUTER JOIN (vendors t2  JOIN regions t3 ON (t2.region_id = t3.id)) ON (t1.vendor_id = t2.id)
EOF

  $i++;

  $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      with_objects => [ 'vendor.region' ]);

  cmp_sql($sql, <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t2.region_id,
  t2.vendor_id,
  t2.name,
  t2.id,
  t3.name,
  t3.id
FROM
  products t1 
  LEFT OUTER JOIN vendors t2 ON (t1.vendor_id = t2.id)
  LEFT OUTER JOIN regions t3 ON (t2.region_id = t3.id)
EOF

  $i++;

  $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      multi_many_ok => 1,
      with_objects  => [ 'colors.description.authors.nicknames' ]);

  cmp_sql("$sql\n", <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t3.description_id,
  t3.name,
  t3.id,
  t4.text,
  t4.id,
  t6.name,
  t6.id,
  t7.author_id,
  t7.id,
  t7.nick
FROM
  products t1 
  LEFT OUTER JOIN product_color_map t2 ON (t2.product_id = t1.id)
  LEFT OUTER JOIN colors t3 ON (t2.color_id = t3.id)
  LEFT OUTER JOIN descriptions t4 ON (t3.description_id = t4.id)
  LEFT OUTER JOIN description_author_map t5 ON (t5.description_id = t4.id)
  LEFT OUTER JOIN authors t6 ON (t5.author_id = t6.id)
  LEFT OUTER JOIN nicknames t7 ON (t6.id = t7.author_id)

ORDER BY t1.id
EOF
  #print STDERR "$sql\n";

  $i++;

  $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      multi_many_ok => 1,
      with_objects  => [ 'colors.description!.authors.nicknames!' ]);

  cmp_sql("$sql\n", <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t3.description_id,
  t3.name,
  t3.id,
  t4.text,
  t4.id,
  t6.name,
  t6.id,
  t7.author_id,
  t7.id,
  t7.nick
FROM
  products t1 
  LEFT OUTER JOIN product_color_map t2 ON (t2.product_id = t1.id)
  LEFT OUTER JOIN (colors t3  JOIN descriptions t4 ON (t3.description_id = t4.id)) ON (t2.color_id = t3.id)
  LEFT OUTER JOIN description_author_map t5 ON (t5.description_id = t4.id)
  LEFT OUTER JOIN (authors t6  JOIN nicknames t7 ON (t6.id = t7.author_id)) ON (t5.author_id = t6.id)

ORDER BY t1.id
EOF
  #print STDERR "$sql\n";

  $i++;

  $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      multi_many_ok => 1,
      require_objects  => [ 'colors.description.authors.nicknames' ]);

  if($db->likes_implicit_joins)
  {
    cmp_sql("$sql\n", <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t3.description_id,
  t3.name,
  t3.id,
  t4.text,
  t4.id,
  t6.name,
  t6.id,
  t7.author_id,
  t7.nick,
  t7.id
FROM
  products t1,
  product_color_map t2,
  colors t3,
  descriptions t4,
  description_author_map t5,
  authors t6,
  nicknames t7
WHERE
  t2.product_id = t1.id AND
  t2.color_id = t3.id AND
  t3.description_id = t4.id AND
  t5.description_id = t4.id AND
  t5.author_id = t6.id AND
  t6.id = t7.author_id
ORDER BY t1.id
EOF
  }
  else
  {

    cmp_sql("$sql\n", <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t3.description_id,
  t3.name,
  t3.id,
  t4.text,
  t4.id,
  t6.name,
  t6.id,
  t7.author_id,
  t7.id,
  t7.nick
FROM
  products t1 
  JOIN (product_color_map t2  JOIN (colors t3  JOIN (descriptions t4  JOIN (description_author_map t5  JOIN (authors t6  JOIN nicknames t7 ON (t6.id = t7.author_id)) ON (t5.author_id = t6.id)) ON (t5.description_id = t4.id)) ON (t3.description_id = t4.id)) ON (t2.color_id = t3.id)) ON (t2.product_id = t1.id)
ORDER BY t1.id
EOF
  }
  #print STDERR "$sql\n";

  $i++;

  $sql = 
    $manager_class->get_objects_sql(
      db => $db,
      multi_many_ok => 1,
      require_objects  => [ 'colors.description?.authors.nicknames?' ]);

  cmp_sql("$sql\n", <<"EOF", "join override $i - $db_type");
SELECT 
  t1.vendor_id,
  t1.name,
  t1.id,
  t3.description_id,
  t3.name,
  t3.id,
  t4.text,
  t4.id,
  t6.name,
  t6.id,
  t7.author_id,
  t7.id,
  t7.nick
FROM
  products t1 
  JOIN (product_color_map t2  JOIN colors t3 ON (t2.color_id = t3.id)) ON (t2.product_id = t1.id)
  LEFT OUTER JOIN (descriptions t4  JOIN (description_author_map t5  JOIN authors t6 ON (t5.author_id = t6.id)) ON (t5.description_id = t4.id)) ON (t3.description_id = t4.id)
  LEFT OUTER JOIN nicknames t7 ON (t6.id = t7.author_id)
ORDER BY t1.id
EOF

  #print STDERR "$sql\n";

  # Conflict tests

  $i = 1;

  foreach my $pair ([ [], [ 'vendor.vendor', 'vendor?.region' ] ], 
                    [ [], [ 'vendor?.vendor', 'vendor.region' ] ], 
                    [ [], [ 'vendor?.vendor!', 'vendor!.region' ] ], 
                    [ [ 'vendor?.vendor' ], [ 'vendor.region' ] ],
                    [ [ 'vendor.vendor' ], [ 'vendor!.region' ] ])
  {
    eval 
    {
      $manager_class->get_objects_sql(
        db => $db,
        debug => 1,  
        (@{$pair->[0]} ? (with_objects => $pair->[0]) : ()),
        (@{$pair->[1]} ? (require_objects => $pair->[1]) : ()));
    };

    ok($@, "join override conflict $i - $db_type");

    $i++;
  }

  is(scalar @$products, 2, "require vendors 1 - $db_type");

  is($products->[0]{'vendor'}{'id'}, 2, "p2 - require vendors 1 - $db_type");
  is($products->[0]{'vendor'}{'vendor'}{'id'}, 1, "p2 - require vendors 2 - $db_type");
  is($products->[0]{'vendor'}{'region'}{'name'}, 'America', "p2 - require vendors 3 - $db_type");

  is($products->[1]{'vendor'}{'id'}, 3, "p3 - require vendors 1 - $db_type");
  is($products->[1]{'vendor'}{'vendor'}{'id'}, 2, "p3 - require vendors 2 - $db_type");
  is($products->[1]{'vendor'}{'region'}{'name'}, 'England', "p3 - require vendors 3 - $db_type");

  $products = 
    $manager_class->get_products(
      db => $db,
      require_objects => [ 'vendor.vendor', 'vendor.region' ],
      limit  => 10,
      offset => 1);

  is(scalar @$products, 1, "offset require vendors 1 - $db_type");

  is($products->[0]{'vendor'}{'id'}, 3, "p3 - offset require vendors 1 - $db_type");
  is($products->[0]{'vendor'}{'vendor'}{'id'}, 2, "p3 - offset require vendors 2 - $db_type");
  is($products->[0]{'vendor'}{'region'}{'name'}, 'England', "p3 - offset require vendors 3 - $db_type");

  my $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      require_objects => [ 'vendor.vendor', 'vendor.region' ]);

  my $p = $iterator->next;
  is($p->{'vendor'}{'id'}, 2, "p2 - require vendors iterator 1 - $db_type");
  is($p->{'vendor'}{'vendor'}{'id'}, 1, "p2 - require vendors iterator 2 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'America', "p2 - require vendors iterator 3 - $db_type");

  $p = $iterator->next;
  is($p->{'vendor'}{'id'}, 3, "p3 - require vendors iterator 1 - $db_type");
  is($p->{'vendor'}{'vendor'}{'id'}, 2, "p3 - require vendors iterator 2 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'England', "p3 - require vendors iterator 3 - $db_type");

  ok(!$iterator->next, "require vendors iterator 1 - $db_type");
  is($iterator->total, 2, "require vendors iterator 2 - $db_type");

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      require_objects => [ 'vendor.vendor', 'vendor.region' ],
      limit  => 10,
      offset => 1);

  $p = $iterator->next;
  is($p->{'vendor'}{'id'}, 3, "p3 - offset require vendors iterator 1 - $db_type");
  is($p->{'vendor'}{'vendor'}{'id'}, 2, "p3 - offset require vendors iterator 2 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'England', "p3 - offset require vendors iterator 3 - $db_type");

  ok(!$iterator->next, "offset require vendors iterator 1 - $db_type");
  is($iterator->total, 1, "offset require vendors iterator 2 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $products = 
    $manager_class->get_products(
      db => $db,
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 2,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  is($products->[0]{'colors'}[0]{'name'}, 'red', "p1 - with colors 1 - $db_type");
  is($products->[0]{'colors'}[1]{'name'}, 'blue', "p1 - with colors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}}, 2, "p1 - with colors 3  - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p1 - with colors description 1 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'text'}, 'desc 2', "p1 - with colors description 2 - $db_type");

  if(has_broken_order_by($db_type))
  {
    $products->[0]{'colors'}[0]{'description'}{'authors'} = 
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}} ];
  }

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p1 - with colors description authors 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p1 - with colors description authors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}}, 2, "p1 - with colors description authors 3  - $db_type");

  if(has_broken_order_by($db_type))
  {
    $products->[0]{'colors'}[1]{'description'}{'authors'} = 
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$products->[0]{'colors'}[1]{'description'}{'authors'}} ];
  }

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'jane', "p1 - with colors description authors 4 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'name'}, 'john', "p1 - with colors description authors 5 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}}, 2, "p1 - with colors description authors 6  - $db_type");

  $products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p1 - with colors description authors nicknames 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p1 - with colors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p1 - with colors description authors nicknames 3 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p1 - with colors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p1 - with colors description authors nicknames 5 - $db_type");

  $products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}} ];

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'jack', "p1 - with colors description authors nicknames 6 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[1]{'nick'}, 'sir', "p1 - with colors description authors nicknames 7 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}}, 2, "p1 - with colors description authors nicknames 8 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'blub', "p1 - with colors description authors nicknames 9 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}}, 1, "p1 - with colors description authors nicknames 10  - $db_type");

  is($products->[1]{'colors'}[0]{'name'}, 'red', "p2 - with colors 1 - $db_type");
  is($products->[1]{'colors'}[1]{'name'}, 'green', "p2 - with colors 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}}, 2, "p2 - with colors 3  - $db_type");

  is($products->[1]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - with colors description 1 - $db_type");
  is($products->[1]{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - with colors description 2 - $db_type");

  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - with colors description authors 1 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - with colors description authors 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - with colors description authors 3  - $db_type");

  is($products->[1]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - with colors description authors 4 - $db_type");
  is(scalar @{$products->[1]{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - with colors description authors 6  - $db_type");

  $products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - with colors description authors nicknames 1 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - with colors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - with colors description authors nicknames 3 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - with colors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - with colors description authors nicknames 5 - $db_type");

  is(scalar @{$products->[1]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - with colors description authors nicknames 6 - $db_type");

  $products = 
    $manager_class->get_products(
      db => $db,
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 1,
      offset          => 1,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  is($products->[0]{'colors'}[0]{'name'}, 'red', "p2 - offset with colors 1 - $db_type");
  is($products->[0]{'colors'}[1]{'name'}, 'green', "p2 - offset with colors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}}, 2, "p2 - offset with colors 3  - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - offset with colors description 1 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - offset with colors description 2 - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - offset with colors description authors 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - offset with colors description authors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - offset with colors description authors 3  - $db_type");

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - offset with colors description authors 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - offset with colors description authors 6  - $db_type");

  $products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - offset with colors description authors nicknames 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - offset with colors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - offset with colors description authors nicknames 3 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - offset with colors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - offset with colors description authors nicknames 5 - $db_type");

  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - offset with colors description authors nicknames 6 - $db_type");

  $products = 
    $manager_class->get_products(
      db => $db,
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 1,
      offset          => 1,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  Rose::DB::Object::Helpers::strip($products->[0], leave => [ 'related_objects' ]);
  Rose::DB::Object::Helpers::strip($products->[0], leave => 'foreign_keys');
  Rose::DB::Object::Helpers::strip($products->[0], leave => [ 'relationships' ]);
  Rose::DB::Object::Helpers::strip($products->[0]);

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 2,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  $p = $iterator->next;
  is($p->{'colors'}[0]{'name'}, 'red', "p1 - iterator with colors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'blue', "p1 - iterator with colors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p1 - iterator with colors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p1 - iterator with colors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 2', "p1 - iterator with colors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p1 - iterator with colors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p1 - iterator with colors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p1 - iterator with colors description authors 3  - $db_type");

  if(has_broken_order_by($db_type))
  {
    $p->{'colors'}[1]{'description'}{'authors'} = 
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$p->{'colors'}[1]{'description'}{'authors'}} ];
  }

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'jane', "p1 - iterator with colors description authors 4 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'name'}, 'john', "p1 - iterator with colors description authors 5 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 2, "p1 - iterator with colors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p1 - iterator with colors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p1 - iterator with colors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p1 - iterator with colors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p1 - iterator with colors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p1 - iterator with colors description authors nicknames 5 - $db_type");

  $p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}} ];

  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'jack', "p1 - iterator with colors description authors nicknames 6 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[1]{'nick'}, 'sir', "p1 - iterator with colors description authors nicknames 7 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}}, 2, "p1 - iterator with colors description authors nicknames 8 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'blub', "p1 - iterator with colors description authors nicknames 9 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}}, 1, "p1 - iterator with colors description authors nicknames 10  - $db_type");

  $p = $iterator->next;
  is($p->{'colors'}[0]{'name'}, 'red', "p2 - iterator with colors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'green', "p2 - iterator with colors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p2 - iterator with colors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - iterator with colors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - iterator with colors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - iterator with colors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - iterator with colors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - iterator with colors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - iterator with colors description authors 4 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - iterator with colors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - iterator with colors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - iterator with colors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - iterator with colors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - iterator with colors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - iterator with colors description authors nicknames 5 - $db_type");

  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - iterator with colors description authors nicknames 6 - $db_type");

  ok(!$iterator->next, "iterator with colors description authors nicknames 1 - $db_type");
  is($iterator->total, 2, "iterator with colors description authors nicknames 2 - $db_type");

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 1,
      offset          => 1,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  $p = $iterator->next;
  is($p->{'colors'}[0]{'name'}, 'red', "p2 - offset iterator with colors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'green', "p2 - offset iterator with colors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p2 - offset iterator with colors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - offset iterator with colors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - offset iterator with colors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - offset iterator with colors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - offset iterator with colors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - offset iterator with colors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - offset iterator with colors description authors 4 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - offset iterator with colors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - offset iterator with colors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - offset iterator with colors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - offset iterator with colors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - offset iterator with colors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - offset iterator with colors description authors nicknames 5 - $db_type");

  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - offset iterator with colors description authors nicknames 6 - $db_type");

  ok(!$iterator->next, "offset iterator with colors description authors nicknames 1 - $db_type");
  is($iterator->total, 1, "offset iterator with colors description authors nicknames 2 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $products = 
    $manager_class->get_products(
      db => $db,
      require_objects => [ 'vendor.region', 'prices.region' ],
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 2,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  #exit;

  is($products->[0]{'vendor'}{'name'}, 'V1', "p1 - vendor 1 - $db_type");
  is($products->[0]{'vendor'}{'region'}{'name'}, 'Germany', "p1 - vendor 2 - $db_type");

  is($products->[1]{'vendor'}{'name'}, 'V2', "p2 - vendor 1 - $db_type");
  is($products->[1]{'vendor'}{'region'}{'name'}, 'America', "p2 - vendor 2 - $db_type");

  is(scalar @{$products->[0]{'prices'}}, 2, "p1 - prices 1 - $db_type");
  is(scalar @{$products->[1]{'prices'}}, 1, "p2 - prices 2 - $db_type");

  $products->[0]{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$products->[0]{'prices'}} ];
  $products->[1]{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$products->[1]{'prices'}} ];

  is($products->[0]{'prices'}[0]{'price'}, 1.25, "p1 - prices 2 - $db_type");
  is($products->[0]{'prices'}[0]{'region'}{'name'}, 'America', "p1 - prices 3 - $db_type");
  is($products->[0]{'prices'}[1]{'price'}, 4.25, "p1 - prices 4 - $db_type");
  is($products->[0]{'prices'}[1]{'region'}{'name'}, 'Germany', "p1 - prices 5 - $db_type");

  is($products->[1]{'prices'}[0]{'price'}, 9.25, "p2 - prices 2 - $db_type");
  is($products->[1]{'prices'}[0]{'region'}{'name'}, 'America', "p2 - prices 3 - $db_type");

  if(has_broken_order_by($db_type))
  {
    $products->[0]{'colors'} = 
      [ sort { $b->{'name'} cmp $a->{'name'} } @{$products->[0]{'colors'}} ];

    $products->[0]{'colors'}[0]{'description'}{'authors'} =
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}} ];

    $products->[0]{'colors'}[1]{'description'}{'authors'} =
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$products->[0]{'colors'}[1]{'description'}{'authors'}} ];
  }

  is($products->[0]{'colors'}[0]{'name'}, 'red', "p1 - with colors vendors 1 - $db_type");
  is($products->[0]{'colors'}[1]{'name'}, 'blue', "p1 - with colors vendors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}}, 2, "p1 - with colors vendors 3  - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p1 - with colors vendors description 1 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'text'}, 'desc 2', "p1 - with colors vendors description 2 - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p1 - with colors vendors description authors 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p1 - with colors vendors description authors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}}, 2, "p1 - with colors vendors description authors 3  - $db_type");

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'jane', "p1 - with colors vendors description authors 4 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'name'}, 'john', "p1 - with colors vendors description authors 5 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}}, 2, "p1 - with colors vendors description authors 6  - $db_type");

  $products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'sir', "p1 - with colors vendors description authors nicknames 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'jack', "p1 - with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p1 - with colors vendors description authors nicknames 3 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p1 - with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p1 - with colors vendors description authors nicknames 5 - $db_type");

  $products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} = 
    [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}} ];

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sir', "p1 - with colors vendors description authors nicknames 6 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[1]{'nick'}, 'jack', "p1 - with colors vendors description authors nicknames 7 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}}, 2, "p1 - with colors vendors description authors nicknames 8 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'blub', "p1 - with colors vendors description authors nicknames 9 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}}, 1, "p1 - with colors vendors description authors nicknames 10  - $db_type");

  is($products->[1]{'colors'}[0]{'name'}, 'red', "p2 - with colors vendors 1 - $db_type");
  is($products->[1]{'colors'}[1]{'name'}, 'green', "p2 - with colors vendors 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}}, 2, "p2 - with colors vendors 3  - $db_type");

  is($products->[1]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - with colors vendors description 1 - $db_type");
  is($products->[1]{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - with colors vendors description 2 - $db_type");

  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - with colors vendors description authors 1 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - with colors vendors description authors 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - with colors vendors description authors 3  - $db_type");

  is($products->[1]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - with colors vendors description authors 4 - $db_type");
  is(scalar @{$products->[1]{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - with colors vendors description authors 6  - $db_type");

  $products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} =
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - with colors vendors description authors nicknames 1 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - with colors vendors description authors nicknames 3 - $db_type");
  is($products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[1]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - with colors vendors description authors nicknames 5 - $db_type");

  is(scalar @{$products->[1]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - with colors vendors description authors nicknames 6 - $db_type");

  $products = 
    $manager_class->get_products(
      db => $db,
      require_objects => [ 'vendor.region', 'prices.region' ],
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 1,
      offset          => 1,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  is($products->[0]{'vendor'}{'name'}, 'V2', "p2 - offset vendor 1 - $db_type");
  is($products->[0]{'vendor'}{'region'}{'name'}, 'America', "p2 - offset vendor 2 - $db_type");

  is(scalar @{$products->[0]{'prices'}}, 1, "p1 - offset prices 1 - $db_type");

  $products->[0]{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$products->[0]{'prices'}} ];

  is($products->[0]{'prices'}[0]{'price'}, 9.25, "p2 - offset prices 2 - $db_type");
  is($products->[0]{'prices'}[0]{'region'}{'name'}, 'America', "p2 - offset prices 3 - $db_type");

  is($products->[0]{'colors'}[0]{'name'}, 'red', "p2 - offset with colors vendors 1 - $db_type");
  is($products->[0]{'colors'}[1]{'name'}, 'green', "p2 - offset with colors vendors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}}, 2, "p2 - offset with colors vendors 3  - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - offset with colors vendors description 1 - $db_type");
  is($products->[0]{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - offset with colors vendors description 2 - $db_type");

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - offset with colors vendors description authors 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - offset with colors vendors description authors 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - offset with colors vendors description authors 3  - $db_type");

  is($products->[0]{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - offset with colors vendors description authors 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - offset with colors vendors description authors 6  - $db_type");

  $products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} =
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - offset with colors vendors description authors nicknames 1 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - offset with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - offset with colors vendors description authors nicknames 3 - $db_type");
  is($products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - offset with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$products->[0]{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - offset with colors vendors description authors nicknames 5 - $db_type");

  is(scalar @{$products->[0]{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - offset with colors vendors description authors nicknames 6 - $db_type");

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      require_objects => [ 'vendor.region', 'prices.region' ],
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 2,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  $p = $iterator->next;
  is($p->{'vendor'}{'name'}, 'V1', "p1 - iterator vendor 1 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'Germany', "p1 - iterator vendor 2 - $db_type");

  is(scalar @{$p->{'prices'}}, 2, "p1 - iterator prices 1 - $db_type");

  $p->{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$p->{'prices'}} ];

  is($p->{'prices'}[0]{'price'}, 1.25, "p1 - iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'region'}{'name'}, 'America', "p1 - iterator prices 3 - $db_type");
  is($p->{'prices'}[1]{'price'}, 4.25, "p1 - iterator prices 4 - $db_type");
  is($p->{'prices'}[1]{'region'}{'name'}, 'Germany', "p1 - iterator prices 5 - $db_type");

  is($p->{'colors'}[0]{'name'}, 'red', "p1 - iterator with colors vendors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'blue', "p1 - iterator with colors vendors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p1 - iterator with colors vendors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p1 - iterator with colors vendors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 2', "p1 - iterator with colors vendors description 2 - $db_type");

  if(has_broken_order_by($db_type))
  {
    $p->{'colors'}[0]{'description'}{'authors'} = 
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$p->{'colors'}[0]{'description'}{'authors'}} ];

    $p->{'colors'}[1]{'description'}{'authors'} =
      [ sort { $a->{'name'} cmp $b->{'name'} } @{$p->{'colors'}[1]{'description'}{'authors'}} ];
  }

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p1 - iterator with colors vendors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p1 - iterator with colors vendors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p1 - iterator with colors vendors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'jane', "p1 - iterator with colors vendors description authors 4 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'name'}, 'john', "p1 - iterator with colors vendors description authors 5 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 2, "p1 - iterator with colors vendors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  $p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} = 
    [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'sir', "p1 - iterator with colors vendors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'jack', "p1 - iterator with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p1 - iterator with colors vendors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p1 - iterator with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p1 - iterator with colors vendors description authors nicknames 5 - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sir', "p1 - iterator with colors vendors description authors nicknames 6 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}[1]{'nick'}, 'jack', "p1 - iterator with colors vendors description authors nicknames 7 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'}}, 2, "p1 - iterator with colors vendors description authors nicknames 8 - $db_type");
  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'blub', "p1 - iterator with colors vendors description authors nicknames 9 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[0]{'nicknames'}}, 1, "p1 - iterator with colors vendors description authors nicknames 10  - $db_type");

  $p = $iterator->next;
  is($p->{'vendor'}{'name'}, 'V2', "p2 - iterator vendor 1 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'America', "p2 - iterator vendor 2 - $db_type");

  $p->{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$p->{'prices'}} ];

  is(scalar @{$p->{'prices'}}, 1, "p2 - iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'price'}, 9.25, "p2 - iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'region'}{'name'}, 'America', "p2 - iterator prices 3 - $db_type");

  is($p->{'colors'}[0]{'name'}, 'red', "p2 - iterator with colors vendors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'green', "p2 - iterator with colors vendors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p2 - iterator with colors vendors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - iterator with colors vendors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - iterator with colors vendors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - iterator with colors vendors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - iterator with colors vendors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - iterator with colors vendors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - iterator with colors vendors description authors 4 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - iterator with colors vendors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - iterator with colors vendors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - iterator with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - iterator with colors vendors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - iterator with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - iterator with colors vendors description authors nicknames 5 - $db_type");

  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - iterator with colors vendors description authors nicknames 6 - $db_type");

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      require_objects => [ 'vendor.region', 'prices.region' ],
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      limit           => 1,
      offset          => 1,
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  $p = $iterator->next;
  is($p->{'vendor'}{'name'}, 'V2', "p2 - offset iterator vendor 1 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'America', "p2 - offset iterator vendor 2 - $db_type");

  $p->{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$p->{'prices'}} ];

  is(scalar @{$p->{'prices'}}, 1, "p2 - offset iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'price'}, 9.25, "p2 - offset iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'region'}{'name'}, 'America', "p2 - offset iterator prices 3 - $db_type");

  is($p->{'colors'}[0]{'name'}, 'red', "p2 - offset iterator with colors vendors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'green', "p2 - offset iterator with colors vendors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p2 - offset iterator with colors vendors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - offset iterator with colors vendors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - offset iterator with colors vendors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - offset iterator with colors vendors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - offset iterator with colors vendors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - offset iterator with colors vendors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - offset iterator with colors vendors description authors 4 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - offset iterator with colors vendors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} = 
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - offset iterator with colors vendors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - offset iterator with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - offset iterator with colors vendors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - offset iterator with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - offset iterator with colors vendors description authors nicknames 5 - $db_type");

  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - offset iterator with colors vendors description authors nicknames 6 - $db_type");

  ok(!$iterator->next, "offset iterator with colors vendors description authors nicknames 1 - $db_type");
  is($iterator->total, 1, "offset iterator with colors vendors description authors nicknames 2 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $iterator = 
    $manager_class->get_products_iterator(
      db => $db,
      require_objects => [ 'vendor.region', 'prices.region' ],
      with_objects    => [ 'colors.description.authors.nicknames' ],
      multi_many_ok   => 1,
      query           => [ 'vendor.region.name' => 'America' ],
      sort_by => [ 'colors.name DESC', 'authors.name' ]);

  $p = $iterator->next;
  is($p->{'vendor'}{'name'}, 'V2', "p2 - query iterator vendor 1 - $db_type");
  is($p->{'vendor'}{'region'}{'name'}, 'America', "p2 - query iterator vendor 2 - $db_type");

  $p->{'prices'} = [ sort { $a->{'price'} <=> $b->{'price'} } @{$p->{'prices'}} ];

  is(scalar @{$p->{'prices'}}, 1, "p2 - query iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'price'}, 9.25, "p2 - query iterator prices 2 - $db_type");
  is($p->{'prices'}[0]{'region'}{'name'}, 'America', "p2 - query iterator prices 3 - $db_type");

  is($p->{'colors'}[0]{'name'}, 'red', "p2 - query iterator with colors vendors 1 - $db_type");
  is($p->{'colors'}[1]{'name'}, 'green', "p2 - query iterator with colors vendors 2 - $db_type");
  is(scalar @{$p->{'colors'}}, 2, "p2 - query iterator with colors vendors 3  - $db_type");

  is($p->{'colors'}[0]{'description'}{'text'}, 'desc 1', "p2 - query iterator with colors vendors description 1 - $db_type");
  is($p->{'colors'}[1]{'description'}{'text'}, 'desc 3', "p2 - query iterator with colors vendors description 2 - $db_type");

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'name'}, 'john', "p2 - query iterator with colors vendors description authors 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'name'}, 'sue', "p2 - query iterator with colors vendors description authors 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}}, 2, "p2 - query iterator with colors vendors description authors 3  - $db_type");

  is($p->{'colors'}[1]{'description'}{'authors'}[0]{'name'}, 'tim', "p2 - query iterator with colors vendors description authors 4 - $db_type");
  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}}, 1, "p2 - query iterator with colors vendors description authors 6  - $db_type");

  $p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'} =
    [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}} ];

  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[0]{'nick'}, 'jack', "p2 - query iterator with colors vendors description authors nicknames 1 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}[1]{'nick'}, 'sir', "p2 - query iterator with colors vendors description authors nicknames 2 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[0]{'nicknames'}}, 2, "p2 - query iterator with colors vendors description authors nicknames 3 - $db_type");
  is($p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}[0]{'nick'}, 'sioux', "p2 - query iterator with colors vendors description authors nicknames 4 - $db_type");
  is(scalar @{$p->{'colors'}[0]{'description'}{'authors'}[1]{'nicknames'}}, 1, "p2 - query iterator with colors vendors description authors nicknames 5 - $db_type");

  is(scalar @{$p->{'colors'}[1]{'description'}{'authors'}[1]{'nicknames'} || []}, 0, "p2 - query iterator with colors vendors description authors nicknames 6 - $db_type");

  ok(!$iterator->next, "query iterator with colors vendors description authors nicknames 1 - $db_type");
  is($iterator->total, 1, "query iterator with colors vendors description authors nicknames 2 - $db_type");

  # End test of the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(0);
}

BEGIN
{
  our %Have;

  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    #die "This test chokes DBD::Pg version 2.1.x and 2.2.0"  if($DBD::Pg::VERSION =~ /^2\.(?:1\.|2\.0)/);
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE description_author_map CASCADE');
      $dbh->do('DROP TABLE nicknames CASCADE');
      $dbh->do('DROP TABLE authors CASCADE');
      $dbh->do('DROP TABLE descriptions CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');
      $dbh->do('DROP TABLE regions CASCADE');

      $dbh->do('DROP TABLE Rose_db_object_private.product_color_map CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.colors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.description_author_map CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.nicknames CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.authors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.descriptions CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.prices CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.products CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.vendors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.regions CASCADE');

      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE regions
(
  id    CHAR(2) NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  vendor_id INT REFERENCES vendors (id),
  region_id CHAR(2) REFERENCES regions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,

  vendor_id  INT REFERENCES vendors (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region_id   CHAR(2) NOT NULL REFERENCES regions (id) DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE descriptions
(
  id    SERIAL NOT NULL PRIMARY KEY,
  text  VARCHAR(255) NOT NULL,

  UNIQUE(text)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE authors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE nicknames
(
  id         SERIAL NOT NULL PRIMARY KEY,
  nick       VARCHAR(255) NOT NULL,
  author_id  INT REFERENCES authors (id),

  UNIQUE(nick, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE description_author_map
(
  description_id  INT NOT NULL REFERENCES descriptions (id),
  author_id       INT NOT NULL REFERENCES authors (id),

  PRIMARY KEY(description_id, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  description_id INT REFERENCES descriptions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.regions
(
  id    CHAR(2) NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  vendor_id INT REFERENCES Rose_db_object_private.vendors (id),
  region_id CHAR(2) REFERENCES Rose_db_object_private.regions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,

  vendor_id  INT REFERENCES Rose_db_object_private.vendors (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES Rose_db_object_private.products (id),
  region_id   CHAR(2) NOT NULL REFERENCES Rose_db_object_private.regions (id) DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.descriptions
(
  id    SERIAL NOT NULL PRIMARY KEY,
  text  VARCHAR(255) NOT NULL,

  UNIQUE(text)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.authors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.nicknames
(
  id         SERIAL NOT NULL PRIMARY KEY,
  nick       VARCHAR(255) NOT NULL,
  author_id  INT REFERENCES Rose_db_object_private.authors (id),

  UNIQUE(nick, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.description_author_map
(
  description_id  INT NOT NULL REFERENCES Rose_db_object_private.descriptions (id),
  author_id       INT NOT NULL REFERENCES Rose_db_object_private.authors (id),

  PRIMARY KEY(description_id, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.colors
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  description_id INT REFERENCES Rose_db_object_private.descriptions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.product_color_map
(
  product_id  INT NOT NULL REFERENCES Rose_db_object_private.products (id),
  color_id    INT NOT NULL REFERENCES Rose_db_object_private.colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    die "MySQL version too old"  unless($db->database_version >= 4_000_000);

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE descriptions CASCADE');
      $dbh->do('DROP TABLE authors CASCADE');
      $dbh->do('DROP TABLE nicknames CASCADE');
      $dbh->do('DROP TABLE description_author_map CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');
      $dbh->do('DROP TABLE regions CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE regions
(
  id    CHAR(2) NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    # MySQL will silently ignore the "ENGINE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('regions');
    my $info = $sth->fetchrow_hashref;

    no warnings 'uninitialized';
    unless(lc $info->{'Type'} eq 'innodb' || lc $info->{'Engine'} eq 'innodb')
    {
      die "Missing InnoDB support";
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  vendor_id INT,
  region_id CHAR(2),

  INDEX(vendor_id),
  INDEX(region_id),

  FOREIGN KEY (vendor_id) REFERENCES vendors (id),
  FOREIGN KEY (region_id) REFERENCES regions (id),

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,

  vendor_id  INT,

  INDEX(vendor_id),

  FOREIGN KEY (vendor_id) REFERENCES vendors (id),

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          INT AUTO_INCREMENT PRIMARY KEY,
  product_id  INT,
  region_id   CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  INDEX(product_id),
  INDEX(region_id),

  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (region_id) REFERENCES regions (id),

  UNIQUE(product_id, region_id)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE descriptions
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  text  VARCHAR(255) NOT NULL,

  UNIQUE(text)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE authors
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE nicknames
(
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nick       VARCHAR(255) NOT NULL,
  author_id  INT,

  INDEX(author_id),

  FOREIGN KEY (author_id) REFERENCES authors (id),

  UNIQUE(nick, author_id)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE description_author_map
(
  description_id  INT NOT NULL,
  author_id       INT NOT NULL,

  INDEX(description_id),
  INDEX(author_id),

  FOREIGN KEY (description_id) REFERENCES descriptions (id),
  FOREIGN KEY (author_id) REFERENCES authors (id),

  PRIMARY KEY(description_id, author_id)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  description_id INT,

  INDEX(description_id),

  FOREIGN KEY (description_id) REFERENCES descriptions (id),

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL,
  color_id    INT NOT NULL,

  INDEX(product_id),
  INDEX(color_id),

  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (color_id) REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
ENGINE=InnoDB
EOF

    $dbh->disconnect;
  }

  #
  # Informix
  #

  eval 
  {
    $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'informix'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE description_author_map CASCADE');
      $dbh->do('DROP TABLE nicknames CASCADE');
      $dbh->do('DROP TABLE authors CASCADE');
      $dbh->do('DROP TABLE descriptions CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');
      $dbh->do('DROP TABLE regions CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE regions
(
  id    CHAR(2) NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  vendor_id INT REFERENCES vendors (id),
  region_id CHAR(2) REFERENCES regions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,

  vendor_id  INT REFERENCES vendors (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region_id   CHAR(2) DEFAULT 'US' NOT NULL REFERENCES regions (id),
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE descriptions
(
  id    SERIAL NOT NULL PRIMARY KEY,
  text  VARCHAR(255) NOT NULL,

  UNIQUE(text)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE authors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE nicknames
(
  id         SERIAL NOT NULL PRIMARY KEY,
  nick       VARCHAR(255) NOT NULL,
  author_id  INT REFERENCES authors (id),

  UNIQUE(nick, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE description_author_map
(
  description_id  INT NOT NULL REFERENCES descriptions (id),
  author_id       INT NOT NULL REFERENCES authors (id),

  PRIMARY KEY(description_id, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  description_id INT REFERENCES descriptions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->disconnect;
  }

  #
  # SQLite
  #

  eval
  {
    $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'sqlite'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE colors');
      $dbh->do('DROP TABLE descriptions');
      $dbh->do('DROP TABLE authors');
      $dbh->do('DROP TABLE nicknames');
      $dbh->do('DROP TABLE description_author_map');
      $dbh->do('DROP TABLE product_color_map');
      $dbh->do('DROP TABLE prices');
      $dbh->do('DROP TABLE products');
      $dbh->do('DROP TABLE vendors');
      $dbh->do('DROP TABLE regions');
    }

    $dbh->do(<<"EOF");
CREATE TABLE regions
(
  id    CHAR(2) NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  vendor_id INT REFERENCES vendors (id),
  region_id CHAR(2) REFERENCES regions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    VARCHAR(255) NOT NULL,

  vendor_id  INT REFERENCES vendors (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INT NOT NULL REFERENCES products (id),
  region_id   CHAR(2) NOT NULL REFERENCES regions (id) DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE descriptions
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  text  VARCHAR(255) NOT NULL,

  UNIQUE(text)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE authors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE nicknames
(
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  nick       VARCHAR(255) NOT NULL,
  author_id  INT REFERENCES authors (id),

  UNIQUE(nick, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE description_author_map
(
  description_id  INT NOT NULL REFERENCES descriptions (id),
  author_id       INT NOT NULL REFERENCES authors (id),

  PRIMARY KEY(description_id, author_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    VARCHAR(255) NOT NULL,
  description_id INT REFERENCES descriptions (id),

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  if($Have{'pg'})
  {
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE description_author_map CASCADE');
    $dbh->do('DROP TABLE nicknames CASCADE');
    $dbh->do('DROP TABLE authors CASCADE');
    $dbh->do('DROP TABLE descriptions CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');
    $dbh->do('DROP TABLE regions CASCADE');

    $dbh->do('DROP TABLE Rose_db_object_private.product_color_map CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.colors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.description_author_map CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.nicknames CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.authors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.descriptions CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.prices CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.products CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.vendors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.regions CASCADE');

    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE description_author_map CASCADE');
    $dbh->do('DROP TABLE nicknames CASCADE');
    $dbh->do('DROP TABLE authors CASCADE');
    $dbh->do('DROP TABLE descriptions CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');
    $dbh->do('DROP TABLE regions CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE description_author_map CASCADE');
    $dbh->do('DROP TABLE nicknames CASCADE');
    $dbh->do('DROP TABLE authors CASCADE');
    $dbh->do('DROP TABLE descriptions CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');
    $dbh->do('DROP TABLE regions CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE colors');
    $dbh->do('DROP TABLE descriptions');
    $dbh->do('DROP TABLE authors');
    $dbh->do('DROP TABLE nicknames');
    $dbh->do('DROP TABLE description_author_map');
    $dbh->do('DROP TABLE product_color_map');
    $dbh->do('DROP TABLE prices');
    $dbh->do('DROP TABLE products');
    $dbh->do('DROP TABLE vendors');
    $dbh->do('DROP TABLE regions');

    $dbh->disconnect;
  }
}

sub has_broken_order_by
{
  my($db_type) = shift;

  no warnings 'uninitialized';
  (my $version = $DBD::SQLite::VERSION) =~ s/_//g;

  if($db_type eq 'sqlite' && $version < 1.11)
  {
    return 1;
  }

  return 0;
}

sub cmp_sql
{
  my($a, $b, $msg) = @_;

  for($a, $b)
  {
    s/\s+/ /g;
    s/^\s+//;
    s/\s+$//;
    s/^SELECT.*?FROM/SELECT * FROM/;
    s/\brose_db_object_private\.//g;
  }

  @_ = ($a, $b, $msg);

  goto &is;
}
