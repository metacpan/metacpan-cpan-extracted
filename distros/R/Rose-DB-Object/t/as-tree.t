#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (5 * 28) + 4;

eval { require Test::Differences };

my $Have_Test_Differences = $@ ? 0 : 1;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
  use_ok('Rose::DB::Object::Helpers');
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

our(%Have, $Have_YAML, $Have_JSON);

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
    skip("$db_type tests", 28)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  if($Have_Test_Differences)
  {
    # Test::Differences is sensitive to string/number distinctions that 
    # SQLite and Pg exhibit and that I don't care about.
    if($db_type eq 'sqlite' || $db_type =~ /^pg/)
    {
      no warnings;
      *is_deeply = \&Test::More::is_deeply;
    }
    else
    {
      no warnings;
      *is_deeply = \&Test::Differences::eq_or_diff;
    }
  }

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

  foreach my $class (@classes)
  {
    next  unless($class->isa('Rose::DB::Object'));

    if(my @rels = grep { !$_->is_singular } $class->meta->relationships)
    {
      foreach my $rel (@rels)
      {
        if($rel->type eq 'many to many')
        {
          $rel->manager_args({ sort_by => 't2.id' });
        }
        else
        {
          $rel->manager_args({ sort_by => 'id' });
        }
      }

      $class->meta->make_relationship_methods(replace_existing => 1);
    }
  }

  my $product_class = $class_prefix  . '::Product';
  my $manager_class = $product_class . '::Manager';

  Rose::DB::Object::Helpers->import(-target_class => $product_class, 
    qw(as_tree new_from_tree new_from_deflated_tree init_with_tree traverse_depth_first));

  if($Have_JSON)
  {
    Rose::DB::Object::Helpers->import(-target_class => $product_class, qw(as_json new_from_json init_with_json));
  }

  if($Have_YAML)
  {
    Rose::DB::Object::Helpers->import(-target_class => $product_class, qw(as_yaml new_from_yaml init_with_yaml));
  }  

  my $p1 = 
    $product_class->new(
      id     => 1,
      name   => 'Kite',
      sale_date => '1/2/2005',
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
      sale_date => '2/2/2005',
      vendor => { id => 2, name => 'V2', region_id => 'US', vendor_id => 1 },
      prices => [ { price => '5.25' } ],
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

  my $tree      = $p2->as_tree;
  my $from_tree = $product_class->new_from_deflated_tree($tree);

  is_deeply($tree, $from_tree->as_tree, "as_tree -> new_from_deflated_tree -> as_tree 1 - $db_type");
  is_deeply($tree, $from_tree->as_tree, "as_tree -> new_from_deflated_tree -> as_tree 2 - $db_type");

  $tree = $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 0);

  my $check_tree =
  {
    'id'        => '2',
    'name'      => 'Sled',
    'vendor_id' => '2',
    'sale_date' => '2005-02-02 00:00:00',
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 0 - $db_type");

  my $new_from_deflated_tree = $product_class->new_from_deflated_tree($tree);  
  is_deeply($new_from_deflated_tree->as_tree, $check_tree, "new_from_deflated_tree 1 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 0);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree, "new_from_json 1 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 0);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree, "new_from_yaml 1 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  $tree = $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 1);

  $check_tree = 
  {
    'colors' => 
    [
      {
        'description_id' => '1',
        'id'             => '1',
        'name'           => 'red'
      },
      {
        'description_id' => '3',
        'id'             => '3',
        'name'           => 'green'
      }
    ],
    'id'     => '2',
    'name'   => 'Sled',
    'prices' => 
    [
      {
        'id'         => '3',
        'price'      => '5.25',
        'product_id' => '2',
        'region_id'  => 'US'
      }
    ],
    'sale_date' => '2005-02-02 00:00:00',
    'vendor' => 
    {
      'id'        => '2',
      'name'      => 'V2',
      'region_id' => 'US',
      'vendor_id' => '1'
    },
    'vendor_id' => '2'
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 1 - $db_type");

  $new_from_deflated_tree = $product_class->new_from_deflated_tree($tree);  
  is_deeply($new_from_deflated_tree->as_tree, $check_tree, "new_from_deflated_tree 2 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 1);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree, "new_from_json 2 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 1);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree, "new_from_yaml 2 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  $tree = $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 2);

  $check_tree =
  {
    'colors' => 
    [
      {
        'description' => 
        {
          'id'   => '1',
          'text' => 'desc 1'
        },
        'description_id' => '1',
        'id'             => '1',
        'name'           => 'red'
      },
      {
        'description' => 
        {
          'id'   => '3',
          'text' => 'desc 3'
        },
        'description_id' => '3',
        'id'             => '3',
        'name'           => 'green'
      }
    ],
    'id'     => '2',
    'name'   => 'Sled',
    'prices' => 
    [
      {
        'id'         => '3',
        'price'      => '5.25',
        'product_id' => '2',
        'region'     => 
        {
          'id'   => 'US',
          'name' => 'America'
        },
        'region_id' => 'US'
      }
    ],
    'sale_date' => '2005-02-02 00:00:00',
    'vendor' => 
    {
      'id'        => '2',
      'name'      => 'V2',
      'region_id' => 'US',
      'vendor'    => 
      {
        'id'        => '1',
        'name'      => 'V1',
        'region_id' => 'DE',
        'vendor_id' => undef
      },
      'vendor_id' => '1',
      'vendors'   => []
    },
    'vendor_id' => '2'
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 2 - $db_type");

  my $new_from_tree = $product_class->new_from_deflated_tree($tree);  
  is_deeply($new_from_tree->as_tree, $check_tree, "new_from_tree 3 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 2);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree, "new_from_json 3 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 2);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree, "new_from_yaml 3 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  $tree = $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 2, allow_loops => 1);

  #$product_class->new(id => 2)->traverse_depth_first(
  #  force_load => 1, handlers => 
  #  {
  #    object => sub { print '  ' x $_[4], ref($_[0]), ': ' . $_[0]->id, "\n" } 
  #  });

  $check_tree =
  {
    'colors' => 
    [
      {
        'description' => 
        {
          'id'   => '1',
          'text' => 'desc 1'
        },
        'description_id' => '1',
        'id'             => '1',
        'name'           => 'red',
        'products'       => 
        [
          {
            'id'        => '1',
            'name'      => 'Kite',
            'sale_date' => '2005-01-02 00:00:00',
            'vendor_id' => '1'
          },
          {
            'id'        => '2',
            'name'      => 'Sled',
            'sale_date' => '2005-02-02 00:00:00',
            'vendor_id' => '2'
          }
        ]
      },
      {
        'description' => 
        {
          'id'   => '3',
          'text' => 'desc 3'
        },
        'description_id' => '3',
        'id'             => '3',
        'name'           => 'green',
        'products'       => 
        [
          {
            'id'        => '2',
            'name'      => 'Sled',
            'sale_date' => '2005-02-02 00:00:00',
            'vendor_id' => '2'
          }
        ]
      }
    ],
    'id'     => '2',
    'name'   => 'Sled',
    'prices' => 
    [
      {
        'id'      => '3',
        'price'   => '5.25',
        'product' => 
        {
          'id'        => '2',
          'name'      => 'Sled',
          'sale_date' => '2005-02-02 00:00:00',
          'vendor_id' => '2'
        },
        'product_id' => '2',
        'region'     => 
        {
          'id'   => 'US',
          'name' => 'America'
        },
        'region_id' => 'US'
      }
    ],
    'sale_date' => '2005-02-02 00:00:00',
    'vendor' => 
    {
      'id'       => '2',
      'name'     => 'V2',
      'products' => 
      [
        {
          'id'        => '2',
          'name'      => 'Sled',
          'sale_date' => '2005-02-02 00:00:00',
          'vendor_id' => '2'
        }
      ],
      'region' => 
      {
        'id'   => 'US',
        'name' => 'America'
      },
      'region_id' => 'US',
      'vendor'    => 
      {
        'id'        => '1',
        'name'      => 'V1',
        'region_id' => 'DE',
        'vendor_id' => undef
      },
      'vendor_id' => '1',
      'vendors'   => []
    },
    'vendor_id' => '2'
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 2, allow_loops => 1 - $db_type");

  $new_from_tree = $product_class->new_from_tree($tree);  
  is_deeply($new_from_tree->as_tree(allow_loops => 1), $check_tree, "new_from_tree 4 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree(allow_loops => 1), "new_from_json 4 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree(allow_loops => 1), "new_from_yaml 4 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  $tree = 
    $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 2, allow_loops => 1,
      prune => sub { shift->name =~ /^p/ });

  $check_tree =
  {
    'colors' => 
    [
      {
        'description' => 
        {
          'id'   => '1',
          'text' => 'desc 1'
        },
        'description_id' => '1',
        'id'             => '1',
        'name'           => 'red',
      },
      {
        'description' => 
        {
          'id'   => '3',
          'text' => 'desc 3'
        },
        'description_id' => '3',
        'id'             => '3',
        'name'           => 'green',
      }
    ],
    'id'     => '2',
    'name'   => 'Sled',
    'sale_date' => '2005-02-02 00:00:00',
    'vendor' => 
    {
      'id'       => '2',
      'name'     => 'V2',
      'region' => 
      {
        'id'   => 'US',
        'name' => 'America'
      },
      'region_id' => 'US',
      'vendor'    => 
      {
        'id'        => '1',
        'name'      => 'V1',
        'region_id' => 'DE',
        'vendor_id' => undef
      },
      'vendor_id' => '1',
      'vendors'   => []
    },
    'vendor_id' => '2'
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 2, allow_loops => 1, /^p/ - $db_type");

  $new_from_tree = $product_class->new_from_tree($tree);  
  is_deeply($new_from_tree->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }), $check_tree, "new_from_tree 5 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }), "new_from_json 5 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }), "new_from_yaml 5 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  $tree = 
    $product_class->new(id => 2)->as_tree(force_load => 1, max_depth => 2, allow_loops => 1,
      prune => sub { shift->name =~ /^p/ }, exclude => sub { no warnings; shift->id > 2 });

  $check_tree =
  {
    'colors' => 
    [
      {
        'description' => 
        {
          'id'   => '1',
          'text' => 'desc 1'
        },
        'description_id' => '1',
        'id'             => '1',
        'name'           => 'red',
      },
    ],
    'id'     => '2',
    'name'   => 'Sled',
    'sale_date' => '2005-02-02 00:00:00',
    'vendor' => 
    {
      'id'       => '2',
      'name'     => 'V2',
      'region' => 
      {
        'id'   => 'US',
        'name' => 'America'
      },
      'region_id' => 'US',
      'vendor'    => 
      {
        'id'        => '1',
        'name'      => 'V1',
        'region_id' => 'DE',
        'vendor_id' => undef
      },
      'vendor_id' => '1',
      'vendors'   => []
    },
    'vendor_id' => '2'
  };

  is_deeply($tree, $check_tree, "as_tree force, depth 2, allow_loops => 1, /^p/,id > 2 - $db_type");

  $new_from_tree = $product_class->new_from_tree($tree);
  is_deeply($new_from_tree->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }, exclude => sub { no warnings; shift->id > 2 }), $check_tree, "new_from_tree 6 - $db_type");

  if($Have_JSON)
  {
    my $json = $product_class->new(id => 2)->as_json(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_json = $product_class->new_from_json($json);
    is_deeply($check_tree, $new_from_json->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }, exclude => sub { no warnings; shift->id > 2 }), "new_from_json 6 - $db_type");
  }
  else { SKIP: { skip('JSON tests', 1) } }

  if($Have_YAML)
  {
    my $yaml = $product_class->new(id => 2)->as_yaml(force_load => 1, max_depth => 2, allow_loops => 1);
    my $new_from_yaml = $product_class->new_from_yaml($yaml);
    is_deeply($check_tree, $new_from_yaml->as_tree(allow_loops => 1, prune => sub { shift->name =~ /^p/ }, exclude => sub { no warnings; shift->id > 2 }), "new_from_yaml 6 - $db_type");
  }
  else { SKIP: { skip('YAML tests', 1) } }

  # Test round-trip of non-column attributes

  $product_class->meta->add_nonpersistent_column(
    other_date => { type => 'datetime', default => DateTime->new(year => 2008, month => 12, day => 31) });

  $product_class->meta->make_nonpersistent_column_methods;

  my $p3 = 
    $product_class->new(
      id         => 3,
      name       => 'Barn',
      other_date => '12/31/2007');

  $check_tree =
  {
    'id' => 3,
    'name' => 'Barn',
    'other_date' => '2007-12-31 00:00:00',
    'sale_date' => undef,
    'vendor_id' => undef
  };

  is_deeply($p3->as_tree, $check_tree, "nonpersistent columns 1 - $db_type");

  $check_tree =
  {
    'id' => 3,
    'name' => 'Barn',
    'sale_date' => undef,
    'vendor_id' => undef
  };

  is_deeply($p3->as_tree(persistent_columns_only => 1), $check_tree, "nonpersistent columns 2 - $db_type");

  #$tree = $p3->as_tree
  # my $p3 = 
  #   $product_class->new(
  #     id     => 3,
  #     name   => 'Barn',
  #     vendor => { id => 3, name => 'V3', region => { id => 'UK', name => 'England' }, vendor_id => 2 },
  #     prices => [ { price => 100 } ],
  #     colors => 
  #     [
  #       { name => 'green' }, 
  #       {
  #         name => 'pink',
  #         description => 
  #         {
  #           text => 'desc 4',
  #           authors => [ { name => 'joe', nicknames => [ { nick => 'joey' } ] } ],
  #         }
  #       }
  #     ]);
  # 
  # $p3->save;

  #local $Rose::DB::Object::Manager::Debug = 1;
}

