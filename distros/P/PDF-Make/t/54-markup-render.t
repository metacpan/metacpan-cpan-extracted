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

done_testing;
