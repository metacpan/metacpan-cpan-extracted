#!perl
use strict;
use warnings;
{package CallBacks;
 use Net::Stomp::Frame;
 our @calls;
 sub new {
     my ($class,@args) = @_;
     push @calls,['new',$class,@args];
     bless {},$class;
 }
 for my $m (qw(subscribe unsubscribe
               receive_frame ack
               send send_frame current_host)) {
     no strict 'refs';
     *$m=sub {
         push @calls,[$m,@_];
         return 1;
     };
 }
 sub connect {
     push @calls,['connect',@_];
     return Net::Stomp::Frame->new({
         command => 'CONNECTED',
         headers => {
             session => 'ID:foo',
         },
         body => '',
     });
 }
}
{package TestThing;
 use Moose;
 with 'Net::Stomp::MooseHelpers::CanConnect';
 with 'Net::Stomp::MooseHelpers::ReconnectOnFailure';

 has '+connect_retry_delay' => (
     default => 0.1,
 );

 has '+connection_builder' => (
     default => sub { sub {
         return CallBacks->new(@_);
     } },
 );
}

package main;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Data::Printer;

subtest 'simple' => sub {
    my $obj;
    is(exception {
        $obj = TestThing->new({
            servers => [ { hostname => 'test-host', port => 9999, ssl => 1 } ],
            connect_headers => { foo => 'bar' },
            extra_connection_builder_args => { more => 'args' },
        });

        $obj->connect;
    },undef,'can build & connect');
    ok($obj->is_connected,"it knows it's connected");

    cmp_deeply(\@CallBacks::calls,
               [
                   [
                       'new',
                       'CallBacks',
                       {
                           hosts => [{
                               hostname => 'test-host',
                               port => 9999,
                               ssl => 1,
                           }],
                           more => 'args',
                       },
                   ],
                   [
                       'current_host',
                       ignore(),
                   ],
                   [
                       'connect',
                       ignore(),
                       { foo => 'bar' },
                   ],
               ],
               'STOMP connect called with expected params')
        or note p @CallBacks::calls;
};

subtest 'on failure' => sub {
    no warnings 'redefine','once';
    my $fail_count=0;
    my $orig = \&CallBacks::connect;
    local *CallBacks::connect = sub {
        my $return = $orig->(@_);
        return $return if $fail_count++ >= 4;
        die "planned death";
    };

    my $obj;
    my @servers = (
        { hostname => 'test-host', port => 9999 },
        { hostname => 'test-host-2', port => 8888 },
    );
    $obj = TestThing->new({
        servers => \@servers,
    });

    @CallBacks::calls=();

    my @warns;
    is(exception {
        local $SIG{__WARN__} = sub {
            push @warns,@_;
            note "@_" if $ENV{TEST_VERBOSE};
        };
        $obj->reconnect_on_failure('connect');
    },undef,'can build & connect');
    ok($obj->is_connected,"it knows it's connected");

    my @connect_call = (
        [
            'current_host',
            ignore(),
        ],
        [
            'connect',
            ignore(),
            {},
        ]
    );
    cmp_deeply(\@CallBacks::calls,
               [
                   (
                       [
                           'new',
                           'CallBacks',
                           { hosts => \@servers },
                       ],
                       @connect_call,
                   ) x 5,
               ],
               'STOMP connect called with expected params')
        or note p @CallBacks::calls;

    cmp_deeply(\@warns,
               [ (re(qr{
                          \A
                          connection\ problems\ calling\ TestThing=.*?->connect\(\)
                          .*?
                          \bplanned\ death\b
                          .*?
                          at\ t/connect\.t
                  }xm)) x 4 ],
               'warns were issued correctly')
        or note p @warns;
};

subtest 'reconnect on error' => sub {
    no warnings 'redefine','once';
    my $fail_count=0;
    my $orig = \&CallBacks::connect;
    local *CallBacks::connect = sub {
        my $return = $orig->(@_);
        return $return if $fail_count++ >= 4;
        return Net::Stomp::Frame->new({
            command => 'ERROR',
            headers => {
                message => 'argh',
            },
            body => '',
        });
    };

    my $obj;
    my @servers = (
        { hostname => 'test-host', port => 9999 },
    );
    $obj = TestThing->new({
        servers => \@servers,
    });

    @CallBacks::calls=();

    my @warns;
    is(exception {
        local $SIG{__WARN__} = sub {
            push @warns,@_;
            note "@_" if $ENV{TEST_VERBOSE};
        };
        $obj->reconnect_on_failure('connect');
    },undef,'can build & connect');
    ok($obj->is_connected,"it knows it's connected");

    my @connect_call = (
        [
            'current_host',
            ignore(),
        ],
        [
            'connect',
            ignore(),
            {},
        ],
    );
    cmp_deeply(\@CallBacks::calls,
               [
                   (
                       [
                           'new',
                           'CallBacks',
                           { hosts => \@servers },
                       ],
                       @connect_call,
                   ) x 5,
               ],
               'STOMP connect called with expected params')
        or note p @CallBacks::calls;

    cmp_deeply(\@warns,
               [ (re(qr{
                          \A
                          connection\ problems\ calling\ TestThing=.*?->connect\(\)
                          .*?
                          \bargh\b
                          .*?
                          at\ .*?CanConnect
                  }xm)) x 4 ],
               'warns were issued correctly')
        or note p @warns;
};

done_testing();


