use Test::Spec;
use strict;
use warnings;
use lib 't/lib';
use SQS::Worker::Client;
use SQS::Worker::DefaultLogger;
use Worker::NothingWorker;
use SQS::Consumers::Default;
use SQS::Consumers::DeleteAlways;
use SQS::Consumers::DeleteAndFork;
use TestMessage;

sub stub_sqs {
    my $client = SQS::Worker::Client->new(serializer => 'json', queue_url => '', region => '');
    my $serialized = $client->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });
    my $message = TestMessage->new(Body => $serialized, ReceiptHandle => '');
    my $message_pack = stub(Messages => [$message]);
    my $sqs_stub = stub(
        ReceiveMessage => $message_pack,
        DeleteMessage => undef,
        isa => 'Paws::SQS',
    );
    return $sqs_stub;
}

sub logmock {
    return stub(
        info => sub {},
        error => sub {},
        warning => sub {},
        debug => sub {});
}

sub mk_success_worker {
    my $processor = shift;
    my $worker = Worker::NothingWorker->new(
        queue_url => '',
        region => '',
        log => logmock(),
        sqs => stub_sqs(),
        processor => $processor,
    );
    $worker->stubs(process_message => sub { 42; });
    return $worker;
};

sub mk_failure_worker {
    my $processor = shift;
    my $worker = Worker::NothingWorker->new(
        queue_url => '',
        region => '',
        log => logmock(),
        sqs => stub_sqs(),
        processor => $processor,
    );
    $worker->stubs(process_message => sub { die "I'm falling" });
    return $worker;
}

describe "Default consumer" => sub {
    my $processor = SQS::Consumers::Default->new;
    it "will delete message on success" => sub {
        my $worker = mk_success_worker($processor);
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };

    it "will not delete message on failure" => sub {
        my $worker = mk_failure_worker($processor);
        my $expectation = $worker->expects('delete_message')->never();
        $worker->fetch_message();
        ok($expectation->verify);
    };
};

describe "DeleteAlways consumer" => sub {
    my $processor = SQS::Consumers::DeleteAlways->new;

    it "will delete message on success" => sub {
        my $worker = mk_success_worker($processor);
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };

    it "will delete message on failure" => sub {
        my $worker = mk_failure_worker($processor);
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };
};
describe "DeleteAndFork consumer" => sub {
    my $processor = SQS::Consumers::DeleteAndFork->new;

    it "will delete message on success" => sub {
        my $worker = mk_success_worker($processor);
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };

    it "will delete message on failure" => sub {
        my $worker = mk_failure_worker($processor);
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };
};

runtests unless caller;
1;
