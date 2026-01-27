use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode bencode];
use Digest::SHA                               qw[sha1];
#
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, bep44 => 1, port => 0 );

# Mock _send_raw
my $sent_data;
no warnings 'redefine';
local *Net::BitTorrent::DHT::_send_raw = sub {
    my ( $self, $data, $dest ) = @_;
    $sent_data = $data;
};

#~ use warnings 'redefine';
subtest 'Immutable data' => sub {
    my $v      = 'Hello, world!';
    my $target = sha1($v);
    my $token  = $dht->_generate_token('127.0.0.1');

    # Store immutable data
    $dht->_handle_query( { t => 'pt1', y => 'q', q => 'put', a => { id => $sec->generate_node_id('127.0.0.1'), v => $v, token => $token } },
        'dummy', '127.0.0.1', 1234 );

    # Retrieve immutable data
    $sent_data = undef;
    $dht->_handle_query( { t => 'gt1', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
        'dummy', '1.2.3.4', 4321 );
    my $res = bdecode($sent_data);
    is $res->{r}{v}, $v, 'Retrieved correct immutable value';
};
subtest 'Mutable data' => sub {
    skip_all 'Cannot enable BEP44. Install Crypt::PK::Ed25519 or Crypt::Perl::Ed25519::PublicKey', 5
        unless eval { require Crypt::PK::Ed25519; 1 } || eval { require Crypt::Perl::Ed25519::PublicKey; 1 };
    my $pk_ed = Crypt::PK::Ed25519->new();
    $pk_ed->generate_key();
    my $pub_key  = $pk_ed->export_key_raw('public');
    my $priv_key = $pk_ed->export_key_raw('private');
    my $v        = 'Mutable data';
    my $seq      = 1;
    my $salt     = 'my salt';
    my $target   = sha1( $pub_key . $salt );
    my $token    = $dht->_generate_token('127.0.0.1');

    # Prepare signature
    # to_sign: salt<len>:<salt>seqi<seq>ev<len>:<v>
    my $to_sign = 'salt' . length($salt) . ':' . $salt . 'seqi' . $seq . 'ev' . length($v) . ':' . $v;
    my $sig     = $pk_ed->sign_message($to_sign);

    # Store mutable data
    $dht->_handle_query(
        {   t => 'pt2',
            y => 'q',
            q => 'put',
            a => { id => $sec->generate_node_id('127.0.0.1'), v => $v, k => $pub_key, seq => $seq, salt => $salt, sig => $sig, token => $token }
        },
        'dummy',
        '127.0.0.1',
        1234
    );

    # Retrieve mutable data
    $sent_data = undef;
    $dht->_handle_query( { t => 'gt2', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
        'dummy', '1.2.3.4', 4321 );
    my $res = bdecode($sent_data);
    is $res->{r}{v},   $v,       'Retrieved correct mutable value';
    is $res->{r}{seq}, $seq,     'Retrieved correct sequence number';
    is $res->{r}{k},   $pub_key, 'Retrieved correct public key';

    # Test CAS and Sequence validation
    my $new_v       = 'Updated data';
    my $new_seq     = 2;
    my $new_to_sign = 'salt' . length($salt) . ':' . $salt . 'seqi' . $new_seq . 'ev' . length($new_v) . ':' . $new_v;
    my $new_sig     = $pk_ed->sign_message($new_to_sign);

    # Update with invalid CAS
    $dht->_handle_query(
        {   t => 'pt3',
            y => 'q',
            q => 'put',
            a => {
                id    => $sec->generate_node_id('127.0.0.1'),
                v     => $new_v,
                k     => $pub_key,
                seq   => $new_seq,
                salt  => $salt,
                sig   => $new_sig,
                token => $token,
                cas   => 999                                    # Wrong CAS
            }
        },
        'dummy',
        '127.0.0.1',
        1234
    );

    # Verify NOT updated
    $dht->_handle_query( { t => 'gt3', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
        'dummy', '1.2.3.4', 4321 );
    $res = bdecode($sent_data);
    is $res->{r}{v}, $v, 'Value not updated due to invalid CAS';

    # Update with valid CAS
    $dht->_handle_query(
        {   t => 'pt4',
            y => 'q',
            q => 'put',
            a => {
                id    => $sec->generate_node_id('127.0.0.1'),
                v     => $new_v,
                k     => $pub_key,
                seq   => $new_seq,
                salt  => $salt,
                sig   => $new_sig,
                token => $token,
                cas   => $seq                                   # Valid CAS
            }
        },
        'dummy',
        '127.0.0.1',
        1234
    );

    # Verify updated
    $dht->_handle_query( { t => 'gt4', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
        'dummy', '1.2.3.4', 4321 );
    $res = bdecode($sent_data);
    is $res->{r}{v}, $new_v, 'Value updated correctly with valid CAS';
};
#
done_testing;
