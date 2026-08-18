#!perl

# The one entry point: template and data in, PDF bytes out.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PDF::Make::Markup::Render;

my $R = 'PDF::Make::Markup::Render';

eval { require Template::Stencil; 1 }
    or plan skip_all => 'Template::Stencil required';

my $dir = tempdir(CLEANUP => 1);

my $TPL = <<'TPL';
<doc page-size="A4" margin="36">
  <style h1="size:20;colour:#1a1a2e" />
  <h1>Invoice {% invoice.number %}</h1>
  <text>Amount due: <b>{% invoice.total | money %}</b> from {% invoice.customer %}.</text>
  <table>
    {% for l in invoice.lines %}
    <tr><td>{% l.name %}</td><td align="right">{% l.qty %}</td></tr>
    {% end %}
  </table>
</doc>
TPL

my $DATA = {
    invoice => {
        number   => 1042,
        total    => 1240.5,
        customer => 'Smith & Sons',
        lines    => [ { name => 'Widget', qty => 2 },
                      { name => 'Gadget', qty => 1 } ],
    },
};

subtest 'a template and its data become a PDF' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $bytes = $R->render($TPL, $DATA);
    ok defined $bytes && length $bytes, 'got bytes back';
    like $bytes, qr/\A%PDF-/, 'which start like a PDF';
    like $bytes, qr/%%EOF\s*\z/, 'and end like one';
};

subtest 'the same input twice is the same bytes' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $a = $R->render($TPL, $DATA);
    my $b = $R->render($TPL, $DATA);
    is length($a), length($b), 'same length';
    ok $a eq $b, 'byte identical - the engine version promise is checkable';
};

subtest 'different data means different bytes' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $a = $R->render($TPL, $DATA);
    my %other = %$DATA;
    $other{invoice} = { %{ $DATA->{invoice} }, number => 1043 };
    my $b = $R->render($TPL, \%other);
    isnt $a, $b, 'the document actually depends on the data';
};

subtest 'file_name writes the file and still returns the bytes' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $bytes = $R->render($TPL, $DATA, file_name => "$dir/inv");
    ok -s "$dir/inv.pdf", 'the file is there';

    open my $fh, '<:raw', "$dir/inv.pdf" or die $!;
    local $/;
    my $on_disk = <$fh>;
    close $fh;
    is $on_disk, $bytes, 'and matches what was returned';
};

subtest 'render_markup skips the template stage' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $bytes = $R->render_markup('<doc><h1>Hand written</h1></doc>');
    like $bytes, qr/\A%PDF-/, 'renders markup directly';
};

# ---- the version gate -------------------------------------------------------

subtest 'engine versions are gated, not guessed' => sub {
    is $R->engine_version, 1, 'this build renders version 1';
    is_deeply [ $R->supported ], [ 1 ], 'and supports exactly that';

    my $bytes = eval { $R->render_markup('<doc><h1>x</h1></doc>', engine_version => 1) };
    ok defined $bytes, 'the current version renders';

    eval { $R->render_markup('<doc><h1>x</h1></doc>', engine_version => 2) };
    like $@, qr/engine version 2 is not available/, 'a future version is refused';
    like $@, qr/written for a newer engine/, '  and says which direction';

    eval { $R->render_markup('<doc><h1>x</h1></doc>', engine_version => 0) };
    like $@, qr/has been retired/, 'a retired version says so instead';

    eval { $R->render_markup('<doc><h1>x</h1></doc>', engine_version => 'latest') };
    like $@, qr/is not a version number/,
        '"latest" is refused: pinning to a moving target is the thing being prevented';
};

# ---- errors reach the caller with their positions ---------------------------

subtest 'errors from every stage keep their position' => sub {
    eval { $R->render('<doc><text>{% raw v %}</text></doc>', { v => 1 }) };
    like $@, qr/\{% raw %\} is not available/, 'a profile refusal';

    eval { $R->render('<doc><nope/></doc>', {}) };
    like $@, qr/markup error at line 1.*unknown tag/, 'a parse error';

    eval { $R->render(qq{<doc>\n  <h1 size="huge">x</h1>\n</doc>}, {}) };
    like $@, qr/size 'huge' is not a number of points at line 2/, 'a build error';

    eval { $R->render('<doc><text>{% missing %}</text></doc>', {}) };
    ok $@, 'and a template error';
};

