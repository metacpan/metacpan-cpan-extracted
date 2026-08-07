#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();

# The fair ceiling for punk-page: the identical page bytes, pre-rendered
# once, served by a bare PSGI app - isolates Punk + Stencil render cost
# from the cost of moving a 1.2KB body instead of 5 bytes.

my $dir = File::Temp->newdir;
{
    open my $fh, '>', "$dir/layout.tmpl" or die $!;
    print $fh "<!doctype html>\n<html><head><title>{% title %}</title></head>\n"
        . "<body>{% content %}</body></html>\n";
    close $fh;
    open $fh, '>', "$dir/rows.tmpl" or die $!;
    print $fh "<h1>{% title %}</h1>\n<table>\n"
        . "{% for row in rows %}<tr><td>{% row.id %}</td>"
        . "<td>{% row.name %}</td><td>{% row.price | money %}</td></tr>\n"
        . "{% end %}</table>\n";
    close $fh;
}

my $rows = [ map { { id => $_, name => "item $_", price => $_ * 1.5 } }
             1 .. 20 ];

require Template::Stencil;
my $body = Template::Stencil->new(
    template_dir => "$dir",
    wrapper      => 'layout.tmpl',
    filters      => { money => sub { sprintf '%.2f', $_[0] } },
)->render('rows', { title => 'Bench', rows => $rows });

my @headers = ('Content-Type' => 'text/html; charset=utf-8',
               'Content-Length' => length $body);

sub { [ 200, \@headers, [$body] ] };
