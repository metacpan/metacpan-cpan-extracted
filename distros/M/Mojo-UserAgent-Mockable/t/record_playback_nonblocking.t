use 5.014;

use File::Temp;
use FindBin qw($Bin);
use lib qq{$Bin/lib};
use RandomOrgQuota qw/check_quota/;
use Mojo::URL;
use Mojo::IOLoop;
use Mojo::UserAgent::Mockable;
use Test::Most;

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

my $output_file = qq{$dir/output.json};

my $transaction_count = 10;
plan skip_all => 'Random.org quota exceeded' unless check_quota($transaction_count);

# Record the interchange
my ( @results, @transactions );
{    # Look! Scoping braces!
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'record', file => $output_file );
    $mock->transactor->name('kit.peters@broadbean.com');

    for (1 .. $transaction_count) {
        $mock->get(
            $url->clone->query( [ quux => int rand 1e9 ] ),
            sub {
                my ( $ua, $tx ) = @_;
                push @transactions, $tx;
                Mojo::IOLoop->stop;
            }
        );
        Mojo::IOLoop->start;
    }

    Mojo::IOLoop->start;

    $mock->save;

    @results = map { [ split /\n/, $_->res->text ] } @transactions;
    BAIL_OUT('Did not get all transactions') unless scalar @results == $transaction_count;
}

BAIL_OUT('Output file does not exist') unless ok(-e $output_file, 'Output file exists');

my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file );
$mock->transactor->name('kit.peters@broadbean.com');

my @mock_results;
my @mock_transactions;

for ( 0 .. ($#transactions - 1)) {
    my $transaction = $transactions[$_];
    my $result      = $results[$_];

    lives_ok {
        $mock->get(
            $transaction->req->url->clone,
            sub {
                my ( $ua, $tx ) = @_;
                my $mock_result = [ split /\n/, $tx->res->text ];
                is $tx->res->headers->header('X-MUA-Mockable-Regenerated'), 1,
                    'X-MUA-Mockable-Regenerated header present and correct';
                my $headers = $tx->res->headers->to_hash;
                delete $headers->{'X-MUA-Mockable-Regenerated'};
                is_deeply( $mock_result, $result, q{Result correct} );
                is_deeply( $headers, $transaction->res->headers->to_hash, q{Response headers correct} );
                Mojo::IOLoop->stop;
            }
        );
    }
    qq{GET did not die (TXN $_)};
    Mojo::IOLoop->start;
}

subtest 'null on unrecognized (nonblocking)' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'null' );

    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];

        lives_ok {
            $mock->get(
                $transaction->req->url->clone,
                sub {
                    my ( $ua, $tx ) = @_;
                    is $tx->res->text, '', qq{Request out of order returned null (TXN $index)};
                    Mojo::IOLoop->stop;
                }
            );
        }
        qq{GET did not die (TXN $index)};
        Mojo::IOLoop->start;
    }
};

subtest 'exception on unrecognized (nonblocking)' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'exception' );

    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];

        throws_ok {
            $mock->get( 
                $transaction->req->url->clone, 
                sub { 
                    Mojo::IOLoop->stop;
                } 
            )
        }
        qr/^Unrecognized request: URL query mismatch/;
    }
};

subtest 'fallback on unrecognized (nonblocking)' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'fallback' );

    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];
        my $result      = $results[$index];

        lives_ok {
            $mock->get(
                $transaction->req->url->clone,
                sub {
                    my ($ua, $tx) = @_;
                    my $mock_result = [ split /\n/, $tx->res->text ];
                    is scalar @{$mock_result}, scalar @{$result}, q{Result counts match};
                    for ( 0 .. $#{$result} ) {
                        isnt $mock_result->[$_], $result->[$_], qq{Result $_ does NOT match};
                    }
                    Mojo::IOLoop->stop;
                }
            );
        }
        qq{GET did not die (TXN $index)};
        Mojo::IOLoop->start;
    }
};

done_testing;
