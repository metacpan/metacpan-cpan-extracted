#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();

# A rendered 20-row Stencil page through the full Punk dispatch:
# routing, context, view registry, Stencil's C renderer, finalize.

my $dir = File::Temp->newdir;
{
    open my $fh, '>', "$dir/layout.tmpl" or die $!;
    print $fh "<!doctype html>\n<html><head><title>{% title %}</title></head>\n"
        . "<body>{% content %}</body></html>\n";
    close $fh;
    open $fh, '>', "$dir/rows.tmpl" or die $!;
    print $fh "<h1>{% title %}</h1>\n<table>\n"
        . "{% for row in rows %}<tr><td>{% row.id %}</td>"
        . "<td>{% row.name %}</td><td>{% row.price %}</td></tr>\n"
        . "{% end %}</table>\n";
    close $fh;
}

# prices pre-formatted at data-build time: a Perl-coderef filter in the
# template costs a C-to-Perl crossing per cell (20/request here) and
# triples the render cost - that would benchmark the callback boundary,
# not the page path
my $rows = [ map { { id => $_, name => "item $_",
                     price => sprintf '%.2f', $_ * 1.5 } } 1 .. 20 ];

package BenchPage;
use Punk;

views Stencil => {
    template_dir => "$dir",
    wrapper      => 'layout.tmpl',
};

get '/' => sub {
    $_[0]->render('rows', { title => 'Bench', rows => $rows });
};

package main;
# keep the tempdir alive for the server's lifetime
our $KEEP_TEMPDIR = $dir;
BenchPage->to_app;
