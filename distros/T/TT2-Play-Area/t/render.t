use Test2::V0;

use Cpanel::JSON::XS;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use TT2::Play::Area;

my $test = Plack::Test->create( TT2::Play::Area->to_app );

subtest 'Main page' => sub {
    ok my $res = $test->request( GET '/' );
    like $res->decoded_content, qr'Welcome to the Template::Toolkit play area';
    ok $res->is_success;
};

subtest 'Example' => sub {
    ok my $res = $test->request( GET '/example/json' );
    like $res->decoded_content, qr'JSON plugin';
    ok $res->is_success;
};

subtest '404' => sub {
    ok my $res = $test->request( GET '/404' );
    ok !$res->is_success;
};

subtest variable_error => sub {
    ok my $res = test_post( variable_json => '{bad_json' );
    like decode_json( $res->decoded_content ),
      { result => { 'Error' => qr'Failed to parse variables:' } };
    ok $res->is_success;
};

subtest missing_plugin => sub {
    ok my $res = test_post( template => '[% USE Missing; %]' );
    like decode_json( $res->decoded_content ),
      { result => { 'TT2' => qr'plugin not found' } };
    ok $res->is_success;
};

subtest all_engines => sub {
    ok my $res = test_post( engines => [ 'tt2', 'alloy', 'alloy_html' ] );
    is decode_json( $res->decoded_content ),
      {
        result => {
            'TT2'                                  => '1',
            'Template::Alloy'                      => '1',
            'Template::Alloy + AUTO_FILTER = html' => '1',
        }
      };
    ok $res->is_success;
};

sub test_post {
    my %args = @_;

    $args{engines}   //= ['tt2'];
    $args{variables} //= { a => 1, b => 2 };
    $args{template}  //= '[% a | html %]';

    my $engines = join( '&', map { 'engine=' . $_ } @{ $args{engines} // [] } );
    my $variable_json = $args{variable_json} // encode_json( $args{variables} );
    my $post = POST(
        "/tt2?$engines",
        Content => {
            template => $args{template} // '',
            vars => $variable_json,
        }
    );
    return $test->request($post);
}

done_testing;
