package NanoTest::Mw;
use strict;
use warnings;

# A tiny object middleware used to prove that enable '^Class' resolves to the
# escaped class verbatim, not to PAGI::Middleware::Class. It records each run in
# a package array the test can inspect.

our @TRAIL;

sub new { my ($class, %args) = @_; bless { %args }, $class }

sub wrap {
    my ($self, $app) = @_;
    return sub {
        my ($scope, $receive, $send) = @_;
        push @TRAIL, $self->{tag} // 'default';
        return $app->($scope, $receive, $send);
    };
}

1;
