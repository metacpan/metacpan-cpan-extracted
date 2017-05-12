use 5.016;

use Mojo::Util qw/slurp/;
use File::Temp;
use FindBin qw($Bin);
use Mojo::IOLoop;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

my $COUNT         = 5;
my $MIN           = 0;
my $MAX           = 100;
my $COLS          = 1;
my $BASE          = 10;

my $url = Mojo::URL->new(q{https://www.random.org/integers/})->query(
    num    => $COUNT,
    min    => $MIN,
    max    => $MAX,
    col    => $COLS,
    base   => $BASE,
    format => 'plain',
);

my $delay = Mojo::IOLoop->delay;
my @transactions;
my $transaction_count = 10;
my @steps;

my @urls = map { $url->clone->query( [ quux => int rand 100, count => $_ ] ) } ( 1 .. $transaction_count );

for ( 0 .. $transaction_count ) {
    my $count = $_;
    my $url = shift @urls;
    say qq{Push TX $count: $url};

    push @steps, sub {
        say qq{Step $count};
        my ($delay, $tx) = @_;
        $ua->get($url, $delay->begin) if $url;
        die $tx unless ref $tx;
        next unless ref $tx;
        say qq{Got TX $count: $url};
        my $code = $tx->res->code;
        say qq{Responded $code};
        push @transactions, $tx;
    };
}

my $error;
say scalar @steps, q{ steps};
$delay->steps(@steps);
$delay->data( mock => $ua );
Mojo::IOLoop->client( { port => 3000 } => $delay->begin );
#$delay->on( error => sub { my ( $e, $err ) = @_; die qq{Caught error: $err}; } );
$delay->catch( sub { my ( $delay, $err ) = @_; $error = "Caught error, buddy: $err"; } );
$delay->wait;

warn qq{Oh shit. $error} if $error;
say q{Got }, scalar @transactions, q{ transactions};
say ref $_ ? $_->req->url : $_ for @transactions;
