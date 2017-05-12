#!/usr/bin/perl -w

use strict;

use Test::More tests => 37;

use Rose::DB::Object;

BEGIN { require 't/test-lib.pl' }

our %Have;

our $Debug = 0;

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 37)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $accounts = Rose::DB::Object::Manager->get_objects
  (
    debug         => $Debug,
    object_class  => 'My::Account',
    with_objects  => [ 'channels.itemMaps' ],
    #sort_by       => 't1.accountId ASC',
    multi_many_ok => 1,
   );

  test_accounts($accounts);

  $accounts = Rose::DB::Object::Manager->get_objects
  (
    debug         => $Debug,
    object_class  => 'My::Account',
    with_objects  => [ 'items.feature', 'channels.itemMaps' ],
    #sort_by       => 't1.accountId, t2.accountId, t3.featureId, t4.accountId, t5.channelId',
    multi_many_ok => 1,
  );

  test_accounts($accounts);

  my $iterator = Rose::DB::Object::Manager->get_objects_iterator
  (
    debug         => $Debug,
    object_class  => 'My::Account',
    with_objects  => [ 'items.feature', 'channels.itemMaps' ],
    #sort_by       => 't1.accountId, t2.accountId, t3.featureId, t4.accountId, t5.channelId',
    multi_many_ok => 1,
  );

  my @accounts;

  while(my $object = $iterator->next)
  {
    push(@accounts, $object);
  }

  test_accounts(\@accounts);

  COUNTER:
  {
    my $i;

    sub test_accounts
    {
      my ($accounts) = shift;

      foreach my $account (@$accounts)
      {
        $Debug && print 'Account ID ', $account->accountId . " has the following channels:\n";

        foreach my $channel ( $account->channels )
        {
          $Debug && print '  Channel ID ', $channel->channelId, " has the following items:\n";

          foreach my $itemMap ( $channel->itemMaps )
          {
            if ($Debug)
            {
              print '    Item ID ', $itemMap->itemId, ' is at position ', $itemMap->position;
              print "  <-- incorrect because map's channelId = ", $itemMap->channelId
                if ( $channel->channelId != $itemMap->channelId );
              print "\n";
            }

            $i ||= 0;
            is( $channel->channelId, $itemMap->channelId, "id match $i" );
            $i++;
          }
        }
      }
    }
  }

  eval
  {
    my $documents =
      Rose::DB::Object::Manager->get_objects(
        object_class => 'My2::DB::Object::Document',
        with_objects => [ 'versions.bs', 'versions.secs' ], 
        query =>
        [
          c_id => 34639,
          deleted  => 0,
        ],
        multi_many_ok => 1);

    my $iterator =
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'My2::DB::Object::Document',
        with_objects => [ 'versions.bs', 'versions.secs' ], 
        query =>
        [
          c_id => 34639,
          deleted  => 0,
        ],
        multi_many_ok => 1);

    while (my $object = $iterator->next) {
        ; # do nothing
    }
  };

  ok(!$@, 'Multi-many 2');
}

#warn $@ if $@;

