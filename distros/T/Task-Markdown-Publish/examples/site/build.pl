#!/usr/bin/env perl

use strict;
use warnings;

use Markdown::Publish;

my $publish_or=Markdown::Publish->new({
    module  => 'mkdocs',
    name    => 'Example documentation',
    sources => ['doc'],
});
$publish_or->build();
