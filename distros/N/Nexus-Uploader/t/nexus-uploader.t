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
            group    => 'BRAD.SVW',
            artefact => 'Nexus::Uploader::Test',
            version  => '1.0.0',
        );
    };
    ok( !$@, 'Testing Nexus::Uploader->new(GAV)' . $@ );
    cmp_ok $uploader->artefact, 'eq', 'Nexus-Uploader-Test', 'Testing artefact processing';
    cmp_ok $uploader->group,    'eq', 'BRAD/SVW',            'Testing group processing';
}

# Finish the testing run
done_testing();
