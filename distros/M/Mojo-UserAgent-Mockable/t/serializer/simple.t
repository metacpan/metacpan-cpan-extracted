use 5.014;
use File::Temp;
use Test::Most;
use Test::JSON;
use Mojo::JSON;
use Mojo::UserAgent::Mockable::Serializer;
use Mojo::UserAgent::Mockable::Request::Compare;
use Mojo::Message::Request;
use Mojo::Message::Response;
use Mojo::UserAgent;

package LocalApp { 
    use Mojolicious::Lite;
    get '/records' => sub {
        my $c = shift;
        $c->render(
            json => {
                meta    => { count => 1, },
                records => [
                    {   id            => 8675309,
                        author        => 'Tommy Tutone',
                        subject       => 'Jenny',
                        repercussions => 'Many telephone companies now refuse to give out the number '
                            . '"867-5309".  People named "Jenny" have come to despise this song. '
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
                        summary => 'The singer wonders who he can turn to, and recalls Jenny, who he feels '
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

my $serializer = Mojo::UserAgent::Mockable::Serializer->new;

subtest 'Victoria and Albert Museum' => sub {
    my $dir = File::Temp->newdir;
   
    my @transactions;
    push @transactions, Mojo::UserAgent->new->get(q{https://www.vam.ac.uk/api/json/museumobject/?limit=1});

    my $result = $transactions[0]->res->json;

    plan skip_all => 'Museum API not responding properly' unless ref $result eq 'HASH' && $result->{'meta'};
    plan skip_all => 'No records returned' unless @{$result->{'records'}};

    my $object_number = $result->{'records'}[0]{'fields'}{'object_number'};

    push @transactions, Mojo::UserAgent->new->get(qq{https://www.vam.ac.uk/api/json/museumobject/$object_number}); 
    my $museum_object = $transactions[1]->res->json;

    plan skip_all => 'Museum object not retrieved properly' unless @{$museum_object} && keys %{$museum_object->[0]};

    test_transactions(@transactions);
};

subtest 'Local App' => sub {
    my $app = LocalApp::app;

    my @transactions = $app->ua->get(q{/records});
     
    my $records = $transactions[0]->res->json;
    my $record_id = $records->{'records'}[0]{'id'};
    push @transactions,  $app->ua->get(qq{/record/$record_id});
    my $record = $transactions[1]->res->json;

    BAIL_OUT('Local app did not serve records correctly') unless $transactions[1]->res->json->[0]{'author'} eq 'Tommy Tutone';

    test_transactions(@transactions);
};

done_testing;

sub test_transactions {
    my @transactions = @_;

    my $serialized;
    lives_ok { $serialized = $serializer->serialize(@transactions) } q{serialize() did not die};

    is_valid_json( $serialized, q{Serializer outputs valid JSON} );

    my $decoded = Mojo::JSON::decode_json($serialized);

    is ref $decoded, 'ARRAY', q{Transactions serialized as array};

    my @deserialized = $serializer->deserialize($serialized);

    for ( 0 .. $#transactions ) {
        my $deserialized_tx = $deserialized[$_];
        my $tx              = $transactions[$_];

        for my $key (qw/request response/) {
            ok defined( $decoded->[$_]{$key} ), qq{Key "$key" defined in serial data};
            for my $subkey (qw/class body/) {
                ok defined( $decoded->[$_]{$key}{$subkey} ), qq{Key "$subkey" defined in "$key" data};
            }
            my $expected_class = sprintf 'Mojo::Message::%s', ucfirst $key;
            is $decoded->[$_]{$key}{'class'}, $expected_class, qq{"$key" class correct};
        }

        my $comparator = Mojo::UserAgent::Mockable::Request::Compare->new;
        if ( !ok $comparator->compare( $deserialized_tx->req, $tx->req ), q{Serialized request matches original} ) {
            diag q{Request mismatch: } . $comparator->compare_result;
        }

        is_deeply( $deserialized_tx->res->headers->to_hash, $tx->res->headers->to_hash, q{Response headers match} );

        is_deeply $deserialized_tx->res->json, $tx->res->json, q{Response encoded correctly};
    }
    return;
}


__END__
