use 5.014;

use File::Temp;
use FindBin qw($Bin);
use lib qq{$Bin/lib};
use RandomOrgQuota qw/check_quota/;
use Mojo::UserAgent::Mockable;
use Test::Most;
use Test::Mojo;

my $ver;
eval {
    require IO::Socket::SSL;
    $ver = $IO::Socket::SSL::VERSION;
    1;
} or plan skip_all => 'IO::Socket::SSL not installed';

plan skip_all => qq{Minimum version of IO::Socket::SSL is 1.94 for this test, but you have $ver} if $ver < 1.94;


my $TEST_FILE_DIR = qq{$Bin/files};
my $COUNT         = 5;
my $MIN           = 0;
my $MAX           = 1e9;
my $COLS          = 1;
my $BASE          = 10;

my $dir = File::Temp->newdir;

my $url = Mojo::URL->new(q{https://www.random.org/integers/})->query(
    num    => $COUNT,
    min    => $MIN,
    max    => $MAX,
    col    => $COLS,
    base   => $BASE,
    format => 'plain',
);
my $output_file = qq{$dir/output_normalized.json};
my $transaction_count = 10;
plan skip_all => 'Random.org quota exceeded' unless check_quota($transaction_count);

note "Record the interchange";
my ( @results, @transactions );
{    # Look! Scoping braces!
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'record', file => $output_file );
    $mock->transactor->name('kit.peters@broadbean.com');

    for ( 1 .. $transaction_count ) {
        push @transactions, $mock->get( $url->clone->query( [ quux => int rand 1e9 ] ));
    }
    @results = map { [ split /\n/, $_->res->text ] } @transactions;

    plan skip_all => 'Remote not responding properly'
        unless ref $results[0] eq 'ARRAY' && scalar @{ $results[0] } == $COUNT;
    $mock->save;
}

BAIL_OUT('Output file does not exist') unless ok(-e $output_file, 'Output file exists');

my $request_normalizer_sub = sub {
    my ($req, $recorded_req) =  @_;
    for ($req, $recorded_req) {
        $_->url->query( quux => 1 );
    }
};

my $mock = Mojo::UserAgent::Mockable->new(
    mode               => 'playback',
    file               => $output_file,
    unrecognized       => 'exception',
    request_normalizer => $request_normalizer_sub,
);
note "Replay in reverse order, and ignore the request url query param quux";
for ( 0 .. $#transactions ) {
    my $transaction = $transactions[$#transactions - $_];
    my $result      = $results[$_];

    my $mock_transaction = $mock->get( $transaction->req->url->clone );

    my $mock_result      = [ split /\n/, $mock_transaction->res->text ];
    is_deeply( $mock_result, $result, q{Result correct} );
}

done_testing;
