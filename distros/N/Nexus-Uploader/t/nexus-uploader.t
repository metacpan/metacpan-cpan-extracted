use Test::More 1.00;

require_ok('Nexus::Uploader');

# Test object constraints
{
    my $uploader = eval { Nexus::Uploader->new(); };
    ok( $@ =~ m/Attribute .* is required/, 'Testing Nexus::Uploader->new()' );
}
{
    my $uploader = eval {
        Nexus::Uploader->new(
            group    => 'BRAD',
            artefact => 'Nexus::Uploader::Test',
            version  => '1.0.0',
        );
    };
    ok( !$@, 'Testing Nexus::Uploader->new(GAV)' . $@ );
}

# Finish the testing run
done_testing();
