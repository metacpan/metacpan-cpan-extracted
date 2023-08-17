#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Test::More;

use Mojo::DOM;
use Test::MockObject;

BEGIN {
    use_ok 'Statocles::Plugin::Highlight::Kamelon';
}

my %helper;
my $style_url;

my $theme = Test::MockObject->new;
$theme->mock('helper', sub { shift; %helper = @_ });
$theme->mock('url', sub { $style_url = $_[1] });

my $site = Test::MockObject->new;
$site->mock('theme', sub {$theme});

my $links = Test::MockObject->new;
$links->set_always('href', '/css/default.css');

my $page = Test::MockObject->new;
$page->mock('site',  sub {$site});
$page->mock('links', sub {$links});

my $plugin = new_ok 'Statocles::Plugin::Highlight::Kamelon' =>
    [style => 'solarized-light'];

can_ok $plugin, qw(highlight register style);

$plugin->register($site);

my $highlight = $helper{highlight};

isa_ok $highlight, 'CODE';

my $args = {page => $page};

ok !eval { $highlight->($args, 'non-existent syntax', q{}) },
    'highlight with non-existent syntax dies';

{
    my $html = $highlight->($args, 'Perl', q{print "hello, world\n"});
    my $dom  = Mojo::DOM->new($html);
    like $dom->at('pre code.hljs span.hljs-string')->text, qr{hello, world},
        'text is highlighted';
    like $style_url, qr{\Qsolarized-light.css\E},
        'style sheet file is solarized-light.css';
}

{
    my $html = $highlight->(
        {self => $page},
        -style => 'solarized-dark',
        'perl',
        sub {q{print "hello, world\n")}}
    );
    my $dom = Mojo::DOM->new($html);
    like $dom->at('pre code.hljs span.hljs-string')->text, qr{hello, world},
        'text is highlighted';
    like $style_url, qr{\Qsolarized-dark.css\E},
        'style sheet file is solarized-dark.css';
}

{
    my $html = $highlight->($args, 'perl', q{    # four spaces});
    my $dom  = Mojo::DOM->new($html);
    unlike $dom->all_text, qr{^[ ]{4}}, 'no leading spaces';
}

{
    my $html = $highlight->($args, 'perl', qq{\t# one tab});
    my $dom  = Mojo::DOM->new($html);
    unlike $dom->all_text, qr{^\t}, 'no leading tab';
}

done_testing;
