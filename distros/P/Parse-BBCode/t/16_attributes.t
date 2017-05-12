use Test::More tests => 6;
use Parse::BBCode;
use strict;
use warnings;

package
    Parse::BBCode::MyAttr;
use base 'Parse::BBCode';

sub parse_attributes {
    my ($self, %args) = @_;
    my $text = $args{text};
    my $tagname = $args{tag};
    if ($tagname eq 'b') {
        my $attr_string = '';
        my $end = '';
        my @array = [''];
        my $i = 0;
        while ($$text =~ s/( )([^\]\s]+)//) {
            $i++;
            my $val = $2;
            $attr_string .= "$1$2";
            push @array, [$i, $val];
        }
        if ($$text =~ s/^\]//) {
            $end = ']';
        }
        else {
            return (0, [], $attr_string, $end);
        }
        return (1, [@array], $attr_string, $end);
    }
    elsif ($tagname eq 'quote') {
        my $attr_string = '';
        my $end = '';
        my @array;
        if ($$text =~ s/=([^,]+),(\d{2}\.\d{2}\.\d{4}, \d{2}:\d{2})\]//) {
            my $nick = $1;
            my $date = $2;
            $attr_string = "=$nick,$date";
            $end = ']';
            @array = ["$nick, $date"];
            return (1, [@array], $attr_string, $end);
        }
        else {
            return (0, [], $attr_string, $end);
        }
    }
    else {
        return shift->SUPER::parse_attributes(@_);
    }
}

package main;
my $parse_attributes = \&Parse::BBCode::MyAttr::parse_attributes;
my $p = Parse::BBCode::MyAttr->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            'quote' => {
                code => sub {
                    my ($parser, $attr, $content) = @_;
                    my $title = 'Quote';
                    if ($attr) {
                        $title = Parse::BBCode::escape_html($attr);
                    }
                    return <<"EOM";
<div class="bbcode_quote_header">$title:
<div class="bbcode_quote_body">$$content</div></div>
EOM
                },
                parse => 1,
                class => 'block',
            },
            test_attr => {
                code => sub {
                    my ($parser, $attr, $content, undef, $tag) = @_;
                    return $tag->get_attr_raw;
                },
            },
        },
    }
);
my $sr = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            'quote' => {
                code => sub {
                    my ($parser, $attr, $content) = @_;
                    my $title = 'Quote';
                    if ($attr) {
                        $title = Parse::BBCode::escape_html($attr);
                    }
                    return <<"EOM";
<div class="bbcode_quote_header">$title:
<div class="bbcode_quote_body">$$content</div></div>
EOM
                },
                parse => 1,
                class => 'block',
            },
            test_attr => {
                code => sub {
                    my ($parser, $attr, $content, undef, $tag) = @_;
                    return $tag->get_attr_raw;
                },
            },
        },
        attribute_parser => $parse_attributes,
    }
);
my @tests = (
    [ qq#test [b foo bar]bold[/b]#,
        q#test <b>bold</b># ],
    [ qq#test [quote=username,27.09.2011, 18:30]quoted[/quote]#,
        q#test <div class="bbcode_quote_header">username, 27.09.2011, 18:30:<div class="bbcode_quote_body">quoted</div></div># ],
    [ qq#test [test_attr=foo_bar]boo[/test_attr]#,
        q#test =foo_bar# ],
    [ qq#test [b foo bar]bold[/b]#,
        q#test <b>bold</b>#, $sr ],
    [ qq#test [quote=username,27.09.2011, 18:30]quoted[/quote]#,
        q#test <div class="bbcode_quote_header">username, 27.09.2011, 18:30:<div class="bbcode_quote_body">quoted</div></div>#, $sr ],
    [ qq#test [test_attr=foo_bar]boo[/test_attr]#,
        q#test =foo_bar#, $sr ],
);
for my $test (@tests) {
    my ($text, $exp, $parser) = @$test;
    $parser ||= $p;
    my $parsed = $parser->render($text);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    s/[\r\n]//g for ($exp, $parsed);
    $text =~ s/[\r\n]//g;
    cmp_ok($parsed, 'eq', $exp, "parse '$text'");
}



