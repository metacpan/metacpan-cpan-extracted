use 5.014;
use File::Temp;
use Test::Most;
use Mojo::JSON;
use Mojo::UserAgent::Mockable::Serializer;
use Mojo::UserAgent;

package TestApp {
    use Mojolicious::Lite;
    get '/foo' => sub {
        shift->render( text => 'OK' );
    };
};
my $app = TestApp::app;

my $serializer = Mojo::UserAgent::Mockable::Serializer->new;
my $tx = $app->ua->get('/foo');
my %events;
$tx->on(
    pre_freeze => sub {
        my ($txn) = @_;
        isa_ok( $txn, 'Mojo::Transaction::HTTP' );
        $events{'pre_freeze'} = 1;
    }
);
$tx->req->on(
    pre_freeze => sub {
        my ($req) = @_;
        isa_ok( $req, 'Mojo::Message::Request' );
        $events{'req_pre_freeze'} = 1;
    }
);
$tx->req->on(
    post_freeze => sub {
        my ($req) = @_;
        isa_ok( $req, 'Mojo::Message::Request' );
        $events{'req_post_freeze'} = 1;
    }
);
$tx->on(
    post_freeze => sub {
        my ( $txn, $slush ) = @_;
        isa_ok( $txn, 'Mojo::Transaction::HTTP' );
        is ref $slush, 'HASH', 'slush is a hashref';
        is $slush->{'class'}, 'Mojo::Transaction::HTTP', 'Class correct';
        $events{'post_freeze'} = 1;
    }
);
$tx->res->on(
    pre_freeze => sub {
        my ($res) = @_;
        isa_ok( $res, 'Mojo::Message::Response' );
        $events{'res_pre_freeze'} = 1;
    }
);
$tx->res->on(
    post_freeze => sub {
        my ($res) = @_;
        isa_ok( $res, 'Mojo::Message::Response' );
        $events{'res_post_freeze'} = 1;
    }
);
$tx->on(
    resume => sub {
        $events{'resume'} = 1;
    }
);
my $serialized;
lives_ok { $serialized = $serializer->serialize($tx); } 'Serialize() did not die';
$tx = undef;
my $decoded = Mojo::JSON::decode_json($serialized);

my @transaction_events = @{$decoded->[0]{'events'}} if defined $decoded->[0]{'events'};

$serializer->on(
    pre_thaw => sub {
        my ( $serializer, $slush ) = @_;
        isa_ok( $serializer, 'Mojo::UserAgent::Mockable::Serializer' );
        is ref $slush, 'ARRAY', 'slush is an arrayref';
        $events{'pre_thaw'} = 1;
    }
);
$serializer->on(
    post_thaw => sub {
        my ( $serializer, $transactions, $slush ) = @_;
        isa_ok( $serializer, 'Mojo::UserAgent::Mockable::Serializer' );
        is ref $transactions, 'ARRAY', q{transactions in arrayref};
        is ref $slush,        'ARRAY',  'slush is an arrayref';
        $events{'post_thaw'} = 1;
    }
);

($tx) = $serializer->deserialize( $serialized);

my @expected_events = qw/
    pre_thaw        post_thaw       pre_freeze      post_freeze
    req_pre_freeze  req_post_freeze res_pre_freeze  res_post_freeze
    /;
push @expected_events, @transaction_events;

for my $event (@expected_events) {
    if ($event eq 'resume') {
        TODO: { 
            local $TODO = 'Events at individual transaction level not yet supported';
            is $events{$event}, 1, qq{Event "$event" fired};
        };
        next;
    }
    is $events{$event}, 1, qq{Event "$event" fired};
}
done_testing;
