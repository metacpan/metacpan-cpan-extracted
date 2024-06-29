use strict;
use Test::More 0.98;
use Data::Dumper;

plan skip_all => 'To test Modules, set OS_HOST, OS_USER, OS_PASS, OS_INDEX, OS_SSL in ENV'
  unless $ENV{OS_HOST} && exists( $ENV{OS_USER} ) && exists( $ENV{OS_PASS} ) && $ENV{OS_INDEX};

my $host  = $ENV{OS_HOST};
my $user  = $ENV{OS_USER};
my $pass  = $ENV{OS_PASS};
my $index = $ENV{OS_INDEX};
my $ssl   = $ENV{OS_SSL} || 0;

print Dumper \%ENV;

use OpenSearch;

my $os = OpenSearch->new(
  user            => $user,
  pass            => $pass,
  hosts           => [$host],
  secure          => $ssl,
  allow_insecure  => 1,
  async           => 0,
  pool_count      => 10,
  max_connections => 50,
);

my $index_api = $os->index;

my $idx_name = 'os-perl-test-index-' . time;

# exists()
my $res = $index_api->exists( index => $idx_name );
is $res->code, 404, 'Create index returns 404';

# Create Index
$res = $index_api->create(
  index    => $idx_name,
  settings => {
    'number_of_shards' => 2,
  }
);
is $res->code, 200, 'Create index returns 200';

# exists()
$res = $index_api->exists( index => $idx_name );
is $res->code, 200, 'Create index returns 200';

# clear_cache()
$res = $index_api->clear_cache( index => $idx_name );
is $res->code,                          200, 'Clear cache returns 200';
is $res->data->{_shards}->{successful}, 2,   'Clear cache returns correct data';

# set_aliases()
$res = $index_api->set_aliases(
  actions => [ {
    add => {
      index => $idx_name,
      alias => $idx_name . '-alias'
    }
  } ]
);
is $res->code, 200, 'Set aliases returns 200';

# get_aliases()
$res = $index_api->get_aliases();
is $res->code,                                                             200, 'Get aliases returns 200';
is exists( $res->data->{$idx_name}->{aliases}->{ $idx_name . '-alias' } ), 1,   'Get aliases returns correct data';

# update_mappings()
$res = $index_api->set_mappings(
  index      => $idx_name,
  properties => {
    title => {
      type => 'text'
    }
  }
);
is $res->code,                 200, 'Update mappings returns 200';
is $res->data->{acknowledged}, 1,   'Update mappings returns correct data';

# get_mappings()
$res = $index_api->get_mappings( index => $idx_name );
is $res->code,                                                         200,    'Get mappings returns 200';
is $res->data->{$idx_name}->{mappings}->{properties}->{title}->{type}, 'text', 'Get mappings returns correct data';

# get()
$res = $index_api->get( index => $idx_name );
is $res->code,                        200, 'Get index returns 200';
is exists( $res->data->{$idx_name} ), 1,   'Get index returns correct data';

# update_settings()
$res = $index_api->update_settings(
  index    => $idx_name,
  settings => {
    'index.blocks.write' => 'true'
  }
);
is $res->code,                 200, 'Update settings returns 200';
is $res->data->{acknowledged}, 1,   'Update settings returns correct data';

# get_settings()
$res = $index_api->get_settings( index => $idx_name, flat_settings => 1 );
is $res->code,                                                            200, 'Get settings returns 200';
is exists( $res->data->{$idx_name}->{settings}->{'index.blocks.write'} ), 1,   'Get settings returns correct data';

# clone()
$res = $index_api->clone(
  index    => $idx_name,
  target   => $idx_name . '-clone',
  settings => {
    'index.number_of_shards' => 2
  }
);
is $res->code,                 200, 'Clone index returns 200';
is $res->data->{acknowledged}, 1,   'Clone index returns correct data';

# stats()
$res = $index_api->stats( index => $idx_name );
is $res->code, 200, 'Stats returns 200';

# close()
$res = $index_api->close( index => $idx_name );
is $res->code, 200, 'Close index returns 200';

# open()
$res = $index_api->open( index => $idx_name );
is $res->code, 200, 'Open index returns 200';

# refresh()
$res = $index_api->refresh( index => $idx_name );
is $res->code, 200, 'Refresh index returns 200';

# shrink()
$res = $index_api->shrink(
  index  => $idx_name . '-clone',
  target => $idx_name . '-shrink',
);
is $res->code,                 200, 'Shrink index returns 200';
is $res->data->{acknowledged}, 1,   'Shrink index returns correct data';

# delete()
$res = $index_api->delete( index => $idx_name );
is $res->code, 200, 'Delete index returns 200';

# Delete clone and shrink
$res = $index_api->delete( index => $idx_name . '-clone' );
$res = $index_api->delete( index => $idx_name . '-shrink' );

done_testing;

