#!perl
use strict;
use warnings;
use lib 't/lib';
use Stomp_LogCalls;

{package TransformClass;

 sub transform {
     my ($me,@data) = @_;
     return { destination => 'a_class' },
         { me => $me, data => \@data };
 }
}
{package TransformInstance;
 use Moose;

 has param => (is => 'ro');

 sub transform {
     my ($me,@data) = @_;
     return { destination => 'a_instance' }, 
         { me => ref($me), param => $me->param, data => \@data };
 }
}
{package TransformAndValidate;

 sub validate {
     my ($self,$headers,$data) = @_;
     return 1 if $data->{ok};
     die "bad input\n";
 }

 sub transform {
     my ($me,$data) = @_;
     return { destination => 'validating' },
         $data,
 }
}

package main;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Data::Printer;
use Net::Stomp::Producer;
use JSON::XS;

my $p;
subtest 'building' => sub {
    cmp_deeply(exception {
        $p=Net::Stomp::Producer->new({
            connection_builder => sub { return Stomp_LogCalls->new(@_) },
            servers => [ {
                hostname => 'test-host', port => 9999,
                # these are to be sure they get ignored
                subscribe_headers => { server_level => 'header' },
            } ],
            connect_headers => { foo => 'bar' },
            default_headers => { default => 'header' },
        })
    },undef,'can build');

    cmp_deeply(\@Stomp_LogCalls::calls,[],
               'not connected yet')
        or note p @Stomp_LogCalls::calls;
};

subtest 'serialisation failure' => sub {
    cmp_deeply(exception { $p->send('somewhere',{},{a=>'ref'}) },
               isa('Net::Stomp::Producer::Exceptions::CantSerialize'),
               'no serialiser set');

    cmp_deeply(\@Stomp_LogCalls::calls,[],
               'still not connected')
        or note p @Stomp_LogCalls::calls;
};

subtest 'straight send' => sub {
    cmp_deeply(exception { $p->send('somewhere',{},'{"a":"message"}') },
               undef,
               'no serialiser needed');

    cmp_deeply(\@Stomp_LogCalls::calls,
               [
                   [
                       'new',
                       'Stomp_LogCalls',
                       {
                           hosts => [
                               superhashof({
                                   hostname => 'test-host',
                                   port => 9999,
                               }),
                           ],
                       },
                   ],
                   [
                       'connect',
                       ignore(),
                       { foo => 'bar' },
                   ],
                   [
                       'send',
                       ignore(),
                       {
                            body  => '{"a":"message"}',
                            default => 'header',
                            destination => '/somewhere',
                       },
                   ],
               ],
               'connected & sent')
        or note p @Stomp_LogCalls::calls;
};


subtest 'arbitrary sending method' => sub {
    for my $method ('transactional','with_receipt','just_testing') {
        @Stomp_LogCalls::calls=();

        $p->sending_method($method);

        cmp_deeply(exception { $p->send('somewhere',{},'{"a":"message"}') },
                   undef,
                   'no serialiser needed');


        cmp_deeply(\@Stomp_LogCalls::calls,
                   [
                       [
                           "send_$method",
                           ignore(),
                           {
                               body  => '{"a":"message"}',
                               default => 'header',
                               destination => '/somewhere',
                           },
                       ],
                   ],
                   "connected & sent with $method")
            or note p @Stomp_LogCalls::calls;
    }

    for my $method ('','default') {
        @Stomp_LogCalls::calls=();

        $p->sending_method($method);

        cmp_deeply(exception { $p->send('somewhere',{},'{"a":"message"}') },
                   undef,
                   'no serialiser needed');

        cmp_deeply(\@Stomp_LogCalls::calls,
                   [
                       [
                           'send',
                           ignore(),
                           {
                               body  => '{"a":"message"}',
                               default => 'header',
                               destination => '/somewhere',
                           },
                       ],
                   ],
                   "connected & sent with default 'send'")
            or note p @Stomp_LogCalls::calls;
    }

    $p->sending_method('');
    cmp_deeply(exception { $p->sending_method('bad') },
               isa('Net::Stomp::Producer::Exceptions::BadMethod'),
               'bad sending_method throws exception');
    is($p->sending_method,'','bad value is not kept');
};

