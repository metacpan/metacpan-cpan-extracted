#!perl
# Benchmark Template::Stencil against other engines on the reference
# workload (a ~1 KB page: 3 variables, a conditional, a 10-item loop)
# and report ops/sec plus the v0.01 performance targets.
#
#   perl -Mblib bench/compare.pl [iterations]
#
# Comparators are optional; absent ones are skipped. Exits non-zero if
# a measurable gate fails (bench/ is not part of make test - run it by
# hand or from CI that tolerates timing noise).

use 5.016;
use strict;
use warnings;
use Time::HiRes ();
use File::Temp  ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Template::Stencil;

my $iters = shift(@ARGV) || 50_000;

my $pad = '<p class="pad">' . ('lorem ipsum dolor sit amet ' x 20)
        . "</p>\n";

my %data = (
    title   => 'Reference Page',
    heading => 'A heading with <specials> & "quotes"',
    user    => 'lnation',
    items   => [ map { { name => "item $_", desc => "desc $_" } } 1 .. 10 ],
);

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub put {
    my ($name, $content) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $content;
    close $fh;
}

# ---- the same page in each engine's syntax --------------------------

put('page.stencil', <<"T");
<html><head><title>{% title %}</title></head><body>
<h1>{% heading %}</h1>
{% if user %}<p class="user">{% user %}</p>{% end %}
$pad<ul>
{% for item in items %}<li>{% item.name %} - {% item.desc %}</li>
{% end %}</ul>
</body></html>
T

put('page.tt', <<"T");
<html><head><title>[% title %]</title></head><body>
<h1>[% heading | html %]</h1>
[% IF user %]<p class="user">[% user %]</p>[% END %]
$pad<ul>
[% FOREACH item IN items %]<li>[% item.name %] - [% item.desc %]</li>
[% END %]</ul>
</body></html>
T

put('page.ht', <<"T");
<html><head><title><TMPL_VAR NAME=title></title></head><body>
<h1><TMPL_VAR NAME=heading ESCAPE=HTML></h1>
<TMPL_IF NAME=user><p class="user"><TMPL_VAR NAME=user></p></TMPL_IF>
$pad<ul>
<TMPL_LOOP NAME=items><li><TMPL_VAR NAME=name> - <TMPL_VAR NAME=desc></li>
</TMPL_LOOP></ul>
</body></html>
T

put('page.tx', <<"T");
<html><head><title><: \$title :></title></head><body>
<h1><: \$heading :></h1>
: if \$user {
<p class="user"><: \$user :></p>
: }
$pad<ul>
: for \$items -> \$item {
<li><: \$item.name :> - <: \$item.desc :></li>
: }
</ul>
</body></html>
T

my $tt_text = <<"T";
<html><head><title>{\$title}</title></head><body>
<h1>{\$heading}</h1>
{ \$user ? qq[<p class="user">\$user</p>] : '' }
$pad<ul>
{ join '', map { "<li>\$_->{name} - \$_->{desc}</li>\\n" } \@items }</ul>
</body></html>
T

# ---- runners: each returns a closure rendering one page -------------

my %runner;

{
    my $s = Template::Stencil->new(template_dir => $dir, stat_ttl => -1);
    $s->render('page.stencil', \%data);
    $runner{'Template::Stencil'} = sub {
        Template::Stencil::render($s, 'page.stencil', \%data);
    };
}

{
    # the honest hand-written comparison point
    my $esc = sub {
        my $x = shift;
        $x =~ s/&/&amp;/g; $x =~ s/</&lt;/g; $x =~ s/>/&gt;/g;
        $x =~ s/"/&quot;/g; $x =~ s/'/&#39;/g;
        $x;
    };
    $runner{'hand-written perl'} = sub {
        my $out = '<html><head><title>' . $esc->($data{title})
                . "</title></head><body>\n<h1>" . $esc->($data{heading})
                . "</h1>\n"
                . ($data{user}
                    ? '<p class="user">' . $esc->($data{user}) . '</p>'
                    : '')
                . "\n" . $pad . "<ul>\n"
                . join('',
                    map { '<li>' . $esc->($_->{name}) . ' - '
                        . $esc->($_->{desc}) . "</li>\n" }
                    @{ $data{items} })
                . "</ul>\n</body></html>\n";
        $out;
    };
}

