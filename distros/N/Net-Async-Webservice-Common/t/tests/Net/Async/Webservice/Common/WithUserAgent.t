#!perl
use strict;
use warnings;
use 5.010;
use Test::Most;
use Data::Printer;
use HTTP::Request;
use HTTP::Response;

{package Net::Async::HTTP; # yes, a fake one
    use Moo;
    sub do_request {}
    sub POST {}
    sub GET {}
};
$INC{'Net/Async/HTTP.pm'}=__FILE__;

{package TestLoop;
    use Moo;
    has added => ( is => 'rw', default => sub { [] } );
    sub add {
        my ($self,$thing) = @_;
        push @{$self->added},$thing;
        return;
    }
};

{package TestUA;
    use Moo;
    sub request {}
    sub get {}
    sub post {}
};

{package TestPkg;
    use Moo;

    with 'Net::Async::Webservice::Common::WithUserAgent';
};

subtest 'manual "async" UA' => sub {
    my $ua = Net::Async::HTTP->new;
    my $t;
    lives_ok { $t=TestPkg->new({user_agent=>$ua}) }
        'object built';
};

subtest 'manual "sync" UA' => sub {
    my $ua = TestUA->new;
    my $t;
    lives_ok { $t=TestPkg->new({user_agent=>$ua}) }
        'object built';
    cmp_deeply($t->user_agent,
               all(
                   isa('Net::Async::Webservice::Common::SyncAgentWrapper'),
                   methods(
                       ua => $ua,
                   ),
               ),
               'UA wrapped');
};

subtest 'with loop' => sub {
    my $loop = TestLoop->new;
    my $t;
    lives_ok { $t=TestPkg->new({loop=>$loop}) }
        'object built';
    cmp_deeply($loop->added,
               [isa('Net::Async::HTTP')],
               'UA built and added');
    cmp_ok($loop->added->[0],'==',$t->user_agent,
           'only one UA built');
};

done_testing;
