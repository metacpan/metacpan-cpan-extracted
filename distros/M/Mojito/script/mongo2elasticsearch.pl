use strictures 1;
use Mojito::Model::Transform;
use Data::Dumper::Concise;

# Transform each collection: notes, collection, users
my $transfer_type = 'elasticsearch';
my $t = Mojito::Model::Transform->new(transfer_type => 'elasticsearch');
my @collections = @{ $t->collections };
foreach my $collection (@collections) {
    print "Collection: $collection\n";
    my @ids =$t->list_mongo_ids($collection);
    $t->transfer_records($collection, @ids);
}

warn Dumper $t->frigo->export if ($ARGV[0] && $ARGV[0] =~ /DEBUG/i);

1;