#!/usr/bin/env perl

use strict;
use warnings;

use Encode;
use Template;

sub usage {
    print <<EOF;
usage: $0 [limit length]
    (ex) % echo "good morning" | $0 10
EOF
}

unless (@ARGV) {
    usage();
    exit;
}

my $limit = shift @ARGV;
unless ($limit =~ m/^\d+$/) {
    die "limit length is not digit.";
}

my $tt = Template->new({
    PLUGINS => {
        VisualTruncate => 'Template::Plugin::Filter::VisualTruncate'
    }
});
my $content = do {
    local $/; # enable "slurp" mode
    <STDIN>;  # whole file now here
};
my $template = qq/[% USE VisualTruncate %][% FILTER visual_truncate($limit) %][% content %][% END %]/;

my $out;
$tt->process(\$template, { content => $content }, \$out);

print $out,"\n";
