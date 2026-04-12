use Test::More;

# List all modules that should load
my @modules = qw(
    SimpleMock
    SimpleMock::Util
    SimpleMock::ScopeGuard
    SimpleMock::Model::DBI
    SimpleMock::Model::LWP_UA
    SimpleMock::Model::SUBS
    SimpleMock::Model::PATH_TINY
    SimpleMock::Mocks::DBI
    SimpleMock::Mocks::LWP::UserAgent
    SimpleMock::Mocks::Path::Tiny
    DBD::SimpleMock
);

foreach my $mod (@modules) {
    use_ok($mod) or diag "Couldn't load $mod";
}

done_testing;

