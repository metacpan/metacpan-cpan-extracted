#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark 'cmpthese';
use Moo::Role::ToJSON;

# ABSTRACT: benchmark is_attribute_serializable

BEGIN {
    package ToJSON::A;
    use Moo;
    with 'Moo::Role::ToJSON';

    has bar => (is => 'ro', default => 'bar');
    has foo => (is => 'ro', default => 'foo');

    sub _build_serializable_attributes { [qw/bar foo/] }

    sub is_attribute_serializable { return 1 }

    package ToJSON::B;
    use Moo;
    with 'Moo::Role::ToJSON';

    has bar => (is => 'ro', default => 'bar');
    has foo => (is => 'ro', default => 'foo');

    sub _build_serializable_attributes { [qw/bar foo/] }
}

cmpthese(
    1_000_000,
    {
        '::ToJSON with is_attribute_serializable' => sub { ToJSON::A->new->TO_JSON() },
        '::ToJSON wout is_attribute_serializable' => sub { ToJSON::B->new->TO_JSON() },
    }
);
