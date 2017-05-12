#!/usr/local/bin/perl
use strict;
use lib "../blib/lib";
use lib "blib/lib";
use Test;
use Test::More tests=>39;
#use Test::More tests=>'noplan';
#use Test::MockObject::Extends;

my $init_log = 0;

BEGIN {
#
#  init_log
#
#  Read and initialize the log4perl configuration file.
#
    use Cwd;
    use Log::Log4perl;
    my $cwd = getcwd();
    my $logfile = 'log4perl.conf';
    while ( $cwd && $cwd ne "/" && !-f "$cwd/$logfile") {
        $cwd =~ s:/?[^/]*$::;
    }

    sub _init_log {
        if (-f "$cwd/$logfile") {
            # print STDERR "Using $cwd/log4perl.conf.\n";
            Log::Log4perl->init_and_watch("$cwd/log4perl.conf", 30);
        } else {
            # print STDERR "No log4perl.conf file found, creating default\n";
            my $app = Log::Log4perl::Appender->new("Log::Dispatch::Screen");
            my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p %m %n");
            $app->layout($layout);
            my $logger = Log::Log4perl::Logger->get_root_logger();
            $logger->level($Log::Log4perl::FATAL);
            # 
            # Only do this once so we don't get duplicate appenders #'
            #
            $logger->add_appender($app) unless $init_log;
            $init_log = 1;
        }
    }

    sub SIGUSR1 {
        _init_log();
    }

    _init_log();
}

# these are for mocking Net::SMTP
my $data_sub = sub {
    my $self = shift;
    if (@_) {
        $self->reset() 
    } else {
        return 1;
    }
};

my $dataend_sub = sub {
    my $self = shift;
    $self->reset();
    return 1;
};

my $config_found;
my $to;
my $good_server;
eval {
    require Net::SMTP::Retryable::ConfigData;
    $config_found = 1;
    $to = Net::SMTP::Retryable::ConfigData->config('to-address');
    $good_server = Net::SMTP::Retryable::ConfigData->config('smtp-server');
};

require_ok('Net::SMTP');
require_ok('Net::SMTP::Retryable');

my $smtp;
my $bad_server = 'silly-server-name-which-doesnt-exist';
my $from = 'mprewitt@flatiron.org';

ok(!defined Net::SMTP->new(bless [$bad_server], 'puppy'), 
        'bad mail host non-array ref ref');

ok(!defined Net::SMTP->new([$bad_server], retryfactor => 0.1), 
        'bad mail host no retries');

ok(!defined Net::SMTP->new([$bad_server], retryfactor => 0.1, connectretries => 5), 
        'bad mail host');

my $r;
SKIP: {
    skip "No config info, smtp server or to address defined", 31 unless $good_server && $to && $config_found;

    isa_ok($smtp = Net::SMTP->new([$bad_server, $good_server]), 'Net::SMTP::Retryable', 'constructor 2 hosts');
    isa_ok($smtp = Net::SMTP->new([$bad_server, $good_server], retryfactor => 0.1, connectretries=>1, sendretries=>1), 'Net::SMTP::Retryable', 'constructor with retries');

    isa_ok($smtp = Net::SMTP->new($good_server), 'Net::SMTP::Retryable', 'constructor 1');
#$smtp = mock_me($smtp);
    is($smtp->host($from), $good_server, 'host');

    for my $method ( qw( to cc bcc recipient ) ) {
        ok($r = $smtp->mail($from), 'mail');
        print STDERR $smtp->message unless $r;
        ok($r = $smtp->$method($to), $method);
        print STDERR $smtp->message unless $r;
        ok($r = $smtp->data("This is a test with $method"), 'data');
        print STDERR $smtp->message unless $r;
    }

    ok($smtp->mail($from), 'mail');
    ok(!$smtp->data("Data without recipient"), 'data before recip');

    isa_ok($smtp = Net::SMTP->new($good_server), 'Net::SMTP::Retryable', 'constructor 2');
    ok($smtp->mail($from), 'mail');
    ok($smtp->to($from), 'bad to address');

    isa_ok($smtp = Net::SMTP->new($good_server), 'Net::SMTP::Retryable', 'constructor 3');

#$smtp = mock_me($smtp);

#ok($smtp->SendMail(mail=>$from, to=>$to, data=>'test 1'), 'SendMail');
#ok($smtp->SendMail(mail=>$from, to=>$to, data=>'test 2'), 'SendMail');
#ok($smtp->SendMail(mail=>[$from, Bits=>7], to=>$to, data=>'test 3'), 'SendMail');
#ok($smtp->SendMail(mail=>[$from, Bits=>7], to=>$to ), 'SendMail');

    ok($r = $smtp->mail($from), 'mail');
        print STDERR $smtp->message unless $r;
    ok($r = $smtp->to($to), 'to');
        print STDERR $smtp->message unless $r;
    ok($r = $smtp->data(), 'blank data');
        print STDERR $smtp->message unless $r;
    ok($r = $smtp->datasend("Testing datasend"), 'datasend');
        print STDERR $smtp->message unless $r;
    ok($r = $smtp->dataend(), 'dataend');
        print STDERR $smtp->message unless $r;

    my $mime_entity_ok;
    BEGIN { $mime_entity_ok = use_ok('MIME::Entity') };
SKIP: {
    skip "MIME::Entity not available to test", 1 unless $mime_entity_ok;
    my $mail = MIME::Entity->build(
        Subject => 'test',
        From => $from,
        Sender => $from,
        To => $to,
        'Reply-To' => $from,
        Type => 'text/plain',
        Data => 'test MIME::Entity send',
    );

    ok($r = $mail->smtpsend(Host=>$good_server), 'mime::entity->smtpsend');
        print STDERR $smtp->message unless $r;
};

    isa_ok($smtp = Net::SMTP->new($good_server), 'Net::SMTP::Retryable', 'constructor 3');

    my $test_mockobject_ok;
    BEGIN { $test_mockobject_ok = use_ok('Test::MockObject::Extends') };
SKIP: {
    skip "Test::MockObject::Extends not available to test", 3 unless $test_mockobject_ok;
TODO: {
    local $TODO = "Need to get mock object working";
    my $mock_smtp = Test::MockObject::Extends->new($smtp->get_smtp());
    $mock_smtp->set_false( 'to' );
    ok($mock_smtp->mail($from), 'mail');
    ok($mock_smtp->to($to), 'to fails first time');
    ok($mock_smtp->data("This is a test with to"), 'data');
};
};

};

sub mock_me {
    my $smtp = shift;
    my $mock_smtp = Test::MockObject::Extends->new($smtp);
    $mock_smtp->mock( 'data', $data_sub );
    $mock_smtp->set_true( 'datasend' );
    $mock_smtp->mock( 'dataend', $dataend_sub );
    return $mock_smtp;
}