#
# init_with_tree() bug
#

INIT_WITH_TREE_BUG:
{
  SKIP:
  {
    skip("init_with_tree() bug tests", 4)  unless(%Have);
  }

  next  unless(%Have);

  package Project::Model::User;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table => 'user',

    columns => 
    [
      id                         => { type => 'bigserial', not_null => 1 },
      name                       => { type => 'varchar', length => 100, not_null => 1 },
      password                   => { type => 'varchar', length => 100, not_null => 1 },
      name_prefix                => { type => 'varchar', length => 20 },
      first_name                 => { type => 'varchar', length => 255 },
      last_name                  => { type => 'varchar', length => 255 },
      reseller_id                => { type => 'integer', default => 0, not_null => 1 },
      created_at                 => { type => 'datetime', not_null => 1 },
      updated_at                 => { type => 'datetime', not_null => 1 },
      parent_user_id             => { type => 'bigint' },
      user_company_id            => { type => 'bigint' },
      company_name               => { type => 'varchar', length => 255 },
      owner_user_id              => { type => 'bigint' },
      user_title_id              => { type => 'bigint' },
      job_title                  => { type => 'varchar', length => 255 },
      primary_user_company_id    => { type => 'bigint' },
      primary_user_title_id      => { type => 'bigint' },
      primary_user_phone_id      => { type => 'bigint' },
      primary_user_email_id      => { type => 'bigint' },
      primary_user_address_id    => { type => 'bigint' },
      commission_user_address_id => { type => 'bigint' },
      user_source_id             => { type => 'integer' },
      updated_by_user_id         => { type => 'bigint' },
      locale_id                  => { type => 'integer', not_null => 1 },
      spoken_lang                => { type => 'enum', check_in => [ 'English', 'Mandarin', 'Cantonese' ], default => 'English', not_null => 1 },
      encryption_key             => { type => 'character', length => 32 },
      timezone_id                => { type => 'integer', default => 513, not_null => 1 },
      user_type_id               => { type => 'integer', default => 0, not_null => 1 },
      primary_billing_method_id  => { type => 'bigint' },
      autodetect_timezone        => { type => 'integer', default => 0, not_null => 1 },
      is_login_disabled          => { type => 'integer', default => 0 },
      security_question_id       => { type => 'integer', default => 1, not_null => 1 },
      security_question_custom   => { type => 'varchar', length => 255 },
      security_answer            => { type => 'varchar', length => 255 },
      has_temporary_password     => { type => 'integer', default => 0 },
      email_id                   => { type => 'bigint' },
      payment_failure_status     => { type => 'integer', default => 0, not_null => 1 },
      notes                      => { type => 'text', length => 65535 },
    ],

    primary_key_columns => ['id'],

    unique_keys => [['email_id'], ['name'],],

    relationships => 
    [
      user_addresses => 
      {
        class      => 'Project::Model::UserAddress',
        column_map => { id => 'user_id' },
        type       => 'one to many',
      },

      user_emails => 
      {
        class      => 'Project::Model::UserEmail',
        column_map => { id => 'user_id' },
        type       => 'one to many',
      },

      user_phones => 
      {
        class      => 'Project::Model::UserPhone',
        column_map => { id => 'user_id' },
        type       => 'one to many',
      },
    ],
  );


  package Project::Model::UserAddress;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table   => 'user_address',

    columns => 
    [
      id                   => { type => 'bigserial', not_null => 1 },
      user_id              => { type => 'bigint', not_null => 1 },
      user_address_type_id => { type => 'integer', not_null => 1 },
      geo_country_id       => { type => 'integer', not_null => 1 },
      address1             => { type => 'varchar', length => 255 },
      address2             => { type => 'varchar', length => 255 },
      address3             => { type => 'varchar', length => 255 },
      geo_subregion        => { type => 'varchar', length => 255 },
      geo_region_id        => { type => 'integer' },
      postal_code1         => { type => 'varchar', length => 5 },
      postal_code2         => { type => 'varchar', length => 5 },
      created_at           => { type => 'datetime', not_null => 1 },
      updated_at           => { type => 'datetime', not_null => 1 },
    ],


    primary_key_columns => [ 'id' ],

    relationships => 
    [
      users => 
      {
        class      => 'IV::Model::User',
        column_map => { id => 'commission_user_address_id' },
        type       => 'one to many',
      },
    ],
  );

  package Project::Model::UserEmail;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table   => 'user_email',

    columns => 
    [
      id                 => { type => 'bigserial', not_null => 1 },
      email              => { type => 'varchar', length => 255, not_null => 1 },
      user_id            => { type => 'bigint', not_null => 1 },
      user_email_type_id => { type => 'integer', not_null => 1 },
      created_at         => { type => 'datetime', not_null => 1 },
      updated_at         => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => [ 'id' ],

    unique_key => [ 'user_id', 'email' ],

    foreign_keys => 
    [
      user => 
      {
        class       => 'Project::Model::User',
        key_columns => { user_id => 'id' },
      },
    ],
  );

  package Project::Model::UserPhone;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table => 'user_phone',

    columns => 
    [
      id                 => { type => 'bigserial', not_null => 1 },
      user_id            => { type => 'bigint', not_null => 1 },
      geo_country_id     => { type => 'integer', not_null => 1 },
      area_code          => { type => 'varchar', length => 4 },
      number1            => { type => 'varchar', length => 10 },
      number2            => { type => 'varchar', length => 10 },
      extension          => { type => 'varchar', length => 50 },
      user_phone_type_id => { type => 'integer', not_null => 1 },
      created_at         => { type => 'datetime', not_null => 1 },
      updated_at         => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => ['id'],

    foreign_keys => 
    [
      user => 
      {
        class       => 'Project::Model::User',
        key_columns => { user_id => 'id' },
      },
    ],
  );


  package main;

  use Rose::DB::Object::Helpers qw/as_tree init_with_tree/;

  my $tree = 
  {
    'user_titles'                     => [],
    'billing_invoices'                => [],
    'incident_external_departments'   => [],
    'salescalendar_user_calendars'    => [],
    'salescalendar_appointment_notes' => [],
    'password'                        => '$1$068F9leP$8jfRI43HMUS2/jxUsQTme.',
    'incident_internal_departments'   => [],
    'user_title_id'                   => undef,
    'reseller_id'                     => '4',
    'incidents_external_owned_by'     => [],
    'primary_billing_method_id'       => undef,
    'name'                            => 'sego03',
    'timezone_id'                     => '513',
    'user_login_logs'                 => [],
    'primary_user_email_id'           => '8061',
    'updated_at'                      => '2008-08-27 22:39:40',
    'encryption_key'                  => '37dcd1d8fc4555fd46f063fbb8e4f55b',
    'security_answer'                 => undef,
    'commission_user_address_id'      => undef,
    'job_title'                       => '',
    'updated_by_user_id'              => undef,
    'salescalendar_appointments'      => [],
    'notes_entered_by'                => [],
    'created_at'                      => '2008-07-10 00:31:58',
    'owner_user_id'                   => '5343',
    'billing_methods'                 => [],
    'autodetect_timezone'             => 0,
    'domains'                         => [],
    'notes'                           => undef,
    'user_company_id'                 => undef,
    'user_source_id'                  => '1',
    'website'                         => {},
    'primary_user_company_id'         => undef,
    'company_name'                    => 'myCompany',
    'user_phones'                     => 
    [
      {
        'area_code'          => '888',
        'extension'          => '',
        'created_at'         => '2008-07-10 00:31:58',
        'number1'            => '8888',
        'geo_country_id'     => '4',
        'user_phone_type_id' => '1',
        'number2'            => '8888',
        'id'                 => '8399',
        'user_id'            => '11647'
      }
    ],
    'primary_user_address_id'                 => undef,
    'salescalendar_appointments_cancelled_by' => [],
    'user_type_id'                            => '6',
    'id'                                      => '11647',
    'password_confirm'                        => '$1$068F9leP$8jfRI43HMUS2/jxUsQTme.',
    'salescalendar_appointments_salesrep'     => [],
    'roles'                                   => [],
    'user_emails'                             => 
    [
      {
        'email'              => 'test@test.com',
        'created_at'         => '2008-07-10 00:31:58',
        'user_email_type_id' => '1',
        'id'                 => '8061',
        'user_id'            => '11647'
      }
    ],
    'salescalendar_lockouts'      => [],
    'name_prefix'                 => '',
    'user_companies'              => [],
    'payment_failure_status'      => 0,
    'locale_id'                   => '8',
    'parent_user_id'              => 1,
    'has_temporary_password'      => 0,
    'email_id'                    => undef,
    'incidents_entered_by'        => [],
    'contact_website'             => {},
    'last_name'                   => 'sego03',
    'is_login_disabled'           => 0,
    'security_question_id'        => '1',
    'billing_schedules'           => [],
    'primary_user_title_id'       => undef,
    'updated_users'               => [],
    'primary_user_phone_id'       => '8399',
    'spoken_lang'                 => 'English',
    'incidents'                   => [],
    'security_question_custom'    => undef,
    'incidents_internal_owned_by' => [],
    'user_addresses'              => [],
    'child_users'                 => [],
    'first_name'                  => ''
  };

  my $user_archive = init_with_tree(Project::Model::User->new, $tree);

  is($user_archive->id, 11647, 'init_with_tree() columns first bug 1');
  is($user_archive->user_emails->[0]->user_id, 11647, 'init_with_tree() columns first bug 2');
  is($user_archive->user_phones->[0]->user_id, 11647, 'init_with_tree() columns first bug 3');

  $tree = as_tree($user_archive);

  is($tree->{'user_phones'}[0]{'user_id'}, 11647, 'as_tree() traverse fks');
}

BEGIN
{
  our($Have_YAML, $Have_JSON);

  eval { require YAML::Syck };
  $Have_YAML = $@ ? 0 : 1;

  eval
  {
    require JSON;
    die "JSON $JSON::VERSION too old"  unless($JSON::VERSION >= 2.00);
  };

  $Have_JSON = $@ ? 0 : 1;
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

  if(!$@ && $dbh && $DBD::Pg::VERSION ge '2.15.1')
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
  id         SERIAL NOT NULL PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  vendor_id  INT REFERENCES vendors (id),
  sale_date  TIMESTAMP,

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
  id         SERIAL NOT NULL PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  vendor_id  INT REFERENCES Rose_db_object_private.vendors (id),
  sale_date  TIMESTAMP,

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
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  vendor_id  INT,
  sale_date  DATETIME,

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
  sale_date  DATETIME YEAR TO SECOND,

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
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       VARCHAR(255) NOT NULL,
  vendor_id  INT REFERENCES vendors (id),
  sale_date  DATETIME,

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
