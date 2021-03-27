package Test::Search::Typesense;

use Moo;
use Test::Most ();
use Test::Search::Typesense::Cached;
use Search::Typesense::Types qw(
  InstanceOf
);

has typesense => (
    is      => 'ro',
    isa     => InstanceOf ['Search::Typesense'],
    builder => '_build_typesense',
);

sub _build_typesense {
    my $self = shift;
    my $typesense;
    eval {
        $typesense = Test::Search::Typesense::Cached->new(
            use_https => 0,
            host      => 'localhost',
            port      => 7777,
            api_key   => 777,
        );
    };
    if ($typesense) {
        $typesense->collections->delete_all;
        return $typesense;
    }

    my $reason = $@;
    Test::Most::explain(<<"END");
If they don't have Typesense running, we skip the tests and give them the
information they need to get the tests running. However, if they're running a
bizarrely old version of Typesense (< 0.8.0), we don't guarantee support and
we bail out.

Error reason: $reason
END
    Test::More::plan( skip_all =>
          "Typesense does not appear to be running. See the CONTRIBUTING.md document with this distribution."
    );
    unless ( $typesense->typesense_version ) {
        Test::More::diag(
            "https://github.com/typesense/typesense-api-spec/commit/778ad3e0d2bdf23e6ccc1b23113ae6f48ec345fb"
        );
        Test::More::BAIL_OUT(
            "You're using a version of Typesense earlier than 0.8.0.");
    }
}

# If, for some strange reason, we've still hit an existing Typesense database,
# minimize the chance of hitting a valid collection
sub company_collection_name {
    'company_XXX_this_will_be_deleted_after_testing_XXX';
}

sub company_collection_definition {
    my $self = shift;
    return {
        'name'          => $self->company_collection_name,
        'num_documents' => 0,
        'fields'        => [
            {
                'name'  => 'company_name',
                'type'  => 'string',
                'facet' => 0,
            },
            {
                'name'  => 'num_employees',
                'type'  => 'int32',
                'facet' => 0,
            },
            {
                'name'  => 'country',
                'type'  => 'string',
                'facet' => 1,
            }
        ],
        'default_sorting_field' => 'num_employees'
    };
}

sub DEMOLISH {
    my $typesense = $_[0]->typesense;
    $typesense->collections->delete_all if $typesense;
}

1;
