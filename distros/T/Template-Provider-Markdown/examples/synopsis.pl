#!/usr/bin/env perl
use strict;

use lib '../lib';

use Template;
use Template::Provider::Markdown;
my $tt = Template->new(
    LOAD_TEMPLATES => [ Template::Provider::Markdown->new ]
);

undef $/;
$tt->process( \<DATA>, { author => "Charlie" } );

__DATA__
My name is [% author %]
How are you ?

Here is an example of [link](http://cpan.org) in *Markdown*
syntax.
