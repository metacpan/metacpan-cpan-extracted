use strictures 1;
use 5.010;
use Mojito;
use Data::Dumper::Concise;

=head1 Purpose

To copy a collection over from one mojito db to another.

=cut

# This is where we copy FROM
say "DB host:port to copy FROM:";
my $from_db_host = <STDIN>;
my $app = Mojito->new( db_host => $from_db_host );
say "DB host:port to copy TO:";
my $to_db_host = <STDIN>;

# This is where we copy TO
my $app_other = Mojito->new( db_host => $to_db_host );

say "Collection id to copy:";
my $collection_id = <STDIN>;

main($collection_id);

sub main {
    my $collection_id = shift;

    my $collection = $app->collector->read($collection_id);
    my @page_ids = @{$collection->{collected_page_ids}};
    
    # copy each page of the collection to the other db
    foreach my $page_id (@page_ids) {
        copy_page($page_id);
    }

    # copy the collection to the other db
    copy_collection($collection_id);
}



sub copy_collection {
    my $collection_id = shift;

    my $doc = $app->collector->read($collection_id);
    my $doc_other = $app_other->collector->read($doc->{_id}->to_string);
    my $oid;
    if ( $oid = $doc_other->{_id} ) {
        $doc->{id} = $oid->to_string;
        $app_other->collector->update( $doc );
        say "Updating collection $oid ...";
    } 
    else {
        $oid = $app_other->collector->create($doc);
        say "Saving collection $oid ...";
    }

    return;
}

sub copy_page {
    my ($page_id) = (shift);

    my $doc = $app->read($page_id);
    # See if page already exists in other db
    my $page = $app_other->read($doc->{_id}->to_string);
    my $oid;
    if ( $oid = $page->{_id} ) {
            $app_other->update( $oid->to_string, $doc );
            say "Updating page $oid ...";
    } 
    else {
        $oid = $app_other->create($doc);
        say "Saving page $oid ...";
    }

    return;
}