BEGIN
{
  our %Have;

  #
  # MySQL
  #

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('SET FOREIGN_KEY_CHECKS = 0');
      $dbh->do('DROP TABLE channel_item_map');
      $dbh->do('DROP TABLE accounts');
      $dbh->do('DROP TABLE channels');
      $dbh->do('DROP TABLE features');
      $dbh->do('DROP TABLE items');

      $dbh->do('DROP TABLE ab');
      $dbh->do('DROP TABLE d');
      $dbh->do('DROP TABLE ds');
      $dbh->do('DROP TABLE dv');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    Rose::DB->default_type('mysql');

    $dbh->do(<<"EOF");
CREATE TABLE accounts
(
  accountId INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner     VARCHAR(100) NOT NULL
)
EOF

    $dbh->do($_) for(split(/;\n/, <<"EOF"));
INSERT INTO accounts (accountId, owner) VALUES (1, 'Account Owner 1');
INSERT INTO accounts (accountId, owner) VALUES (2, 'Account Owner 2');
EOF

    $dbh->do(<<"EOF");
CREATE TABLE channels
(
  channelId  INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  accountId  INT UNSIGNED NOT NULL,
  name       VARCHAR(100) NOT NULL,

  KEY accountId (accountId)
)
EOF

    $dbh->do($_) for(split(/;\n/, <<"EOF"));
INSERT INTO channels (channelId, accountId, name) VALUES (1, 1, 'Channel 1 Name');
INSERT INTO channels (channelId, accountId, name) VALUES (2, 1, 'Channel 2 Name');
INSERT INTO channels (channelId, accountId, name) VALUES (3, 1, 'Channel 3 Name');
INSERT INTO channels (channelId, accountId, name) VALUES (4, 2, 'Channel 4 Name');
EOF

    $dbh->do(<<"EOF");
CREATE TABLE features
(
  featureId    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  accountId    INT UNSIGNED NOT NULL,
  description  VARCHAR(500) NOT NULL,

  KEY accountId (accountId)
)
EOF

    $dbh->do($_) for(split(/;\n/, <<"EOF"));
INSERT INTO features (featureId, accountId, description) VALUES (1, 1, 'Feature 1 description.');
INSERT INTO features (featureId, accountId, description) VALUES (2, 1, 'Feature 2 description.');
INSERT INTO features (featureId, accountId, description) VALUES (3, 1, 'Feature 3 description.');
EOF

    $dbh->do(<<"EOF");
CREATE TABLE items
(
  itemId     INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  accountId  INT UNSIGNED NOT NULL,
  featureId  INT UNSIGNED NULL,
  title       VARCHAR(100) NOT NULL,

  KEY accountId (accountId),
  KEY featureId (featureId)
)
EOF

    $dbh->do($_) for(split(/;\n/, <<"EOF"));
INSERT INTO items (itemId, accountId, featureId, title) VALUES (1, 1, 1, 'Item 1 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (2, 1, 1, 'Item 2 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (3, 1, 2, 'Item 3 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (4, 1, 2, 'Item 4 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (5, 1, 2, 'Item 5 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (6, 1, 2, 'Item 6 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (7, 1, 3, 'Item 7 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (8, 1, 3, 'Item 8 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (9, 1, 3, 'Item 9 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (10, 1, 3, 'Item 10 Title');
INSERT INTO items (itemId, accountId, featureId, title) VALUES (11, 1, 3, 'Item 11 Title');
INSERT INTO items (itemId, accountId, title) VALUES (12, 2, 'Item 12 Title');
EOF

    $dbh->do(<<"EOF");
CREATE TABLE channel_item_map
(
  channelId  INT UNSIGNED NOT NULL,
  itemId     INT UNSIGNED NOT NULL,
  position   INT UNSIGNED NOT NULL,

  PRIMARY KEY  (channelId, position),
  KEY channelId (channelId),
  KEY itemId (itemId)
)
EOF

    $dbh->do($_) for(split(/;\n/, <<"EOF"));
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (1, 1, 1);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (1, 2, 2);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (1, 3, 3);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (1, 4, 4);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (1, 5, 5);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (2, 6, 1);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (2, 7, 2);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (3, 8, 1);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (3, 9, 2);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (3, 10, 3);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (3, 11, 4);
INSERT INTO channel_item_map (channelId, itemId, position) VALUES (4, 12, 1);
EOF

    $dbh->do($_) for(grep { /\S/ } split(/;/, <<"EOF"));
ALTER TABLE channels ADD CONSTRAINT channels_to_accounts_fk
  FOREIGN KEY (accountId) REFERENCES accounts (accountId) ON DELETE CASCADE;

ALTER TABLE features ADD CONSTRAINT features_to_accounts_fk
  FOREIGN KEY (accountId) REFERENCES accounts (accountId) ON DELETE CASCADE;

ALTER TABLE channel_item_map 
  ADD CONSTRAINT channel_item_map_to_channels_fk
    FOREIGN KEY (channelId) REFERENCES channels (channelId) ON DELETE CASCADE,
  ADD CONSTRAINT channel_item_map_to_items_fk 
    FOREIGN KEY (itemId) REFERENCES items (itemId) ON DELETE CASCADE;

ALTER TABLE items 
  ADD CONSTRAINT items_to_accounts_fk 
    FOREIGN KEY (accountId) REFERENCES accounts (accountId) ON DELETE CASCADE,
  ADD CONSTRAINT items_to_features_fk
    FOREIGN KEY (featureId) REFERENCES features (featureId) ON DELETE CASCADE;
EOF

    #$dbh->disconnect;

    package My::DB::Object;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new }

    package My::Account;

    our @ISA = qw(My::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'accounts',

      columns => 
      [
        accountId => 
        {
          type     => 'serial',
          not_null => 1,
        },
        owner => 
        {
          type     => 'varchar',
          length   => 100,
          not_null => 1,
        },
      ],

      primary_key_columns => ['accountId'],

      relationships => 
      [
        items => 
        {
          type       => 'one to many',
          class      => 'My::Item',
          column_map => { accountId => 'accountId' }
        },
        features => 
        {
          type       => 'one to many',
          class      => 'My::Feature',
          column_map => { featureId => 'featureId' }
        },
        channels => 
        {
          type       => 'one to many',
          class      => 'My::Channel',
          column_map => { accountId => 'accountId' }
        },
      ],
    );

    package My::ChannelItemMap;

    our @ISA = qw(My::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'channel_item_map',

      columns => 
      [
        channelId => 
        {
          type     => 'integer',
          not_null => 1,
        },
        itemId => 
        {
          type     => 'integer',
          not_null => 1,
        },
        position => 
        {
          type     => 'integer',
          not_null => 1,
        },
      ],

      primary_key_columns => [ 'channelId', 'position' ],

      foreign_keys => 
      [
        channel => 
        {
          class       => 'My::Channel',
          key_columns => { channelId => 'channelId' },
        },
        item => 
        {
          class       => 'My::Item',
          key_columns => { itemId => 'itemId' },
        },
      ],
    );

    package My::Channel;

    our @ISA = qw(My::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'channels',

      columns => 
      [
        channelId => 
        {
          type     => 'serial',
          not_null => 1,
        },
        accountId => 
        {
          type     => 'integer',
          not_null => 1,
        },
        name => 
        {
          type     => 'varchar',
          length   => 100,
          not_null => 1,
        },
      ],

      primary_key_columns => ['channelId'],

      foreign_keys => 
      [
        account => 
        {
          class       => 'My::Account',
          key_columns => { accountId => 'accountId' },
        },
      ],

      relationships => 
      [
        itemMaps => 
        {
          type       => 'one to many',
          class      => 'My::ChannelItemMap',
          column_map => { channelId => 'channelId' },
        },
      ],
    );

    package My::Feature;

    our @ISA = qw(My::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'features',

      columns => 
      [
        featureId => 
        {
          type     => 'serial',
          not_null => 1,
        },
        accountId => 
        {
          type     => 'integer',
          not_null => 1,
        },
        description => 
        {
          type     => 'varchar',
          length   => 500,
          not_null => 1,
        },
      ],

      primary_key_columns => ['featureId'],

      foreign_keys => 
      [
        account => 
        {
          class       => 'My::Account',
          key_columns => { accountId => 'accountId' },
        },
      ],

      relationships => 
      [
        items => 
        {
          type       => 'one to many',
          class      => 'My::Item',
          column_map => { featureId => 'featureId' },
        },
      ],
    );

    package My::Item;

    our @ISA = qw(My::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'items',

      columns => 
      [
        itemId => 
        {
          type     => 'serial',
          not_null => 1,
        },
        accountId => 
        {
          type     => 'integer',
          not_null => 1,
        },
        featureId => { type => 'integer', },
        title     => 
        {
          type     => 'varchar',
          length   => 100,
          not_null => 1,
        },
      ],

      primary_key_columns => ['itemId'],

      foreign_keys => 
      [
        account => 
        {
          class       => 'My::Account',
          key_columns => { accountId => 'accountId' },
        },
        feature => 
        {
          class       => 'My::Feature',
          key_columns => { featureId => 'featureId' },
        },
      ],

      relationships => 
      [
        channelMaps => 
        {
          type       => 'one to many',
          class      => 'My::ChannelItemMap',
          column_map => { itemId => 'itemId' },
        },
      ],
    );

    $dbh->do($_) for(grep { /\S/ } split(/;/, <<"EOF"));
CREATE TABLE ab
(
  id               BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  battery_id       BIGINT(20) UNSIGNED NOT NULL,
  dv_id  bigint(20) unsigned NOT NULL
);

INSERT INTO ab VALUES
  (265633,22,306667),
  (265634,22,306668),
  (265637,22,306670);

CREATE TABLE d
(
  id       INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  c_id     INT UNSIGNED NOT NULL,
  pq       VARCHAR(255) NOT NULL,
  accid    VARCHAR(255) DEFAULT NULL,
  deleted  INT(1) DEFAULT '0',

  UNIQUE KEY doc_unq1 (c_id, pq)
);

INSERT INTO d VALUES (132156,34639,'lab 08:M0011740R','V00011071496',0);

CREATE TABLE ds 
(
  document_id  INT UNSIGNED NOT NULL,
  s_id         INT UNSIGNED NOT NULL
);

INSERT INTO ds VALUES (385,1),
  (3952,1), (4151,1), (4154,1), (4469,1), (4709,1), (4711,1), (4713,1),
  (4714,1), (5760,1), (6112,1), (6270,1), (6280,1), (6282,1), (6283,1),
  (7150,1), (7283,1), (7285,1), (7477,1), (7479,1), (8654,1), (12125,1),
  (12127,1), (12306,1), (12308,1), (12310,1), (12776,1), (13381,1), (13385,1),
  (13717,1), (13752,1), (14311,1), (14312,1), (14388,1), (14389,1), (14392,1),
  (16625,1), (18511,1), (18513,1), (18515,1), (18908,1), (18917,1), (18918,1),
  (18922,1), (18923,1), (18924,1), (18926,1), (19153,1), (19155,1), (19157,1),
  (19165,1), (19489,1), (22535,1), (24549,1), (24551,1), (25434,1), (25507,1),
  (25597,1), (25605,1), (25607,1), (25644,1), (26681,1), (26682,1), (26688,1),
  (26689,1), (26690,1), (26691,1), (29690,1), (29692,1), (29693,1), (31032,1),
  (31036,1), (31038,1), (31040,1), (31044,1), (31052,1), (31054,1), (33208,1),
  (33215,1), (33217,1), (33219,1), (34543,1), (36633,1), (36858,1), (36864,1),
  (36871,1), (36873,1), (38303,1), (39159,1), (39186,1), (39653,1), (39655,1),
  (40662,1), (40664,1), (40669,1), (40671,1), (44727,1), (44732,1), (44735,1),
  (44737,1), (45061,1), (45063,1), (45064,1), (46037,1), (46039,1), (46044,1),
  (46696,1), (46697,1), (46705,1), (46709,1), (46710,1), (46712,1), (47580,1),
  (47582,1), (47585,1), (48113,1), (48115,1), (52374,1), (56361,1), (56370,1),
  (56373,1), (56379,1), (56990,1), (56997,1), (57013,1), (57100,1), (57114,1),
  (57115,1), (57116,1), (57117,1), (57118,1), (57120,1), (58980,1), (58982,1),
  (58988,1), (59234,1), (60198,1), (60719,1), (60724,1), (60726,1), (60893,1),
  (60895,1), (60896,1), (60905,1), (60907,1), (60908,1), (62360,1), (62362,1),
  (62367,1), (62691,1), (62697,1), (62700,1), (62703,1), (63795,1), (63807,1),
  (63809,1), (63811,1), (63974,1), (63976,1), (63980,1), (63986,1), (63993,1),
  (63997,1), (64170,1), (65224,1), (66565,1), (66568,1), (66570,1), (66576,1),
  (66943,1), (66944,1), (66945,1), (66946,1), (66947,1), (66948,1), (67829,1),
  (67830,1), (67832,1), (68280,1), (70071,1), (70073,1), (70074,1), (70189,1),
  (70191,1), (70192,1), (71404,1), (71411,1), (71412,1), (71423,1), (71426,1),
  (71428,1), (72034,1), (72035,1), (72041,1), (72043,1), (72047,1), (73848,1),
  (73853,1), (74527,1), (74643,1), (74645,1), (76348,1), (76351,1), (76352,1),
  (80843,1), (80845,1), (80848,1), (81423,1), (81425,1), (81433,1), (81667,1),
  (82497,1), (82597,1), (82604,1), (82605,1), (82607,1), (84571,1), (84574,1),
  (84576,1), (84586,1), (84860,1), (84873,1), (84875,1), (84877,1), (85796,1),
  (86047,1), (86049,1), (86621,1), (87242,1), (87243,1), (88762,1), (88764,1),
  (88767,1), (88771,1), (88776,1), (88779,1), (88958,1), (88964,1), (88966,1),
  (90035,1), (92485,1), (92487,1), (92758,1), (93549,1), (93551,1), (93561,1),
  (95296,1), (95560,1), (95724,1), (95736,1), (95737,1), (95738,1), (95746,1),
  (97592,1), (99377,1), (101388,1), (101390,1), (101391,1), (101507,1),
  (101517,1), (102003,1), (102748,1), (102749,1), (103525,1), (104347,1),
  (104358,1), (104361,1), (104448,1), (104478,1), (104555,1), (106771,1),
  (106778,1), (106988,1), (106990,1), (107780,1), (107783,1), (107785,1),
  (110554,1), (111333,1), (111335,1), (111355,1), (111359,1), (111361,1),
  (111363,1), (112149,1), (112151,1), (112833,1), (113902,1), (114190,1),
  (114192,1), (116154,1), (116161,1), (116162,1), (116164,1), (117490,1),
  (117492,1), (118065,1), (118067,1), (119498,1), (119741,1), (120936,1),
  (120978,1), (121069,1), (121072,1), (121075,1), (122939,1), (122943,1),
  (123817,1), (124142,1), (124248,1), (124250,1), (126837,1), (126838,1),
  (126842,1), (126843,1), (126844,1), (126845,1), (126847,1), (128136,1),
  (128138,1), (128140,1), (129881,1), (131002,1), (131007,1), (131010,1),
  (131012,1), (131536,1), (131538,1), (131922,1), (131924,1), (131926,1),
  (133203,1), (133205,1), (133207,1), (133777,1), (133785,1), (133787,1),
  (134804,1), (134806,1), (134812,1), (134816,1), (135811,1), (135817,1),
  (135819,1), (135820,1), (136227,1), (136229,1), (137796,1), (137805,1),
  (137811,1), (138115,1), (138117,1), (138120,1);

CREATE TABLE dv
(
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  document_id INT UNSIGNED NOT NULL
);

INSERT INTO dv VALUES 
  (306667,132156),
  (306668,132156),
  (306670,132156);
EOF

    $dbh->disconnect;

    package My2::DB::Object;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new }

    package My2::DB::Object::DocumentVersion;

    our @ISA = qw(My2::DB::Object);

    __PACKAGE__->meta->setup
    (
      table   => 'dv',

      columns => 
      [
        id          => { type => 'bigserial', not_null => 1 },
        document_id => { type => 'bigint', not_null => 1 },
      ],

      primary_key_columns => [ 'id' ],

      foreign_keys => 
      [
        d => 
        {
          class       => 'My2::DB::Object::Document',
          key_columns => { 'document_id' => 'id' },
        },
      ],

      relationships =>
      [
        bs => 
        {
          class      => 'My2::DB::Object::AB',
          column_map => { id => 'dv_id' },
          type       => 'one to many',
        },

        secs => 
        {
          class      => 'My2::DB::Object::DocumentSecurity',
          column_map => { id => 'document_id' },
          type       => 'one to many',
        },
      ],

    );

    package My2::DB::Object::DocumentSecurity;

    our @ISA = qw(My2::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'ds',

      columns => 
      [
        document_id => { type => 'bigint', not_null => 1 },
        s_id        => { type => 'bigint', not_null => 1 },
      ],

      primary_key_columns => [ 'document_id', 's_id' ],

      foreign_keys => 
      [
        flag => 
        {
          class       => 'My2::DB::Object::SecurityFlag',
          key_columns => { 's_id' => 'id' },
        },
      ],
    );

    package My2::DB::Object::AB;

    our @ISA = qw(My2::DB::Object);

    __PACKAGE__->meta->setup(
      table => 'ab',

      columns => 
      [
        id         => { type => 'bigserial', not_null => 1 },
        battery_id => { type => 'bigint', not_null => 1 },
        dv_id      => { type => 'bigint', not_null => 1 },
      ],

      primary_key_columns => [ 'id' ],

      foreign_key => 
      [
        dv => 
        {
          class       => 'My2::DB::Object::DocumentVersion',
          key_columns => { 'dv_id' => 'id' },
        },
      ],
    );

    package My2::DB::Object::Document;

    our @ISA = qw(My2::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'd',

      columns => 
      [
        id       => { type => 'bigserial', not_null => 1 },
        c_id     => { type => 'bigint',    not_null => 1 },
        pq       => { type => 'varchar',   length   => 255 },
        accid    => { type => 'varchar',   length   => 255 },
        deleted  => { type => 'int',       length   => 1 },
      ],

      primary_key_columns => ['id'],

      unique_key => [ 'c_id', 'pq' ],

      foreign_keys => 
      [
        chart => 
        {
          class       => 'My2::DB::Object::Chart',
          key_columns => { 'c_id' => 'id' },
        },
      ],

      relationships => 
      [
        versions => 
        {
          class        => 'My2::DB::Object::DocumentVersion',
          column_map   => { id => 'document_id' },
          type         => 'one to many',
          manager_args => 
          {
            sort_by => My2::DB::Object::DocumentVersion->meta->table . '.id DESC',
          },
        },

        version => 
        {
          class        => 'My2::DB::Object::DocumentVersion',
          column_map   => { id => 'document_id' },
          type         => 'one to one',
          manager_args => 
          {
            sort_by => My2::DB::Object::DocumentVersion->meta->table . '.id DESC',
            limit   => 1,
          },
        },

        read_status => 
        {
          class      => 'My2::DB::Object::ResultReadStatus',
          column_map => { id => 'document_id' },
          type       => 'one to many',
        }
      ],
    );
  }
}

END
{
  # Delete test tables

  if($Have{'mysql'})
  {
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    local $dbh->{'RaiseError'} = 0;
    local $dbh->{'PrintError'} = 0;
    $dbh->do('SET FOREIGN_KEY_CHECKS = 0');
    $dbh->do('DROP TABLE channel_item_map');
    $dbh->do('DROP TABLE accounts');
    $dbh->do('DROP TABLE channels');
    $dbh->do('DROP TABLE features');
    $dbh->do('DROP TABLE items');

    $dbh->do('DROP TABLE ab');
    $dbh->do('DROP TABLE d');
    $dbh->do('DROP TABLE ds');
    $dbh->do('DROP TABLE dv');

    $dbh->disconnect;
  }
}
