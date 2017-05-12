#!/usr/bin/env perl

use utf8;
use 5.008001;

use strict;
use warnings;

use Readonly;

use version; our $VERSION = qv('v1.2.0');

use PPIx::Shorthand;

use Test::More tests => 5;


my $translator = PPIx::Shorthand->new();


$translator->add_class_translation( t => 'PPI::Token' );
is(
    $translator->get_class('t'),
    'PPI::Token',
    q<Can retrieve translation via get_class() after adding it via add_class_translation().>,
);


$translator->remove_class_translation('t');
is(
    $translator->get_class('t'),
    undef,
    q<Cannot retrieve translation via get_class() after removing it via remove_class_translation().>,
);


$translator->add_class_translation( BLAHBLAH => 'PPI::Token' );
is(
    $translator->get_class('bLaHBlAh'),
    'PPI::Token',
    q<Can retrieve added translation in a case-insensitive manner.>,
);


# Sanity check
is(
    $translator->get_class('PPI::Token'),
    'PPI::Token',
    q<Can retrieve PPI::Token via standard identity translation.>,
);

$translator->remove_class_translation('PPI::Token');
is(
    $translator->get_class('PPI::Token'),
    undef,
    q<Can delete standard identity translation of PPI::Token.>,
);


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