subtest 'transactional send (back-compat)' => sub {
    $p->transactional_sending(1);
    is($p->sending_method,'transactional','transactional set');

    $p->transactional_sending(0);
    is($p->sending_method,'','transactional reset');
};

my $json = JSON::XS->new->canonical(1)->pretty(0);

subtest 'serialise & send' => sub {
    @Stomp_LogCalls::calls=();

    $p->serializer(sub{$json->encode($_[0])});

    cmp_deeply(exception { $p->send('somewhere',{},{a=>'message'}) },
               undef,
               'serialiser worked');

    cmp_deeply(\@Stomp_LogCalls::calls,
               [
                   [
                       'send',
                       ignore(),
                       {
                            body  => '{"a":"message"}',
                            default => 'header',
                            destination => '/somewhere',
                       },
                   ],
               ],
               'connected & sent')
        or note p @Stomp_LogCalls::calls;
};

subtest 'transformer class' => sub {
    @Stomp_LogCalls::calls=();

    $p->serializer(sub{$json->encode($_[0])});

    cmp_deeply(exception {
        $p->transform_and_send('TransformClass',['some','data'])
    },
               undef,
               'transformer class worked');

    cmp_deeply(\@Stomp_LogCalls::calls,
               [
                   [
                       'send',
                       ignore(),
                       {
                            body  => '{"data":[["some","data"]],"me":"TransformClass"}',
                            default => 'header',
                            destination => '/a_class',
                       },
                   ],
               ],
               'connected & sent')
        or note p @Stomp_LogCalls::calls;
};

subtest 'transformer instance' => sub {
    @Stomp_LogCalls::calls=();

    $p->transformer_args({param => 'passed in'});

    cmp_deeply(exception {
        $p->transform_and_send('TransformInstance',['some','data'])
    },
               undef,
               'transformer class worked');

    cmp_deeply(\@Stomp_LogCalls::calls,
               [
                   [
                       'send',
                       ignore(),
                       {
                            body  => '{"data":[["some","data"]],"me":"TransformInstance","param":"passed in"}',
                            default => 'header',
                            destination => '/a_instance',
                       },
                   ],
               ],
               'connected & sent')
        or note p @Stomp_LogCalls::calls;
};

subtest 'transformer instance exception' => sub {
    @Stomp_LogCalls::calls=();

    $p->transformer_args({param => 'passed in'});

    my $e;
    cmp_deeply($e=exception {
        $p->transform_and_send('TransformInstance',[$p])
    },
               all(
                   isa('Net::Stomp::Producer::Exceptions::CantSerialize'),
                   methods(previous_exception=>re(qr{^encountered object\b})),
               ),
               'transformer class died')
        or note $e;

    cmp_deeply(\@Stomp_LogCalls::calls,
               [],
               'nothing sent')
        or note p @Stomp_LogCalls::calls;
};

subtest 'split transform/send_many' => sub {
    $p->serializer(sub{$json->encode($_[0])});

    my @msgs;
    cmp_deeply(exception {
        @msgs=$p->transform('TransformClass',['some','data'])
    },
               undef,
               'transformer class worked');
    cmp_deeply(exception {
        $p->send_many(@msgs)
    },
               undef,
               'send_many worked');

    cmp_deeply(\@Stomp_LogCalls::calls,
               [
                   [
                       'send',
                       ignore(),
                       {
                            body  => '{"data":[["some","data"]],"me":"TransformClass"}',
                            default => 'header',
                            destination => '/a_class',
                       },
                   ],
               ],
               'connected & sent')
        or note p @Stomp_LogCalls::calls;
};

subtest 'validation ok' => sub {
    @Stomp_LogCalls::calls=();

    $p->serializer(sub{$json->encode($_[0])});

    cmp_deeply(exception {
        $p->transform_and_send('TransformAndValidate',{ok=>1});
    },
               undef,
               'validation passed');

    cmp_deeply(exception {
        $p->transform_and_send('TransformAndValidate',{ok=>0});
    },
               all(
                   isa('Net::Stomp::Producer::Exceptions::Invalid'),
                   methods(
                       reason => re(qr{\bvalidation\b}),
                       previous_exception => "bad input\n",
                   ),
               ),
               'validation falied as expected');
};

done_testing();
