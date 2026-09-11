#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();

# BENCH-HEADER: Accept-Language: fr-CA,fr;q=0.9,en;q=0.5

# The SAME 40 translations as punk-i18n.psgi, fetched through the fast door
# - $c->locale($key) - instead of the tied `locale` hash.
#
# Two apps because the two doors move in opposite directions under the
# Frozen migration and one number cannot show both:
#
#   punk-i18n-fn  measures the FUNCTION door. It gets SLOWER: a dotted key
#                 was one FNV-1a probe whatever its depth, and becomes one
#                 probe per segment. This is what stop condition S1 is
#                 about.
#   punk-i18n     measures the TIED door. It gets FASTER: FETCH stops
#                 rebuilding the joined key and re-walking from the
#                 catalogue root on every segment.
#
# Measured together they would cancel, and a regression on the door most
# request paths use would ship invisibly.
#
# The template does one `for` over a prepared list, so what separates this
# from punk-page is 40 $c->locale calls and one loop, not 40 more template
# lookups.

my $cat = File::Temp->newdir;
my $dir = File::Temp->newdir;

my @ONE = qw(title subtitle heading footer greeting tagline
             copyright search login logout help back);
my %TWO = (
    columns => [qw(id name price)],
    nav     => [qw(home about contact)],
    status  => [qw(ok error pending)],
    units   => [qw(each pair dozen)],
    filter  => [qw(all new sale)],
);
my %THREE = (
    form => { buttons => [qw(save cancel reset)],
              labels  => [qw(email password name)] },
    msg  => { error   => [qw(notfound denied timeout)],
              ok      => [qw(saved sent)] },
    cart => { summary => [qw(total shipping)] },
);

sub catalogue {
    my ($mark) = @_;
    my %c;
    $c{$_} = "$mark $_" for @ONE;
    for my $k (keys %TWO) {
        $c{$k} = { map { $_ => "$mark $k $_" } @{ $TWO{$k} } };
    }
    for my $k (keys %THREE) {
        for my $j (keys %{ $THREE{$k} }) {
            $c{$k}{$j} = { map { $_ => "$mark $k $j $_" } @{ $THREE{$k}{$j} } };
        }
    }
    return \%c;
}

sub as_json {
    my ($d, $ind) = @_;
    $ind ||= 0;
    my $pad = '  ' x ($ind + 1);
    return '"' . $d . '"' unless ref $d;
    return "{\n" . join(",\n",
        map { $pad . '"' . $_ . '": ' . as_json($d->{$_}, $ind + 1) }
        sort keys %$d) . "\n" . ('  ' x $ind) . '}';
}

for my $tag (qw(en fr)) {
    open my $fh, '>:raw', "$cat/$tag.json" or die $!;
    print $fh as_json(catalogue($tag));
    close $fh;
}
{
    open my $fh, '>:raw', "$cat/en-GB.json" or die $!;
    print $fh '{ "title": "en-GB title", "footer": "en-GB footer" }';
    close $fh;
}

# the same 40 keys, in the same order, as dotted paths for the fast door
our @KEYS = (
    @ONE,
    (map { my $k = $_; map { "$k.$_" } @{ $TWO{$k} } } sort keys %TWO),
    (map { my $k = $_;
           map { my $j = $_; map { "$k.$j.$_" } @{ $THREE{$k}{$j} } }
           sort keys %{ $THREE{$k} } } sort keys %THREE),
);

{
    open my $fh, '>', "$dir/layout.tmpl" or die $!;
    print $fh "<!doctype html>\n<html><head><title>{% title %}</title></head>\n"
        . "<body>{% content %}</body></html>\n";
    close $fh;
    open $fh, '>', "$dir/rows.tmpl" or die $!;
    print $fh "<h1>{% title %}</h1>\n<ul>\n"
        . "{% for l in labels %}<li>{% l %}</li>\n{% end %}</ul>\n<table>\n"
        . "{% for row in rows %}<tr><td>{% row.id %}</td>"
        . "<td>{% row.name %}</td><td>{% row.price %}</td></tr>\n"
        . "{% end %}</table>\n";
    close $fh;
}

my $rows = [ map { { id => $_, name => "item $_",
                     price => sprintf '%.2f', $_ * 1.5 } } 1 .. 20 ];

package BenchI18nFn;
use Punk;

plugin 'I18n' => { dir => "$cat", default => 'en' };

views Stencil => {
    template_dir => "$dir",
    wrapper      => 'layout.tmpl',
};

get '/' => sub {
    my $c = shift;
    $c->render('rows', {
        title  => 'Bench',
        rows   => $rows,
        labels => [ map { $c->locale($_) } @main::KEYS ],
    });
};

package main;
our @KEEP_TEMPDIR = ($cat, $dir);
BenchI18nFn->to_app;
