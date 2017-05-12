#!perl
use strict;
use warnings;
use lib 't/lib';
use Stomp_LogCalls;

{package Tr1;
 sub new {
     my ($class,$args) = @_;
     my $self = { arg => delete $args->{foo} };
     return bless $self,$class;
 }
 sub transform {
     my ($self) = @_;
     return {destination => 'foo'},
         $self->{arg};
 }
}

package main;
use Test::More;
use Test::Deep;
use Data::Printer;
use Net::Stomp::Producer;

my $args = { foo => '123' };
my $p=Net::Stomp::Producer->new({
    connection_builder => sub { return Stomp_LogCalls->new(@_) },
    servers => [ {
        hostname => 'test-host', port => 9999,
    } ],
    transformer_args => $args,
});

is($p->transformer_args,$args,
   "transformer_args takes the ref");

$p->transform_and_send('Tr1',{});
cmp_deeply(\@Stomp_LogCalls::calls,
           superbagof(
               [
                   'send',
                   ignore(),
                   {
                       body  => '123',
                       destination => '/foo',
                   },
               ],
           ),
           'sent the arg')
    or note p @Stomp_LogCalls::calls;

cmp_deeply($p->transformer_args,{foo=>'123'},
           'args unchanged');

@Stomp_LogCalls::calls=();

$p->transform_and_send('Tr1',{});
cmp_deeply(\@Stomp_LogCalls::calls,
           superbagof(
               [
                   'send',
                   ignore(),
                   {
                       body  => '123',
                       destination => '/foo',
                   },
               ],
           ),
           'sent the arg, second time')
    or note p @Stomp_LogCalls::calls;

cmp_deeply($p->transformer_args,{foo=>'123'},
           'args still unchanged');

done_testing;
