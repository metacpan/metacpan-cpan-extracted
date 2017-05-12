package testlib::Util;
use strict;
use warnings;
use Test::Builder;
use Test::More;
use Test::MockObject;
use Exporter qw(import);

our @EXPORT_OK = qw(test_call end_call mock_timeline mock_search mock_twitter statuses);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

sub test_call {
    my ($mock, $method, @method_args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply([$mock->next_call], [$method, [$mock, @method_args]], "mock method $method");
}

sub end_call {
    my ($mock, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(!defined(scalar($mock->next_call)), $msg || "call end");
}

sub limit {
    my ($orig, $min, $max) = @_;
    $$orig = $min if $$orig < $min;
    $$orig = $max if $$orig > $max;
}

sub mock_timeline {
    my ($self, $params) = @_;
    my $page_size = $params->{count} || $params->{per_page} || $params->{rpp} || 10;
    my $max_id = $params->{max_id} || 100;
    my $since_id = $params->{since_id} || 0;
    limit \$max_id,   1, 100;
    limit \$since_id, 0, 100;
    my @result = ();
    for(my $id = $max_id ; $id > $since_id && int(@result) < $page_size ; $id--) {
        push(@result, { id => $id });
    }
    return \@result;
}

sub mock_search {
    my ($self, $params) = @_;
    my $statuses = mock_timeline($self, $params);
    return { results => $statuses };
}

sub statuses {
    my (@ids) = @_;
    return map { +{id => $_} } @ids;
}

sub mock_twitter {
    my $mocknt = Test::MockObject->new();
    foreach my $method (
        qw(home_timeline user_timeline public_timeline list_statuses
           favorites mentions retweets_of_me)
    ) {
        $mocknt->mock($method, \&mock_timeline) 
    }
    
    $mocknt->mock('search', \&mock_search);
    return $mocknt;
}

1;

