#!/usr/bin/env perl

use utf8;
use 5.008001;

use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use version; our $VERSION = qv('v1.2.0');

use PPIx::Shorthand qw< get_ppi_class >;

use Test::More tests => 12;
use Test::Exception;


Readonly my $EMPTY_STRING => q<>;


throws_ok(
    sub { get_ppi_class(undef) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'get_ppi_class() throws an exception when called with undef.',
);
throws_ok(
    sub { get_ppi_class($EMPTY_STRING) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'get_ppi_class() throws an exception when called with an empty string.',
);


my $translator = PPIx::Shorthand->new();


throws_ok(
    sub { $translator->get_class(undef) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'get_class() throws an exception when called with undef.',
);
throws_ok(
    sub { $translator->get_class($EMPTY_STRING) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'get_class() throws an exception when called with an empty string.',
);


throws_ok(
    sub { $translator->add_class_translation(undef, 'PPI::Token') },
    qr/Must [ ] specify [ ] name [.]/xms,
    'add_class_translation() throws an exception when called without a name.',
);
throws_ok(
    sub { $translator->add_class_translation($EMPTY_STRING, 'PPI::Token') },
    qr/Must [ ] specify [ ] name [.]/xms,
    'add_class_translation() throws an exception when called with an empty name.',
);

throws_ok(
    sub { $translator->add_class_translation('foo', undef) },
    qr/Must [ ] specify [ ] PPI [ ] class [.]/xms,
    'add_class_translation() throws an exception when called without a class.',
);
throws_ok(
    sub { $translator->add_class_translation('foo', $EMPTY_STRING) },
    qr/Must [ ] specify [ ] PPI [ ] class [.]/xms,
    'add_class_translation() throws an exception when called with an empty class.',
);
throws_ok(
    sub { $translator->add_class_translation('foo', 'bar') },
    qr/"bar" [ ] is [ ] not [ ] a [ ] known [ ] subclass [ ] of [ ] PPI::Element [.]/xms,
    'add_class_translation() throws an exception when called with a bad class.',
);


throws_ok(
    sub { $translator->remove_class_translation(undef) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'remove_class_translation() throws an exception when called without a name.',
);
throws_ok(
    sub { $translator->remove_class_translation($EMPTY_STRING) },
    qr/Must [ ] specify [ ] name [.]/xms,
    'remove_class_translation() throws an exception when called with an empty name.',
);
throws_ok(
    sub { $translator->remove_class_translation('blahblah') },
    qr/"blahblah" [ ] is [ ] not [ ] a [ ] known [ ] translation [.]/xms,
    'remove_class_translation() throws an exception when called with a bad name.',
);


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
