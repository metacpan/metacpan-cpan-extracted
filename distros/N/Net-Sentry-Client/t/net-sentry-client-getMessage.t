use Test::More;
use Test::Fatal;
use Test::JSON;

use Net::Sentry::Client;

subtest 'Making a params' => sub {
    plan tests => 1;
    my $params = {
        message     => 'test'
    };
    ok ( $params->{uuid} = Data::UUID::MT->new->create_hex(), 'new uuid' );
};

subtest 'Making JSON' => sub {
    plan tests => 3;
    my $params = {
        message     => 'test'
    };
    isnt ( $params, undef, '$params not undef' );
    ok ( my $json = JSON->new->utf8(1)->pretty(1)->allow_nonref(1)->encode( $params ), 'new json with params' );
    is_valid_json $json, 'json is well formed';
};

subtest 'Compress' => sub {
    plan tests => 3;
    my $params = {
        message     => 'test'
    };
    my $json = JSON->new->utf8(1)->pretty(1)->allow_nonref(1)->encode( $params );
    is_valid_json $json, 'encoded json is well formed';
    ok ( $json = Compress::Zlib::compress($json), 'new json compress');
    ok ( my $json_encode = MIME::Base64::encode_base64($json), 'new json compressed and in base64' );
};

done_testing();

