use 5.014;
use File::Temp;
use Test::Most;
use Test::JSON;
use Mojo::JSON;
use Mojo::Message::Request;
use Mojo::Message::Response;
use Mojo::UserAgent::Mockable::Serializer;
use Mojo::UserAgent::Mockable::Request::Compare;
use Path::Tiny;
use FindBin qw($Bin);
use lib qq{$Bin/../lib};
use RandomOrgQuota qw/check_quota/;

package LocalApp {
    use Mojolicious::Lite;
    my $app = Mojolicious->new;

    get '/records' => sub {
        my $c = shift;
        $c->render(
            json => {
                meta    => { count => 1, },
                records => [
                    {   id            => 8675309,
                        author        => 'Tommy Tutone',
                        subject       => 'Jenny',
                        repercussions => 'Many telephone companies now refuse to give out the number '  #
                                         . '"867-5309".  People named "Jenny" have come to despise this song. ' #
                                         . 'Mr. Tutone made out well.',
                    }
                ],
            }
        );
    };
    get '/record/:id' => sub {
            my $c  = shift;
            my $id = $c->stash('id');
            if ( $id eq '8675309' ) {
                $c->render(
                    json => [
                        {   id            => 8675309,
                            author        => 'Tommy Tutone',
                            subject       => 'Jenny',
                            repercussions => 'Many telephone companies now refuse to give out the number ' 
                                            . '"867-5309".  People named "Jenny" have come to despise this song. ' 
                                            . 'Mr. Tutone made out well.',
                            summary       => 'The singer wonders who he can turn to, and recalls Jenny, who he feels ' 
                                            . 'gives him something that he can hold on to.  He worries that she will ' 
                                            . 'think that he is like other men who have seen her name and number written ' 
                                            . 'upon the wall, but persists in calling her anyway. In his heart, the ' 
                                            . 'singer knows that Jenny is the girl for him.',
                        }
                    ]
                );
            }
    };
};

package LocalRandomApp {
    use Mojolicious::Lite;
    get '/integers' => sub {
        my $c     = shift;
        my $count = $c->req->param('num') || 1;
        my $min   = $c->req->param('min') || 0;
        my $max   = $c->req->param('max') || 1e9;
        my $cols  = $c->req->param('cols') || 1;

        my @nums;
        for ( 0 .. ( $count - 1 ) ) {
            my $number = ( int rand( $max - $min ) ) + $min;
            push @nums, $number;
        }

        $c->render( text => join qq{\n}, @nums );
    };
}

my $serializer = Mojo::UserAgent::Mockable::Serializer->new;

subtest 'Victoria and Albert Museum' => sub {
    my $dir = File::Temp->newdir;
    my $output_file = qq{$dir/victoria_and_albert.json};

    my @transactions;
    push @transactions, Mojo::UserAgent->new->get(q{https://www.vam.ac.uk/api/json/museumobject/?limit=1});

    my $result = $transactions[0]->res->json;

    plan skip_all => 'Museum API not responding properly' unless ref $result eq 'HASH' && $result->{'meta'};
    plan skip_all => 'No records returned' unless @{$result->{'records'}};

    my $object_number = $result->{'records'}[0]{'fields'}{'object_number'};

    push @transactions, Mojo::UserAgent->new->get(qq{https://www.vam.ac.uk/api/json/museumobject/$object_number});
    my $museum_object = $transactions[1]->res->json;

    plan skip_all => 'Museum object not retrieved properly' unless @{$museum_object} && keys %{$museum_object->[0]};

    test_transactions($output_file, @transactions);
};

subtest 'Local App' => sub {
    my $dir = File::Temp->newdir;
    my $output_file = qq{$dir/local_app.json};

    my $app = LocalApp::app;
    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);

    my $url = $ua->server->url->clone->path('/records');
    my @transactions = $ua->get($url);

    my $records = $transactions[0]->res->json;
    my $record_id = $records->{'records'}[0]{'id'};
    push @transactions,  $ua->get($url->clone->path(qq{/record/$record_id}));
    my $record = $transactions[1]->res->json;

    BAIL_OUT('Local app did not serve records correctly') unless $transactions[1]->res->json->[0]{'author'} eq 'Tommy Tutone';

    test_transactions($output_file, @transactions);
};

subtest 'random.org' => sub { 
    my $ver;
    eval { 
        require IO::Socket::SSL; 
        $ver = $IO::Socket::SSL::VERSION; 
        1;
    } or plan skip_all => 'IO::Socket::SSL not installed';

    plan skip_all => qq{Minimum version of IO::Socket::SSL is 1.94 for this test, but you have $ver} if $ver < 1.94;
    plan skip_all => 'Random.org quota exceeded' unless check_quota();

    my $dir = File::Temp->newdir;
    my $output_file = qq{$dir/random_org.json};

    my $url = Mojo::URL->new( q{https://www.random.org/integers/} )->query(
        num    => 5,
        min    => 0,
        max    => 1e9,
        col    => 1,
        base   => 10,
        format => 'plain',
    );

    my $ua = Mojo::UserAgent->new;
    my @transactions = ($ua->get($url), $ua->get($url));

    test_transactions($output_file, @transactions);
};

subtest 'URL bits' => sub {
    my $dir = File::Temp->newdir;
    my $output_file = qq{$dir/local_random.json};

    my $app = LocalRandomApp::app;
    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);

    my $url = Mojo::URL->new( $ua->server->url('https')->clone->path('/integers') )->query(
        num    => 5,
        min    => 0,
        max    => 1e9,
        col    => 1,
        base   => 10,
        format => 'plain',
    )->userinfo('nobody:nohow');

    my @transactions = ($ua->get($url), $ua->get($url));
    test_transactions($output_file, @transactions);
};

done_testing;

sub test_transactions {
    my ($output_file, @transactions) = @_;

    lives_ok { $serializer->store($output_file, @transactions) } q{serialize() did not die};

    my $serialized = path($output_file)->slurp_raw;
    is_valid_json($serialized, q{Serializer outputs valid JSON});

    my $decoded = Mojo::JSON::decode_json($serialized);

    is ref $decoded, 'ARRAY', q{Transactions serialized as array};
    for (0 .. $#transactions) {
        for my $key (qw/request response/) {
            ok defined($decoded->[$_]{$key}), qq{Key "$key" defined in serial data};
            for my $subkey (qw/class body/) {
                ok defined($decoded->[$_]{$key}{$subkey}), qq{Key "$subkey" defined in "$key" data};
            }
            if ($key eq 'request') {
                ok defined($decoded->[$_]{$key}{'url'}), qq{Key "url" defined in "$key" data};
            }
            my $expected_class = sprintf 'Mojo::Message::%s', ucfirst $key;
            is $decoded->[$_]{$key}{'class'}, $expected_class, qq{"$key" class correct};
        }
    }

    my @deserialized = $serializer->retrieve($output_file);
    for (0 .. $#transactions) {
        my $deserialized_tx = $deserialized[$_];
        my $tx = $transactions[$_];

        my $comparator = Mojo::UserAgent::Mockable::Request::Compare->new;
        if (!ok $comparator->compare($deserialized_tx->req, $tx->req), q{Serialized request matches original}) {
            diag q{Request mismatch: } . $comparator->compare_result;
        }

        is_deeply($deserialized_tx->res->headers->to_hash, $tx->res->headers->to_hash, q{Response headers match});

        is_deeply $deserialized_tx->res->json, $tx->res->json, q{Response encoded correctly};
    }

    return;
}

__END__
