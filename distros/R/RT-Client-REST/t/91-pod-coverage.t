use Test::More;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        plan(skip_all => 'these tests are for release candidate testing');
    }
}

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 9; # heh, plan9!

pod_coverage_ok("RT::Client::REST", {
    also_private => [qw(DEBUG get_links link unlink)]
});
pod_coverage_ok("RT::Client::REST::Exception");
pod_coverage_ok("RT::Client::REST::Object", {
    trustme => [qw(autoget autosync autostore)],
});
pod_coverage_ok("RT::Client::REST::Ticket");
pod_coverage_ok("RT::Client::REST::User");
pod_coverage_ok("RT::Client::REST::Queue");
pod_coverage_ok("RT::Client::REST::Attachment", {
    private => [qw(can count store search _attributes)],
});
pod_coverage_ok("RT::Client::REST::Transaction", {
    private => [qw(can count store search _attributes)],
});
pod_coverage_ok("RT::Client::REST::SearchResult");

# vim:ft=perl:
