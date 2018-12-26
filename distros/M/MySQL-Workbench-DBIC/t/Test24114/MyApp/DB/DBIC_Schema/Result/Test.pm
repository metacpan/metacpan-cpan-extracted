package MyApp::DB::DBIC_Schema::Result::Test;

# ABSTRACT: Result class for Test

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core PassphraseColumn/ );
__PACKAGE__->table( 'Test' );
__PACKAGE__->add_columns(
    test_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    passphrase => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
        'passphrase' => 'rfc2307',
        'passphrase_args' => {
          'algorithm' => 'SHA-1',
          'salt_random' => 20
        },
        'passphrase_check_method' => 'check_passphrase',
        'passphrase_class' => 'SaltedDigest'
    },
    another_phrase => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
    },

);
__PACKAGE__->set_primary_key( qw/ test_id / );






# ---
# Put your own code below this comment
# ---

# ---

1;