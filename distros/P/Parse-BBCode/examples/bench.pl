#!/usr/bin/perl
use strict;
use warnings;
use Carp qw(carp croak);
use Data::Dumper;
use Benchmark;

my %loaded;
for (qw/ BBCode::Parser Parse::BBCode HTML::BBCode HTML::BBReverse AUBBC /) {
    eval "use $_";
    unless ($@) {
        $loaded{$_} = $_->VERSION;
    }
}
print "Benchmarking...\n";
for my $key (sort keys %loaded) {
    print "$key\t$loaded{$key}\n";
}


my $code = <<'EOM';
[b]bold [i]italic[/i] test[/b]
[code]some [perl] code[/code]
[url=http://foo.example.org/]a link![/url]

EOM

my ($count, $multiply) = @ARGV;
$multiply ||= 1;
$code = $code x $multiply;

sub create_au {
    my $pb = AUBBC->new();
    return $pb;
}

sub create_pb {
    my $pb = Parse::BBCode->new({
        tags => {
            b => '<b>%s</b>',
            i => '<i>%s</i>',
            url => '<a href="%{link}A">%s</a>',
            code =>'block:<div class="bbcode-code">
<div class="bbcode-code-head">Code:</div>
<pre class="bbcode-code-body">%{noparse}s
</pre>
</div>',
        },
    });
    return $pb;
}

sub create_hb {
    my $bbc  = HTML::BBCode->new();
    return $bbc;
}

sub create_bp {
    my $parser = BBCode::Parser->new(follow_links => 1);
    return $parser;
}

sub create_bbr {
    my $bbr = HTML::BBReverse->new();
    return $bbr;
}

my ($pb, $bp, $hb, $bbr, $au);
if ($loaded{'Parse::BBCode'}) {
    $pb = create_pb();
    my $rendered1 = $pb->render($code);
    #print "$rendered1\n";
}
if ($loaded{'BBCode::Parser'}) {
    $bp = create_bp();
    my $tree = $bp->parse($code);
    my $rendered2 = $tree->toHTML();
    #print "$rendered2\n";
}
if ($loaded{'HTML::BBCode'}) {
    $hb = create_hb();
    my $rendered3 = $hb->parse($code);
    #print "$rendered3\n";
}
if ($loaded{'HTML::BBReverse'}) {
    $bbr = create_bbr();
    my $rendered4 = $bbr->parse($code);
    #print "$rendered4\n";
}
if ($loaded{'AUBBC'}) {
    $au = create_au();
    my $rendered5 = $au->do_all_ubbc($code);
    #print "$rendered4\n";
}


timethese($count || -1, {
    $loaded{'Parse::BBCode'} ?  (
        'P::B::new'  => \&create_pb,
        'P::B'  => sub { my $out = $pb->render($code) },
    ) : (),
    $loaded{'HTML::BBCode'} ?  (
        'H::B::new'  => \&create_hb,
        'H::B'  => sub { my $out = $hb->parse($code) },
    ) : (),
    $loaded{'BBCode::Parser'} ?  (
        'B::P::new' => \&create_bp,
        'B::P' => sub { my $tree = $bp->parse($code); my $out = $tree->toHTML(); },
    ) : (),
    $loaded{'HTML::BBReverse'} ?  (
        'BBR::new' => \&create_bbr,
        'BBR' => sub { my $out = $bbr->parse($code); },
    ) : (),
    $loaded{'AUBBC'} ?  (
        'AUBBC::new' => \&create_bbr,
        'AUBBC' => sub { my $out = $au->do_all_ubbc($code); },
    ) : (),
});
