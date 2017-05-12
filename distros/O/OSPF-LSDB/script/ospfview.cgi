#!/usr/bin/perl -T

##########################################################################
# Copyright (c) 2012 Alexander Bluhm <alexander.bluhm@gmx.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##########################################################################

# use cgi script with paramter
#   format   = dot|fig|gif|pdf|png|ps|ps2|svg|svgz
#   ipv6     = 0|1
#   legend   = 0|1
#   summary  = 0|1|2
#   boundary = 0|1|2
#   external = 0|1|2
#   link     = 0|1
#   intra    = 0|1
#   cluster  = 0|1
#   warnings = 0|1|2

use strict;
use warnings;
use CGI qw(header param);
use Sys::Hostname;

use OSPF::LSDB;
use OSPF::LSDB::ospfd;
use OSPF::LSDB::ospf6d;
use OSPF::LSDB::View;
use OSPF::LSDB::View6;

$ENV{PATH} = "/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin";

my %format2content = (
    dot => {
	disposition => "attachment",
	extension   => "dot",
	type        => "text/plain",
    },
    fig => {
	disposition => "attachment",
	extension   => "fig",
	type        => "text/plain",
    },
    gif => {
	disposition => "inline",
	extension   => "gif",
	type        => "image/gif",
    },
    pdf  => {
	disposition => "attachment",
	extension   => "pdf",
	type        => "application/pdf",
    },
    png => {
	disposition => "inline",
	extension   => "png",
	type        => "image/png",
    },
    ps  => {
	disposition => "attachment",
	extension   => "ps",
	type        => "application/postscript",
    },
    ps2 => {
	disposition => "attachment",
	extension   => "ps",
	type        => "application/postscript",
    },
    svg => {
	disposition => "inline",
	extension   => "svg",
	type        => "image/svg+xml",
    },
    svgz => {
	disposition => "inline",
	extension   => "svg",
	type        => "image/svg+xml",
	encoding    => "gzip",
    },
);
my $format = "svg";
if (param('format') && $format2content{param('format')}) {
    # param('format') is a key of %format2content, untaint
    param('format') =~ /^(\w+)$/;
    $format = $1;
}

my $content = $format2content{$format};
my $v6 = param('ipv6') ? "6" : "";
(my $hostname = hostname()) =~ s/\..*//;  # short hostname
my %header = (
    -type => $content->{type},
    "Content-Disposition" => "$content->{disposition}; ".
	"filename=\"ospf${v6}_$hostname.$content->{extension}\"",
    "Content-Encoding" => $content->{encoding} || "identity",
);
print header(%header);

my $viewclass = param('ipv6') ? 'OSPF::LSDB::View6' : 'OSPF::LSDB::View';

my @dot = ('dot', "-T$format");
open(my $fh, '|-', @dot)
    or die "Open pipe for writing to '@dot' failed: $!";

if (param('legend')) {
    print $fh $viewclass->legend();
} else {
    my $ospfclass = param('ipv6') ? 'OSPF::LSDB::ospf6d' : 'OSPF::LSDB::ospfd';
    my $ospf = $ospfclass->new();
    $ospf->parse();

    my %todo;
    foreach (qw(boundary summary external link intra cluster warning)) {
	next unless defined(param($_)) && param($_) =~ /^\d+$/;
	if (/cluster/) {
	    $todo{$_}              = 1 if param($_) >= 1;
	} elsif (/warning/) {
	    $todo{$_}{all}         = 1 if param($_) == 1;
	    $todo{$_}{single}      = 1 if param($_) >= 2;
	} elsif (/link|intra/) {
	    $todo{$_}{generate}    = 1 if param($_) >= 1;
	} else {
	    $todo{$_}{generate}    = 1 if param($_) == 1;
	    $todo{$_}{aggregate}   = 1 if param($_) >= 2;
	}
    }
    my $view = $viewclass->new($ospf);
    print $fh $view->graph(%todo);
}

close($fh) or die $! ?
    "Close pipe after writing to '@dot' failed: $!" :
    "Command '@dot' failed: $?";
