use 5.014;

use File::stat;
use File::Temp;
use Mojo::UserAgent::Mockable;
use Mojo::UserAgent::Mockable::Serializer;
use Test::Most;

my $dir = File::Temp->newdir;

my @transactions;
push @transactions, Mojo::UserAgent->new->get(q{http://www.vam.ac.uk/api/json/museumobject/O1}), Mojo::UserAgent->new->get(q{http://www.vam.ac.uk/api/json/museumobject/O1}); 

my @results = map { $_->res->json } @transactions;

BAIL_OUT('Museum API not responding properly') unless $results[0]->[0]->{'pk'};

my $output_file = qq{$dir/victoria_and_albert.json};

my $mock = Mojo::UserAgent::Mockable->new( mode => 'record', file => $output_file );
for (0 .. $#transactions) {
    my $result_from_mock;
    lives_ok { $result_from_mock = $mock->get( $transactions[$_]->req->url )->res->json; } 'get() did not die';
    is_deeply( $result_from_mock, $results[$_], 'result matches that of stock Mojo UA' );
}
$mock->save;

ok -e $output_file, 'Output file exists';
isnt stat($output_file)->size, 0, 'Output file has nonzero size';
my @deserialized = Mojo::UserAgent::Mockable::Serializer->new->retrieve($output_file);

is scalar @deserialized, scalar @transactions, 'Transaction count matches';
done_testing;

