use 5.014;

use File::Temp;
use FindBin qw($Bin);
use lib qq{$Bin/lib};
use Mojo::UserAgent::Mockable;
use RandomOrgQuota qw/check_quota/;
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

my %args = @_;

my $dir = File::Temp->newdir;

my $url = Mojo::URL->new(q{https://www.random.org/integers/})->query(
    num    => $COUNT,
    min    => $MIN,
    max    => $MAX,
    col    => $COLS,
    base   => $BASE,
    format => 'plain',
);
my $app = $args{'app'};

my $output_file = qq{$dir/output.json};

my $transaction_count = 10;
my %cookies;
my $cookie_count = 0;
# Record the interchange
my ( @results, @transactions );
{    # Look! Scoping braces!
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'record', file => $output_file );
    $mock->transactor->name('kit.peters@broadbean.com');

    for ( 1 .. $transaction_count ) {
        plan skip_all => 'Random.org quota exceeded' unless check_quota();
        push @transactions, $mock->get( $url->clone->query( [ quux => int rand 1e9 ] ));
    }

    for my $cookie (@{$mock->cookie_jar->all}) {
        $cookie_count++;
        my $domain = $cookie->domain;
        my $name = $cookie->name;
        BAIL_OUT(qq{Duplicate cookie "$name" for domain "$domain"}) if ($cookies{$domain}{$name}); 
        $cookies{$domain}{$name} = $cookie;
    }
    @results = map { [ split /\n/, $_->res->text ] } @transactions;

    plan skip_all => 'Remote not responding properly'
        unless ref $results[0] eq 'ARRAY' && scalar @{ $results[0] } == $COUNT;
    $mock->save;
}

subtest "Check that the file was recorded in a nice clean format" => sub {
    open(my $mocks_fh, '<', $output_file) || BAIL_OUT('Output file does not exist');
    foreach my $expected (
        '[',
        '   {',
        '      "class" : "Mojo::Transaction::HTTP",',
        '      "request" : {',
        qr/^         "body" : "GET.*/,
        '         "class" : "Mojo::Message::Request",',
        '         "url" : {',
        '            "host" : "www.random.org",',
        '            "path" : "/integers/",',
        qr/^            "query" : "num=5&min=0&max=1000000000&col=1&base=10&format=plain&quux=\d+",/,
        '            "scheme" : "https"',
        '         }',
        '      },',
    ) {
        chomp(my $this_line = <$mocks_fh>);
        ref($expected) ? like($this_line, $expected, $this_line)
                       :   is($this_line, $expected, $this_line);
    }
};

my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file );
$mock->transactor->name('kit.peters@broadbean.com');

my @mock_results;
my @mock_transactions;

# my $t = Test::Mojo->new;
for ( 0 .. $#transactions ) {
    my $transaction = $transactions[$_];
    my $result      = $results[$_];

    my $url = $transaction->req->url->clone; 
    my $mock_transaction = $mock->get( $url );
    my $mock_result      = [ split /\n/, $mock_transaction->res->text ];
    my $mock_headers     = $mock_transaction->res->headers->to_hash;
    is $mock_headers->{'X-MUA-Mockable-Regenerated'}, 1, 'X-MUA-Mockable-Regenerated header present and correct';
    delete $mock_headers->{'X-MUA-Mockable-Regenerated'};
    
    # $t->get_ok( $transaction->req->url->clone )->header_is( 'X-MUA-Mockable-Regenerated' => 1 );
    # my $tx = $t->tx;
    # my $mock_headers = $tx->res->headers->to_hash;
    # my $mock_result = [ split /\n/, $tx->res->text ];
    # delete $mock_headers->{'X-MUA-Mockable-Regenerated'};

    is_deeply( $mock_result, $result, q{Result correct} );
    is_deeply( $mock_headers, $transaction->res->headers->to_hash, q{Response headers correct} );
}

is scalar @{$mock->cookie_jar->all}, $cookie_count, 'Cookie count correct';
for my $cookie (@{$mock->cookie_jar->all}) {
    my $domain = $cookie->domain;
    my $name = $cookie->name;
    my $original_cookie = $cookies{$domain}{$name};
    subtest qq{Cookie "$name"} => sub {
        for my $attr (qw/domain httponly max_age path secure/) {
            is $cookie->$attr, $original_cookie->$attr, qq{"$attr" matches};
        }

        # If "max_age" is set, "expires" is re-calculated, so isn't
        # expected to be the same as the previous value
        my $expires = $cookie->expires;
        if ( my $max_age = $cookie->max_age ) {
            my $margin = 5; # account for slow test runs
            my $new_expires = time() + $max_age - $margin;
            cmp_ok(
                $expires, ">=", $new_expires,
                qq{"expires" is re-calculated from current time: $expires >= $new_expires},
            );
        }
        else {
            is $expires, $original_cookie->expires, qq{"expires" matches};
        }
    };
}

subtest 'null on unrecognized' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'null' );

    my $t = Test::Mojo->new;
    $t->ua($mock);
    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];
        lives_ok { $t->get_ok($transaction->req->url->clone)->status_is(200)->content_is('') } qq{GET did not die (TXN $index)};
    }
};

subtest 'exception on unrecognized' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'exception' );

    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];

        throws_ok { $mock->get( $transaction->req->url->clone ) } qr/^Unrecognized request: URL query mismatch/;
    }
};

subtest 'fallback on unrecognized' => sub {
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => $output_file, unrecognized => 'fallback' );

    for ( 0 .. ($#transactions - 1) ) {
        my $index       = $#transactions - $_;
        my $transaction = $transactions[$index];
        my $result      = $results[$index];

        my $tx;
        lives_ok { $tx = $mock->get( $transaction->req->url->clone ) } q{GET did not die};
        my $mock_result = [ split /\n/, $tx->res->text ];
        is scalar @{$mock_result}, scalar @{$result}, q{Result counts match};
        for ( 0 .. $#{$result} ) {
            isnt $mock_result->[$_], $result->[$_], qq{Result $_ does NOT match};
        }
    }
};

done_testing;
