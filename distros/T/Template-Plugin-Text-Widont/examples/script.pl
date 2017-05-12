#!/usr/bin/perl -wT

use strict;
use warnings;

use Template;

my $tt = Template->new({
    PLUGINS => {
        'Text::Widont' => 'Template::Plugin::Text::Widont',
    },
});

$tt->process( 'template.tt' );
