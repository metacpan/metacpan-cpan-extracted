#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

# One template exercising every v0.01 feature at once, asserted against
# a committed golden file. This is the rendered-output spec: any change
# that alters produced bytes shows up here first. The golden is
# pretty-formatted (pretty => 1, so Eshu is required to run this file).

plan skip_all => 'Eshu required for the pretty golden'
    unless eval { require Eshu; 1 };

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub put {
    my ($name, $content) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $content;
    close $fh;
}

put('wrap.tmpl', <<'W');
<page title="{% title | default('untitled') %}">
{% content %}
</page>
W

put('side.tmpl', <<'S');
<side for="{% who.name %}" at="{% loop.index %}/{% outer.index1 %}"></side>
S

put('sink.tmpl', <<'T');
{%# every feature in one file %}
<h1>{% title | trim | upper %}</h1>
literal brace: {%%}raw%}
{% if user && user.age >= 18 %}adult {% user.name %}{% elsif user %}minor{% else %}nobody{% end %}
{% unless missing %}no-missing{% end %}
{% set greeting = 'hi "' %}{% set who = user %}
{% for item in items %}
  {% set outer = loop %}
  {% for tag in item.tags %}<t o="{% outer.index %}" i="{% loop.index %}" f="{% if loop.first %}y{% else %}n{% end %}" l="{% if loop.last %}y{% else %}n{% end %}" e="{% if loop.even %}e{% else %}o{% end %}">{% tag %}</t>{% end %}
  {% include side.tmpl %}
{% end %}
{% for k, v in map %}[{% loop.key %}={% v | upper %}]{% end %}
esc: {% evil %} raw: {% raw evil %} html: {% evil | html %} double: {% evil | html | lower %}
uri: {% link | uri %} default: {% nothing | default('<d>') %}
money: {% price | money %} chain: {% shout | trim | lower | upper %}
greeting: {% greeting %} num: {% if n == 2.5 %}two-and-a-half{% end %}
str: {% if title eq ' The Title ' %}exact{% end %} not: {% if not missing %}absent{% end %}
paths: {% deep.a[1].b %} undef-quiet: [{% deep.a[5].b %}]
T

my $s = Template::Stencil->new(
    template_dir => $dir,
    wrapper      => 'wrap.tmpl',
    pretty       => 1,
    filters      => { money => sub { sprintf '%.2f', $_[0] } },
);

my %data = (
    title => ' The Title ',
    user  => { name => 'Ada <A>', age => 36 },
    items => [
        { tags => [qw(x y)] },
        { tags => [qw(z)] },
    ],
    map   => { beta => 'b&b', alpha => 'a' },
    # all five escapables; not a <script> because Eshu's current
    # same-line script handling truncates (see phase-09 notes)
    evil  => q{<em a="1&2">'q'</em>},
    link  => "a b/c?d=e&f=caf\x{e9}",
    price => 3.5,
    shout => '  MiXeD  ',
    n     => 2.5,
    deep  => { a => [ {}, { b => 'found' } ] },
);

my $got = $s->render('sink.tmpl', \%data);

my $golden_file = 't/corpus/kitchen.golden';
if ($ENV{STENCIL_REGOLD}) {
    open my $fh, '>', $golden_file or die $!;
    print $fh $got;
    close $fh;
    diag 'kitchen golden regenerated';
}
my $want = do {
    open my $fh, '<', $golden_file or die "$golden_file: $!";
    local $/;
    <$fh>;
};
is($got, $want, 'kitchen sink matches golden');

# Determinism across repeated renders and dispatch/cache paths.
is($s->render('sink.tmpl', \%data), $got, 'second render identical');

done_testing;
