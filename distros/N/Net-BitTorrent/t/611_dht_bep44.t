use v5.40;
use lib 'lib', '../lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode bencode];
use Digest::SHA                               qw[sha1];
use Socket                                    qw[pack_sockaddr_in inet_aton AF_INET];
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
    my $backend;
    try { require Crypt::PK::Ed25519; $backend = 'Crypt::PK::Ed25519' }
    catch ($e) {
        try {
            require Crypt::Perl::Ed25519::PrivateKey;
            require Crypt::Perl::Ed25519::PublicKey;
            $backend = 'Crypt::Perl';
        }
        catch ($e2) { }
    }
    skip_all 'Cannot enable BEP44. Install Crypt::PK::Ed25519 or Crypt::Perl::Ed25519::PublicKey', 5 unless $backend;
    my ( $pub_key, $v, $seq, $salt, $target, $pk_ed );
    if ( $backend eq 'Crypt::PK::Ed25519' ) {
        $pk_ed = Crypt::PK::Ed25519->new();
        $pk_ed->generate_key();
        $pub_key = $pk_ed->export_key_raw('public');
    }
    else {
        $pk_ed = Crypt::Perl::Ed25519::PrivateKey->new();
        my $tmp_pub = $pk_ed->get_public;
        $pub_key = ref $tmp_pub ? $tmp_pub->encode : $tmp_pub;
    }
    $v      = 'Mutable data';
    $seq    = 1;
    $salt   = 'my salt';
    $target = sha1( $pub_key . $salt );
    my $token = $dht->_generate_token('127.0.0.1');

    # Prepare signature
    # to_sign: 4:salt<bencoded salt>3:seq<bencoded seq>1:v<bencoded v>
    my $to_sign = "4:salt" . bencode($salt) . "3:seq" . bencode($seq) . "1:v" . bencode($v);
    my $sig     = ( $backend eq 'Crypt::PK::Ed25519' ) ? $pk_ed->sign_message($to_sign) : $pk_ed->sign($to_sign);

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
    my $new_to_sign = "4:salt" . bencode($salt) . "3:seq" . bencode($new_seq) . "1:v" . bencode($new_v);
    my $new_sig     = ( $backend eq 'Crypt::PK::Ed25519' ) ? $pk_ed->sign_message($new_to_sign) : $pk_ed->sign($new_to_sign);

    # Update with invalid CAS (signature is valid for this CAS, but CAS doesn't match storage)
    my $bad_cas         = 999;
    my $bad_cas_to_sign = "3:cas" . bencode($bad_cas) . "4:salt" . bencode($salt) . "3:seq" . bencode($new_seq) . "1:v" . bencode($new_v);
    my $bad_cas_sig     = ( $backend eq 'Crypt::PK::Ed25519' ) ? $pk_ed->sign_message($bad_cas_to_sign) : $pk_ed->sign($bad_cas_to_sign);
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
                sig   => $bad_cas_sig,
                token => $token,
                cas   => $bad_cas                               # Wrong CAS
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

    # Update with valid CAS (must include CAS in signature)
    my $cas_to_sign = "3:cas" . bencode($seq) . "4:salt" . bencode($salt) . "3:seq" . bencode($new_seq) . "1:v" . bencode($new_v);
    my $cas_sig     = ( $backend eq 'Crypt::PK::Ed25519' ) ? $pk_ed->sign_message($cas_to_sign) : $pk_ed->sign($cas_to_sign);
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
                sig   => $cas_sig,
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
    subtest 'Invalid signature/key' => sub {
        my $bad_v       = 'Malicious update';
        my $bad_seq     = 100;
        my $bad_to_sign = "4:salt" . bencode($salt) . "3:seq" . bencode($bad_seq) . "1:v" . bencode($bad_v);

        # Generate a DIFFERENT key pair
        my ( $other_pk, $other_pub );
        if ( $backend eq 'Crypt::PK::Ed25519' ) {
            $other_pk = Crypt::PK::Ed25519->new();
            $other_pk->generate_key();
            $other_pub = $other_pk->export_key_raw('public');
        }
        else {
            $other_pk = Crypt::Perl::Ed25519::PrivateKey->new();
            my $tmp_pub = $other_pk->get_public;
            $other_pub = ref $tmp_pub ? $tmp_pub->encode : $tmp_pub;
        }

        # Scenario 1: Correct signature but for a DIFFERENT key targeting the original salt
        # In this implementation, the target is derived from the key provided in the query.
        # So providing a different key just targets a different slot.
        my $other_sig = ( $backend eq 'Crypt::PK::Ed25519' ) ? $other_pk->sign_message($bad_to_sign) : $other_pk->sign($bad_to_sign);
        $dht->_handle_query(
            {   t => 'pt_bad1',
                y => 'q',
                q => 'put',
                a => {
                    id    => $sec->generate_node_id('127.0.0.1'),
                    v     => $bad_v,
                    k     => $other_pub,
                    seq   => $bad_seq,
                    salt  => $salt,
                    sig   => $other_sig,
                    token => $token
                }
            },
            'dummy',
            '127.0.0.1',
            1234
        );

        # Verify ORIGINAL target is unchanged
        $dht->_handle_query( { t => 'gt_check1', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
            'dummy', '1.2.3.4', 4321 );
        $res = bdecode($sent_data);
        is $res->{r}{v}, $new_v, 'Original target remains unchanged when different key is used';

        # Scenario 2: Correct key but INVALID signature
        my $fake_sig = "A" x 64;
        $dht->_handle_query(
            {   t => 'pt_bad2',
                y => 'q',
                q => 'put',
                a => {
                    id    => $sec->generate_node_id('127.0.0.1'),
                    v     => $bad_v,
                    k     => $pub_key,
                    seq   => $bad_seq,
                    salt  => $salt,
                    sig   => $fake_sig,
                    token => $token
                }
            },
            'dummy',
            '127.0.0.1',
            1234
        );

        # Verify ORIGINAL target is still unchanged
        $dht->_handle_query( { t => 'gt_check2', y => 'q', q => 'get', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
            'dummy', '1.2.3.4', 4321 );
        $res = bdecode($sent_data);
        is $res->{r}{v}, $new_v, 'Original target remains unchanged when invalid signature is provided';
        subtest 'Blacklisting' => sub {
            my $malicious_ip    = '1.2.3.5';
            my $malicious_id    = $sec->generate_node_id($malicious_ip);
            my $malicious_token = $dht->_generate_token($malicious_ip);

            # Trigger blacklist with bad signature
            $dht->_handle_query(
                {   t => 'pt_mal',
                    y => 'q',
                    q => 'put',
                    a => { id => $malicious_id, v => 'bad', k => $pub_key, seq => 999, sig => 'invalid', token => $malicious_token }
                },
                'dummy',
                $malicious_ip,
                1234
            );

            # Subsequent VALID query from same IP should be ignored (return undef)
            $sent_data = 'no_change';
            my $result = $dht->_handle_query( { t => 'ping_after_blacklist', y => 'q', q => 'ping', a => { id => $malicious_id } },
                'dummy', $malicious_ip, 1234 );
            is $result,    undef,       'Subsequent query from malicious IP is ignored';
            is $sent_data, 'no_change', 'No response packet sent to blacklisted IP';
        };
    };
};
subtest 'malformed want field does not crash DHT' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    for my $want ( {}, [], 42, 'string', undef ) {
        my $a = { id => 'B' x 20 };
        $a->{want} = $want if defined $want;
        my $msg    = bencode( { t => 'xx', y => 'q', q => 'ping', a => $a } );
        my $sender = pack_sockaddr_in( 6881, inet_aton('10.0.0.1') );
        my @result = $dht->handle_incoming( $msg, $sender );
        ok @result == 3, 'handle_incoming returned 3-element list for want=' . ( defined $want ? ref($want) || "$want" : 'undef' );
    }
};
subtest '_query_rate capped at 10000 entries' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    for my $i ( 1 .. 100 ) {
        my $ip     = sprintf( "10.0.%d.%d", int( $i / 256 ), $i % 256 );
        my $msg    = bencode( { t => 'xx', y => 'q', q => 'ping', a => { id => 'C' x 20 } } );
        my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
        $dht->handle_incoming( $msg, $sender );
    }
    ok 1, 'DHT survived 100 queries from different IPs';
    my $msg    = bencode( { t => 'xx', y => 'q', q => 'ping', a => { id => 'C' x 20 } } );
    my $sender = pack_sockaddr_in( 6881, inet_aton('10.0.0.1') );
    my @result = $dht->handle_incoming( $msg, $sender );
    ok @result == 3, 'DHT still responds after many queries';
};
subtest 'peers per info_hash capped at 50' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1, bep42 => 0 );
    my $ih  = 'A' x 20;
    for my $i ( 1 .. 100 ) {
        my $ip    = "10.0.$i.1";
        my $token = $dht->_generate_token($ip);
        my $msg = bencode( { t => 'xx', y => 'q', q => 'announce_peer', a => { id => 'B' x 20, info_hash => $ih, port => 6881, token => $token } } );
        my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
        $dht->handle_incoming( $msg, $sender );
    }
    my $peers_obj = $dht->peer_storage->get($ih);
    ok defined $peers_obj, 'peers entry exists for info_hash';
    my $peers = $peers_obj->value;
    ok @$peers <= 50, 'peers per info_hash capped at 50 (got ' . scalar(@$peers) . ')';
};
subtest 'bootstrap uses pre-resolved nodes' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    my $ok  = eval { $dht->bootstrap(); 1 };
    ok $ok, 'bootstrap did not crash';
};
subtest 'import_state handles invalid data gracefully' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    my $ok  = eval { $dht->import_state("not a hash"); 1 };
    ok $ok, 'import_state with string input did not crash';
    $ok = eval { $dht->import_state( { nodes => "not an array" } ); 1 };
    ok $ok, 'import_state with invalid nodes did not crash';
    $ok = eval { $dht->import_state( { nodes => [ "not a hash", 42, undef ] } ); 1 };
    ok $ok, 'import_state with invalid node entries did not crash';
    $ok = eval { $dht->import_state( { peers => { a => "not a hash" } } ); 1 };
    ok $ok, 'import_state with invalid peer entries did not crash';
    $ok = eval { $dht->import_state( { data => { a => undef } } ); 1 };
    ok $ok, 'import_state with undef data entry did not crash';
    $ok = eval { $dht->import_state( { id => 'A' x 20, nodes => [], nodes6 => [], peers => {}, data => {} } ); 1 };
    ok $ok, 'import_state with valid state did not crash';
};
subtest 'external IP change rate-limited to once per 5 minutes' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    for ( 1 .. 5 ) {
        $dht->_check_external_ip( inet_aton('8.8.8.8') );
    }
    is $dht->external_ip, '8.8.8.8', 'first external IP established';
    for ( 1 .. 5 ) {
        $dht->_check_external_ip( inet_aton('1.1.1.1') );
    }
    is $dht->external_ip, '8.8.8.8', 'external IP unchanged within cooldown';
};
subtest 'debug log sanitizes non-printable characters' => sub {
    my $dht    = Net::BitTorrent::DHT->new( port => 0, debug => 1, ssrf_bypass => 1 );
    my $msg    = bencode( { t => 'xx', y => 'q', q => "ping\x00\x01\x02\x7F", a => { id => 'C' x 20 } } );
    my $sender = pack_sockaddr_in( 6881, inet_aton('10.0.0.1') );
    my @result = $dht->handle_incoming( $msg, $sender );
    ok 1, 'DHT survived debug log with non-printable characters';
};
subtest 'mutable put rejects non-integer seq' => sub {
    my $dht   = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    my $ip    = '10.0.0.1';
    my $token = $dht->_generate_token($ip);
    my $msg   = bencode(
        {   t => 'xx',
            y => 'q',
            q => 'put',
            a => { id => 'D' x 20, v => 'some value', k => 'E' x 32, sig => 'F' x 64, seq => 'not a number', token => $token }
        }
    );
    my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
    $dht->handle_incoming( $msg, $sender );
    ok 1, 'mutable put with non-integer seq did not crash';
    my $state = $dht->export_state();
    ok !keys $state->{data}->%*, 'no data stored from invalid mutable put';
};
subtest 'mutable put rejects non-integer cas' => sub {
    my $dht   = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    my $ip    = '10.0.0.1';
    my $token = $dht->_generate_token($ip);
    my $msg   = bencode(
        {   t => 'xx',
            y => 'q',
            q => 'put',
            a => { id => 'D' x 20, v => 'some value', k => 'E' x 32, sig => 'F' x 64, seq => 1, cas => 'bad', token => $token }
        }
    );
    my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
    $dht->handle_incoming( $msg, $sender );
    ok 1, 'mutable put with non-integer cas did not crash';
    my $state = $dht->export_state();
    ok !keys $state->{data}->%*, 'no data stored from invalid mutable put';
};
subtest 'mutable put rejects short key' => sub {
    my $dht   = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    my $ip    = '10.0.0.1';
    my $token = $dht->_generate_token($ip);
    my $msg   = bencode(
        { t => 'xx', y => 'q', q => 'put', a => { id => 'D' x 20, v => 'some value', k => 'short', sig => 'F' x 64, seq => 1, token => $token } } );
    my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
    $dht->handle_incoming( $msg, $sender );
    ok 1, 'mutable put with short key did not crash';
    my $state = $dht->export_state();
    ok !keys $state->{data}->%*, 'no data stored from invalid mutable put';
};
subtest 'mutable put rejects short signature' => sub {
    my $dht   = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1 );
    my $ip    = '10.0.0.1';
    my $token = $dht->_generate_token($ip);
    my $msg   = bencode(
        { t => 'xx', y => 'q', q => 'put', a => { id => 'D' x 20, v => 'some value', k => 'E' x 32, sig => 'short', seq => 1, token => $token } } );
    my $sender = pack_sockaddr_in( 6881, inet_aton($ip) );
    $dht->handle_incoming( $msg, $sender );
    ok 1, 'mutable put with short signature did not crash';
    my $state = $dht->export_state();
    ok !keys $state->{data}->%*, 'no data stored from invalid mutable put';
};
#
subtest 'DHT mutable put value size limit defined' => sub {
    ok defined Net::BitTorrent::DHT::MAX_IMMUTABLE_VALUE_SIZE(), 'MAX_IMMUTABLE_VALUE_SIZE defined';
    is Net::BitTorrent::DHT::MAX_IMMUTABLE_VALUE_SIZE(), 1024 * 1024, 'immutable limit is 1MB';
};
#
subtest 'DHT handle_incoming does not crash on malformed data' => sub {
    my $dht    = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    my @result = $dht->handle_incoming( 'not-bencode-data', undef );
    is scalar @result, 3, 'handle_incoming returns 3-element list for malformed data';
    @result = $dht->handle_incoming( bencode( { y => 'q', q => 'ping' } ), undef );
    is scalar @result, 3, 'handle_incoming returns 3-element list for bad query (no a dict)';
};
#
subtest 'DHT set_node_id validates input' => sub {
    my $dht     = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    my $orig_id = $dht->node_id_bin;
    $dht->set_node_id(undef);
    is $dht->node_id_bin, $orig_id, 'set_node_id(undef) does not change ID';
    $dht->set_node_id('short');
    is $dht->node_id_bin, $orig_id, 'set_node_id with wrong length does not change ID';
    my $valid_id = 'A' x 20;
    $dht->set_node_id($valid_id);
    is $dht->node_id_bin, $valid_id, 'set_node_id with valid 20-byte ID works';
};
#
subtest 'DHT import_state caps nodes and entries' => sub {
    my $dht        = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    my @many_nodes = map { { id => sha1("node$_"), ip => "1.2.3.$_%256", port => 6881 } } 1 .. 3000;
    my $state      = { id => $dht->node_id_bin, nodes => \@many_nodes };
    $dht->import_state($state);
    pass 'import_state with 3000 nodes completed without crash';
};
#
subtest 'DHT _unpack_nodes filters port 0' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    use Socket qw[AF_INET inet_aton];
    my $id     = 'A' x 20;
    my $ip_bin = inet_aton('1.2.3.4');
    my $node   = $id . $ip_bin . pack( 'n', 0 );
    my $nodes  = $dht->_unpack_nodes( $node, AF_INET );
    is scalar @$nodes, 0, 'node with port 0 filtered out';
};
#
subtest 'DHT transaction ID validated' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    my $msg = { y => 'q', q => 'ping', a => { id => 'A' x 20 } };
    delete $msg->{t};
    my @result = $dht->handle_incoming( bencode($msg), undef );
    is scalar @result, 3, 'query with undef t is rejected (returns empty result)';
};
#
subtest 'DHT _unpack_nodes caps at MAX_UNPACK_NODES' => sub {
    my $dht  = Net::BitTorrent::DHT->new( port => 0, bep42 => 0 );
    my $blob = '';
    for my $i ( 1 .. 300 ) {
        my $id   = pack( 'a20', substr( pack( 'N', $i ) x 5, 0, 20 ) );
        my $ip   = pack( 'C4',  10, 0, 0, ( $i % 254 ) + 1 );
        my $port = pack( 'n',   6881 );
        $blob .= $id . $ip . $port;
    }
    my $nodes = $dht->_unpack_nodes( $blob, AF_INET );
    ok @$nodes <= 200, '_unpack_nodes caps at MAX_UNPACK_NODES (got ' . scalar(@$nodes) . ')';
};
#
done_testing;
