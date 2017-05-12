use Test::Spec;
use Test::Exception;
use Parallel::Tiny;
use Parallel::Tiny::Test;

describe 'A forker' => sub {
    my ($forker, $handler, $fh);

    before each => sub {
        $handler = Parallel::Tiny::Test->new();
        $forker  = Parallel::Tiny->new(
            handler      => $handler,
            workers      => 2,
            worker_total => 4,
        );
    };

    it 'should be able to run several processes' => sub {
        lives_ok { $forker->run() };
    };

    it 'should run the total number of processes expected via worker_total' => sub {
        $forker->run();
        is(_childResponse($handler), '1111');
    };

    it 'should run the total number of processes expected via worker_total even when the workers is higher' => sub {
        $forker = Parallel::Tiny->new(
            handler      => $handler,
            workers      => 4,
            worker_total => 2,
        );
        $forker->run();
        is(_childResponse($handler), '11');
    };
};

runtests unless caller;

sub _childResponse {
    my $handler = shift;

    local $SIG{ALRM} = sub { die "children timed out" };
    alarm 2;

    open(FH, '<', $handler->{filename}) or die $!;

    local $/;
    my $content = <FH>;

    close(FH);

    alarm 0;

    return $content;
}