if (eval { require Text::Xslate; 1 }) {
    # the reigning fast XS engine - the comparison that matters
    my $tx = Text::Xslate->new(path => [$dir], cache_dir => $dir,
                               cache => 1);
    $tx->render('page.tx', \%data);
    $runner{'Text::Xslate'} = sub {
        $tx->render('page.tx', \%data);
    };
}

if (eval { require Template; 1 }) {
    my $tt = Template->new(INCLUDE_PATH => $dir, CACHE_SIZE => 64);
    my $out;
    $tt->process('page.tt', \%data, \$out) or die $tt->error;
    $runner{'Template::Toolkit'} = sub {
        my $o = '';
        $tt->process('page.tt', \%data, \$o) or die $tt->error;
        $o;
    };
}

if (eval { require HTML::Template; 1 }) {
    my $make = sub {
        HTML::Template->new(filename => "$dir/page.ht", cache => 1,
                            die_on_bad_params => 0);
    };
    $runner{'HTML::Template'} = sub {
        my $ht = $make->();
        $ht->param(%data);
        $ht->output;
    };
}

if (eval { require Text::Template; 1 }) {
    no warnings 'once';
    my $t = Text::Template->new(TYPE => 'STRING', SOURCE => $tt_text)
        or die $Text::Template::ERROR;
    $runner{'Text::Template'} = sub {
        $t->fill_in(HASH => {
            title => $data{title}, heading => $data{heading},
            user => $data{user}, items => [ @{ $data{items} } ],
        });
    };
}

# ---- measure --------------------------------------------------------

my %rate;
for my $name (sort keys %runner) {
    my $fn = $runner{$name};
    my $n  = $name eq 'Template::Stencil' || $name eq 'hand-written perl'
          || $name eq 'Text::Xslate'
        ? $iters : int($iters / 10) || 1;
    $fn->() for 1 .. 50;   # warm
    my $t0 = Time::HiRes::time();
    $fn->() for 1 .. $n;
    my $dt = Time::HiRes::time() - $t0;
    $rate{$name} = $n / $dt;
}

my $base = $rate{'Template::Stencil'};
printf "%-22s %12s %10s %9s\n", 'engine', 'ops/sec', 'ns/op', 'relative';
for my $name (sort { $rate{$b} <=> $rate{$a} } keys %rate) {
    printf "%-22s %12.0f %10.0f %8.2fx\n", $name, $rate{$name},
        1e9 / $rate{$name}, $base / $rate{$name};
}

# cold-compile time
{
    my $src = do {
        open my $fh, '<', "$dir/page.stencil" or die $!;
        local $/; <$fh>;
    };
    my $n  = 5000;
    my $t0 = Time::HiRes::time();
    for (1 .. $n) {
        my $h = Template::Stencil::_compile_handle($src);
        Template::Stencil::_free_handle($h);
    }
    printf "\ncold compile: %.1f us for %d bytes\n",
        (Time::HiRes::time() - $t0) / $n * 1e6, length $src;
}

# ---- gates ----------------------------------------------------------

my @gates = (
    [ 'hand-written perl',  'within 2x',  sub { $base >= $_[0] / 2 } ],
    [ 'Text::Xslate',       '>= 1x',      sub { $base >= $_[0] } ],
    [ 'Text::Template',     '>= 8x',      sub { $base >= $_[0] * 8 } ],
    [ 'HTML::Template',     '>= 10x',     sub { $base >= $_[0] * 10 } ],
    [ 'Template::Toolkit',  '>= 15x',     sub { $base >= $_[0] * 15 } ],
);
my $failed = 0;
print "\ngates:\n";
for my $g (@gates) {
    my ($name, $desc, $check) = @$g;
    if (!exists $rate{$name}) {
        printf "  %-22s %-10s SKIP (not installed)\n", $name, $desc;
        next;
    }
    my $ok = $check->($rate{$name});
    printf "  %-22s %-10s %s (%.1fx)\n", $name, $desc,
        $ok ? 'PASS' : 'FAIL', $base / $rate{$name};
    $failed++ unless $ok;
}
exit($failed ? 1 : 0);
