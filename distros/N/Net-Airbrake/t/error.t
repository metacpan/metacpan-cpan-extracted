use strict;
use warnings;
use utf8;

use Test::More;

use_ok 'Net::Airbrake::Error';

subtest 'new from HashRef' => sub {
    my $e = Net::Airbrake::Error->new({
        type    => 'test',
        message => 'Error!!!',
    });
    ok $e;
    is $e->type, 'test';
    ok $e->message, 'Error!!!';
    is $e->backtrace, undef;
};

subtest 'new from Object' => sub {
    my $obj = Net::Airbrake::Error->new({
        type    => 'test',
        message => 'Error!!!',
    });

    my $e = Net::Airbrake::Error->new($obj);
    ok $e;
    is $e->type, 'Net::Airbrake::Error';
    ok $e->message;
    is $e->backtrace, undef;
};

subtest 'new from CORE::die message' => sub {
    eval { die 'Oops' }; my $line = __LINE__;
    my $e = Net::Airbrake::Error->new($@);
    ok $e;
    is $e->type, 'CORE::die';
    is $e->message, 'Oops';
    is_deeply $e->backtrace->[0], { file => __FILE__, line => $line, function => 'N/A' };
};

subtest 'new from string' => sub {
    my $e = Net::Airbrake::Error->new('Oops');
    ok $e;
    is $e->type, 'error';
    is $e->message, 'Oops';
    is $e->backtrace, undef;
};

done_testing;
