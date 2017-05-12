#!/usr/bin/perl
use strict;
use warnings;
use Carp qw(carp croak);
use Data::Dumper;

use BBCode::Parser;
use Parse::BBCode;
use HTML::BBCode;
use HTML::BBReverse;
use AUBBC;

my %subs = (
    'BBCode::Parser'  => \&parse_bb_parser,
    'Parse::BBCode'   => \&parse_p_bb,
    'HTML::BBCode'    => \&parse_html_bb,
    'HTML::BBReverse' => \&parse_bbr,
    'AUBBC'           => \&parse_aubbc,
);

my $unbalanced = <<'EOM';
[i]italic [b]bold[/b]
EOM
my $unbalanced2 = <<'EOM';
[i]italic [b]bold[/i]
EOM
my $unbalanced3 = <<'EOM';
[i]italic [code]bold[/i]
EOM
my $unknown = <<'EOM';
[some]unknown[/unknown] tag
EOM
my $forbidden = <<'EOM';
[img]forbidden[/img]
EOM
my $block = <<'EOM';
[i] italic [code]code block[/code] [/i]
EOM
my $list = <<'EOM';
[list] [*]first [*] second [/list]
EOM
my $image = <<'EOM';
[img]image.png[/img]
[img="image.png"]text[/img]
EOM
my $url = <<'EOM';
[b]test[/b] http://perl.org/
EOM
#[img=image.png][/img]
#[img=image.png]text with [b]bold[/b][/img]
#[img=image.png]text with "" quotes[/img]

my %codes = (
    unbalanced => $unbalanced,
    unbalanced2 => $unbalanced2,
    unbalanced3 => $unbalanced3,
    unknown => $unknown,
    forbidden => $forbidden,
    block => $block,
    list => $list,
    image => $image,
	url => $url,
);

for my $key (sort keys %subs) {
    my $v = $key->VERSION;
    print "\n$key\t$v\n";
    my $sub = $subs{$key};
    for my $name (sort keys %codes) {
        my $code = $codes{$name};
        my $out;
		print "======= $key $name:\n";
		my $forbid = $name eq 'forbidden' ? 1 : 0;
        eval {
            $out = $sub->($code, $forbid);
        };
        if ($@) {
            print "$key $name dies: $@\n";
            print <<"EOM";
$code=======

EOM
        }
        else {
            print "$key $name does not die\n";
            print <<"EOM";
$code=======
$out
=======

EOM
        }
    }
}



sub parse_bb_parser {
    my ($code, $forbid) = @_;
    my $p = BBCode::Parser->new(follow_links => 1);
    if ($forbid) {
        $p->forbid('IMG');
    }
    my $tree = $p->parse($code);
    my $out = $tree->toHTML();
}

sub parse_aubbc {
    my ($code, $forbid) = @_;
    my $p;
    if ($forbid) {
        $p = AUBBC->new( no_img => 1 );
    }
    else {
        $p = AUBBC->new();
    }
    my $out = $p->do_all_ubbc($code);
}

sub parse_p_bb {
    my ($code, $forbid) = @_;
    my $p = Parse::BBCode->new({
        tags => {
            b => '<b>%s</b>',
            i => '<i>%s</i>',
            url => '<a href="%{link}A">%s</a>',
            code =>'block:<div class="bbcode-code">
<div class="bbcode-code-head">Code:</div>
<pre class="bbcode-code-body">%{noparse}s
</pre>
</div>',
            'img' => '<img src="%{html}A" alt="%{html}s" title="%{html}s">',
        },
    });
	if ($forbid) {
		$p->forbid(qw/ img /);
	}
    my $out = $p->render($code);
}

sub parse_html_bb {
    my ($code, $forbid) = @_;
    my $p;
    if ($forbid) {
        $p = HTML::BBCode->new({
            allowed_tags => [
                qw/ b i code url list /
            ],
        });
    }
    else {
        $p = HTML::BBCode->new();
    }
    my $out = $p->parse($code);
}

sub parse_bbr {
    my ($code, $forbid) = @_;
    my $p;
    if ($forbid) {
        $p = HTML::BBReverse->new(
            allowed_tags => [
                qw/ b i code url list /
            ],
        );
    }
    else {
        $p = HTML::BBReverse->new(
        );
    }
    my $out = $p->parse($code);
}