subtest 'a template cannot inject document structure through this path either' => sub {
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;
    my $plain = $R->render('<doc><text>{% v %}</text></doc>', { v => 'safe' });
    my $evil  = $R->render('<doc><text>{% v %}</text></doc>',
                           { v => '</text><pagebreak/><h1>X</h1><text>' });
    # The hostile payload is longer text, so the documents differ - but both
    # must be one page: an injected pagebreak would have made two.
    for my $case ([ $plain, 'plain' ], [ $evil, 'hostile' ]) {
        my ($bytes, $name) = @$case;
        my $pages = () = $bytes =~ m{/Type\s*/Page\b}g;
        is $pages, 1, "the $name payload produced a single page";
    }
};

# ---------------------------------------------------------------------------
# Blocks stack, inside a <box> as much as outside it.
#
# Two bugs met here. A <text size="20"> kept the base font's leading, so the
# block after it was drawn through it; and inside a <box> every block child
# was treated as inline, so a whole certificate flowed onto one line.

sub baselines {
    my ($tpl) = @_;
    my $bytes = $R->render($tpl, {});
    my @y;
    my $size;
    for my $chunk ($bytes =~ /stream\r?\n(.*?)\r?\nendstream/gs) {
        next unless $chunk =~ /Tj/;
        for my $line (split /\n/, $chunk) {
            $size = $1 if $line =~ m{/\S+\s+([\d.]+)\s+Tf};
            push @y, [ $size, $2 ]
                if $line =~ /^(?:1 0 0 1 )?([\d.]+) ([\d.]+) (?:Tm|Td)/;
        }
    }
    return @y;
}

my $BLOCKS = <<'X';
  <text size="11">alpha</text>
  <text size="20">beta</text>
  <text size="10">gamma</text>
X

for my $case (['bare', $BLOCKS],
              ['in a box', qq{<box pad="12" border="#333">\n$BLOCKS</box>}]) {
    my ($what, $body) = @$case;
    my @y = baselines(
        qq{<doc page-size="A4" margin="36">\n<style text="size:12" />\n$body</doc>});

    is scalar @y, 3, "three blocks, three baselines ($what)";
    is_deeply [ map { $_->[0] } @y ], [ '11', '20', '10' ],
        "each block keeps its own size ($what)";

    ok $y[0][1] > $y[1][1], "the second block sits below the first ($what)";
    ok $y[1][1] > $y[2][1], "and the third below the second ($what)";

    # The gap under a 20pt block has to clear 20pt, or its glyphs are drawn
    # through the line above: that is the collision this guards.
    cmp_ok $y[1][1] + 20, '<=', $y[0][1] + 0.001,
        "a 20pt block gets 20pt of room, not the base font's ($what)";
}

# spacing separates the blocks stacked in a box, and the box grows by
# exactly that much - the row is measured with the same slot the renderer
# draws with, or it is sized for less than it draws and the last line goes
# missing under the bottom edge.
{
    my $blocks = sub {
        my ($sp) = @_;
        my $s = $sp ? qq{ spacing="$sp"} : '';
        return qq{<box pad="10" border="#333">
  <text size="10"$s>alpha</text>
  <text size="10"$s>beta</text>
  <text size="10">gamma</text>
</box>};
    };
    my $doc = sub {
        qq{<doc page-size="A4" margin="36">\n<style text="size:12" />\n}
        . $blocks->($_[0]) . "\n</doc>";
    };

    my @flat = baselines($doc->(0));
    my @gap  = baselines($doc->(12));

    is scalar @gap, 3, 'every block still drawn with spacing on';

    is sprintf('%.0f', $flat[0][1] - $flat[1][1]), '10',
        'without spacing the blocks are one line height apart';
    is sprintf('%.0f', $gap[0][1] - $gap[1][1]), '22',
        'with spacing="12" they are a line height plus the spacing apart';

    # The box itself has to absorb it: two spaced blocks, two gaps.
    my ($flat_h) = $R->render($doc->(0), {})  =~ /([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+) re/
        ? $4 : undef;
    my ($gap_h)  = $R->render($doc->(12), {}) =~ /([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+) re/
        ? $4 : undef;
    is sprintf('%.0f', $gap_h - $flat_h), '24',
        'and the box grows by the spacing it now holds';

    # Nothing fell off the bottom: the last baseline clears the box floor.
    my ($gap_y) = $R->render($doc->(12), {}) =~ /([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+) re/
        ? $2 : undef;
    cmp_ok $gap[-1][1], '>=', $gap_y, 'the last block is inside the box';
}

done_testing;
