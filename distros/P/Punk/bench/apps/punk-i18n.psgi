#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();

# BENCH-HEADER: Accept-Language: fr-CA,fr;q=0.9,en;q=0.5

# punk-page.psgi with translations. Same 20 rows, same layout, same view
# registry and the same Stencil renderer - the only thing added is 40
# lookups through the tied `locale` hash, so
#
#     punk-i18n - punk-page = what i18n costs
#
# to within the handful of literal template runs the labels block adds.
# Measured on its own, punk-i18n would be measuring Stencil.
#
# The 40 keys are deliberately 12 one-segment, 15 two-segment and 13
# three-segment. Depth is the whole point: the flat dotted key of 0.48 is
# one probe whatever its depth, and a tree walk is one probe per segment,
# so a catalogue of only top-level keys would hide the regression this
# benchmark exists to find.
#
# The Accept-Language header above picks `fr`, which is complete, so what
# is measured is the hit path. Falling back to the default catalogue costs
# a second lookup and is a different number; en-GB is here only so the
# arena holds more than one locale.

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

# Hand-rolled rather than through a JSON encoder: bench/ must not acquire a
# dependency the dist does not already have at runtime, and the shape here
# is known.
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

# The labels block: 40 lookups, in the order the lists above declare them.
my $labels = join '', map { "<li>{% locale.$_ %}</li>\n" } (
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
    print $fh "<h1>{% title %}</h1>\n<ul>\n$labels</ul>\n<table>\n"
        . "{% for row in rows %}<tr><td>{% row.id %}</td>"
        . "<td>{% row.name %}</td><td>{% row.price %}</td></tr>\n"
        . "{% end %}</table>\n";
    close $fh;
}

# identical to punk-page.psgi, and for the same reason: a Perl-coderef
# filter in the template would benchmark the callback boundary
my $rows = [ map { { id => $_, name => "item $_",
                     price => sprintf '%.2f', $_ * 1.5 } } 1 .. 20 ];

package BenchI18n;
use Punk;

plugin 'I18n' => { dir => "$cat", default => 'en' };

views Stencil => {
    template_dir => "$dir",
    wrapper      => 'layout.tmpl',
};

get '/' => sub {
    $_[0]->render('rows', { title => 'Bench', rows => $rows });
};

package main;
# keep both tempdirs alive for the server's lifetime
our @KEEP_TEMPDIR = ($cat, $dir);
BenchI18n->to_app;
