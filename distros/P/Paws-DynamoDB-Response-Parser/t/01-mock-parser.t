#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::MockObject;
use Paws::DynamoDB::Response::Parser;

my $parser = Paws::DynamoDB::Response::Parser->new;

# Helper: mock a Paws::DynamoDB::AttributeValue
sub attr {
    my ($type, $value) = @_;
    my $mock = Test::MockObject->new;
    $mock->set_isa('Paws::DynamoDB::AttributeValue');

    for my $field (qw(S N BOOL NULL B M L SS NS BS)) {
        $mock->mock($field => sub { $field eq $type ? $value : undef });
    }

    return $mock;
}

# Helper: mock a Paws::DynamoDB::AttributeMap
sub attr_map {
    my (%fields) = @_;
    my $mock = Test::MockObject->new;
    $mock->set_isa('Paws::DynamoDB::AttributeMap');
    $mock->mock(Map => sub { \%fields });
    return $mock;
}

# Sample mocked item
my $mock_item = attr_map(
    str  => attr(S    => 'hello'),
    num  => attr(N    => '42'),
    bool => attr(BOOL => 1),
    null => attr(NULL => 1),
    list => attr(L    => [ attr(S => 'x'), attr(N => '1') ]),
    map  => attr(M    => { inner => attr(BOOL => 0) }),
    ss   => attr(SS   => ['a', 'b']),
    ns   => attr(NS   => ['3', '4']),
    bs   => attr(BS   => ['aGVsbG8=']),
);

# GetItemOutput
{
    my $resp = Test::MockObject->new;
    $resp->set_isa('Paws::DynamoDB::GetItemOutput');
    $resp->mock(Item => sub { $mock_item });

    my $result = $parser->to_perl($resp);

    is($result->{str}, 'hello', 'GetItem: string');
    is($result->{num}, 42, 'GetItem: number');
    is($result->{bool}, 1, 'GetItem: bool');
    ok(!defined $result->{null}, 'GetItem: null');
    is_deeply($result->{list}, ['x', 1], 'GetItem: list');
    is_deeply($result->{map}, { inner => 0 }, 'GetItem: map');
    is_deeply($result->{ss}, ['a', 'b'], 'GetItem: ss');
    is_deeply($result->{ns}, [3, 4], 'GetItem: ns');
    is_deeply($result->{bs}, ['aGVsbG8='], 'GetItem: bs');
}

# ScanOutput
{
    my $resp = Test::MockObject->new;
    $resp->set_isa('Paws::DynamoDB::ScanOutput');
    $resp->mock(Items => sub { [$mock_item] });

    my $result = $parser->to_perl($resp);
    is(ref $result, 'ARRAY', 'ScanOutput returns arrayref');
    is($result->[0]{str}, 'hello', 'ScanOutput: item[0] string');
}

# QueryOutput
{
    my $resp = Test::MockObject->new;
    $resp->set_isa('Paws::DynamoDB::QueryOutput');
    $resp->mock(Items => sub { [$mock_item] });

    my $result = $parser->to_perl($resp);
    is(ref $result, 'ARRAY', 'QueryOutput returns arrayref');
    is($result->[0]{num}, 42, 'QueryOutput: item[0] number');
}

# BatchGetItemOutput
{
    my $map = {
        MyTable => [ $mock_item ]
    };

    my $responses = Test::MockObject->new;
    $responses->set_isa('Paws::DynamoDB::MapAttributeResponse');
    $responses->mock(Map => sub { $map });

    my $resp = Test::MockObject->new;
    $resp->set_isa('Paws::DynamoDB::BatchGetItemOutput');
    $resp->mock(Responses => sub { $responses });

    my $result = $parser->to_perl($resp);
    is(ref $result, 'ARRAY', 'BatchGetItemOutput returns arrayref');
    is($result->[0]{map}{inner}, 0, 'BatchGetItemOutput: inner map value');
}

done_testing;
