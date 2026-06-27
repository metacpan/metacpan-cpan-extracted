use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Response;

# A plain-Perl framework-style subclass (no Moose dependency in the test):
{
    package T::FancyResponse;
    use parent -norequire, 'PAGI::Response';
    use Future::AsyncAwait;
    # The documented seam: override respond($send) to customize sending.
    async sub respond {
        my ($self, $send) = @_;
        $self->header('X-Framework' => 'fancy');   # public chainer, not internals
        return await $self->SUPER::respond($send);
    }
}

sub recorder { my @e; my $s = sub { push @e, $_[0]; Future->done }; return ($s, \@e) }

subtest 'subclass: construct via new($scope), override respond, use accessors' => sub {
    my $res = T::FancyResponse->new({ type => 'http' });   # parent constructor
    isa_ok $res, ['PAGI::Response'], 'is-a PAGI::Response';
    is ref($res->scope), 'HASH', 'scope() accessor works (no internal poking)';

    $res->status(201)->json({ ok => 1 });                  # public chainers + body method
    is $res->status, 201, 'status() accessor reflects the chained value';

    my ($send, $events) = recorder();
    $res->respond($send)->get;                             # the overridden respond
    is $events->[0]{status}, 201, 'subclass sends with the accumulated status';
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $h{'x-framework'}, 'fancy', 'respond override added a header via SUPER::respond';
    like $events->[1]{body}, qr/ok/, 'body sent';
};

done_testing;
