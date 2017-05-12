##
# name:      Stardoc::Kwim::Parser
# abstract:  Stardoc Kwim Parser Module
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2008, 2010, 2011

package Stardoc::Kwim::Parser;
use strict;
use warnings;
use base 'WikiText::Parser';

# Reusable regexp generators used by the grammar
my $ALPHANUM = '\p{Letter}\p{Number}\pM';

# These are all stolen from URI.pm
my $reserved   = q{;/?:@&=+$,[]#};
my $mark       = q{-_.!~*'()};
my $unreserved = "A-Za-z0-9\Q$mark\E";
my $uric       = quotemeta($reserved) . $unreserved . "%";
my %im_types = (
    yahoo  => 'yahoo',
    ymsgr  => 'yahoo',
    callto => 'callto',
    skype  => 'callto',
    callme => 'callto', 
    aim    => 'aim',
    msn    => 'msn',
    asap   => 'asap',
);
my $im_re = join '|', keys %im_types;

sub create_grammar {
    my $all_phrases = [
        qw(waflphrase asis wikilink a im mail tt b i del)
    ];
    my $all_blocks = [
        qw(
            pre wafl_block
            hr hx
            waflparagraph
            ul ol
            blockquote table
            p empty
            else
        )
    ];

    return {
        _all_blocks => $all_blocks,
        _all_phrases => $all_phrases,

        top => {
            blocks => $all_blocks,
        },

        empty => {
            match => qr/^\s*\n/,
            filter => sub {
                my $node = shift;
                $node->{type} = '';
            },
        },

        wafl_block => {
            match => qr/(?:^\.([\w\-]+)\ *\n)((?:.*\n)*?)(?:\.\1\ *\n|\z)/,
        }, 

        p => {
           match =>  qr/^(            # Capture whole thing
                (?m:
                    ^(?!        # All consecutive lines *not* starting with
                    (?:
                        [\#\-\*]+[\ ] |
                        [\^\|\>] |
                        \.\w+\s*\n |
                        \{[^\}]+\}\s*\n
                    )
                    )
                    .*\S.*\n
                )+
                )
                (\s*\n)*   # and all blank lines after
            /x,
            phrases => $all_phrases,
            filter => sub { chomp },
        },

        else => {
            match => qr/^(.*)\n/,
            phrases => [],
            filter => sub {
                my $node = shift;
                $node->{type} = 'p';
            },
        },

        pre => {
            match => qr/^(?m:^\.pre\ *\n)((?:.*\n)*?)(?m:^\.pre\ *\n)(?:\s*\n)?/,
        },

        blockquote => {
            match => qr/^((?m:^>.*\n)+)(\s*\n)?/,
            blocks => $all_blocks,
            filter => sub {
                s/^>\ ?//gm;
            },
        },

        waflparagraph => {
            match => qr/^\{(.*)\}[\ \t]*\n(?:\s*\n)?/,
            filter => sub {
                my $node = shift;
                my ($function, $options) = split /[: ]/, $node->{text}, 2;
                my $replacement = defined $1 ? $1 : '';
                $options = '' unless defined $options; # protect against an undefined here
                $options =~ s/\s*(.*?)\s*/$replacement/;
                $node->{attributes}{function} = $function;
                $node->{attributes}{options} = $options;
                undef $_;
            },
        },

        hx => {
            match => qr/^(\=+) *(.*?)(\s+=+)?\s*?\n+/,
            phrases => $all_phrases,
            filter => sub {
                my $node = shift;
                $node->{type} = 'h' . length($node->{1});
                $_ = $node->{text} = $node->{2};
            },
        },

        ul => {
            match => re_list('[\*\-\+]'),
            blocks => [qw(ul ol subl li)],
            filter => sub { s/^[\*\-\+\#] *//mg },
        }, 

        ol => {
            match => re_list('\#'),
            blocks => [qw(ul ol subl li)],
            filter => sub { s/^[\*\#] *//mg },
        },

        subl => {
            type => 'li',

            match => qr/^(          # Block must start at beginning
                                    # Capture everything in $1
                (.*)\n              # Capture the whole first line
                [\*\#]+\ .*\n      # Line starting with one or more bullet
                (?:[\*\#]+\ .*\n)*  # Lines starting with '*' or '#'
            )(?:\s*\n)?/x,          # Eat trailing lines
            blocks => [qw(ul ol li2)],
        },

        li => {
            match => qr/(.*)\n/,    # Capture the whole line
            phrases => $all_phrases,
        },

        li2 => {
            type => '',
            match => qr/(.*)\n/,    # Capture the whole line
            phrases => $all_phrases,
        },

        hr => {
            match => qr/^--+(?:\s*\n)?/,
        },

        table => {
            match => qr/^(
                (
                    (?m:^\|.*\|\ \n(?=\|))
                    |
                    (?m:^\|.*\|\ \ +\n)
                    |
                    (?ms:^\|.*?\|\n)
                )+
            )(?:\s*\n)?/x,
            blocks => ['tr'],
        },

        tr => {
            match => qr/^((?m:^\|.*?\|(?:\n| \n(?=\|)|  +\n)))/s,
            blocks => ['td'],
            filter => sub { s/\s+\z// },
        },

        # XXX Need to support blocks in TD
        td => {
            match => qr/\|?\s*(.*?)\s*\|\n?/s,
            phrases => $all_phrases,
        },

        wikilink => {
            match => qr/
                (?:"([^"]*)"\s*)?(?:^|(?<=[^$ALPHANUM]))\[(?=[^\s\[\]])
                (.*?)
                \](?=[^$ALPHANUM]|\z)
            /x,
            filter => sub {
                my $node = shift;
                $node->{attributes}{target} = $node->{2};
                $_ = $node->{1} || $node->{2};
            },
        },

        b => {
            match => re_huggy(q{\*}),
            phrases => $all_phrases,
        },

        tt => {
            match => re_huggy(q{\`}),
        },

        i => {
            match => Stardoc::Kwim::Parser::re_huggy(q{\_}),
            phrases => $all_phrases,
        },

        del => {
            match => re_huggy(q{\-}),
            phrases => $all_phrases,
        },

        im => {
            match => qr/(\b(?:$im_re)\:[^\s\>\)]+)/,
            filter => sub {
                my $node = shift;
                my ($type, $id) = split /:/, $node->{text}, 2;
                $node->{attributes}{type} = $type;
                $node->{attributes}{id} = $id;
                undef $_;
            },
        },

        waflphrase => {
            match => qr/
                (?:^|(?<=[\s\-]))
                (?:"(.+?)")?
                \{
                ([\w-]+)
                (?=[\:\ \}])
                (?:\s*:)?
                \s*(.*?)\s*
                \}
                (?=[^A-Za-z0-9]|\z)
            /x,
            filter => sub {
                my $node = shift;
                my ($label, $function, $options) = @{$node}{qw(1 2 3)};
                $label ||= '';
                $node->{attributes}{function} = $function;
                $node->{attributes}{options} = $options;
                $_ = $label;
            },
        },

        mail => {
            match => qr/
                (?:"([^"]*)"\s*)?
                <?
                (?:mailto:)?
                ([\w+%\-\.]+@(?:[\w\-]+\.)+[\w\-]+)
                >?
            /x,
            filter => sub {
                my $node = shift;
                $_ = $node->{1} || $node->{2};
                $node->{attributes}{address} = $node->{2};
            },
        },

        a => {
            type => 'hyperlink',
            match => qr{
                (?:"([^"]*)"\s*)?
                <?
                (
                    (?:http|https|ftp|irc|file):
                    (?://)?
                    [$uric]+
                    [A-Za-z0-9/#]
                )
                >?
            }x,
            filter => sub {
                my $node = shift;
                $_ = $node->{1} || $node->{2};
                $node->{attributes}{target} = $node->{2};
            },
        },

        asis => {
            match => qr/
                \{\{
                (.*?)
                \}\}(\}*)
            /xs,
            filter => sub {
                my $node = shift;
                $node->{type} = '';
                $_ = $node->{1} . $node->{2};
            },
        },

    };
}

sub re_huggy {
    my $brace1 = shift;
    my $brace2 = shift || $brace1;

    qr/
        (?:^|(?<=[^{$ALPHANUM}$brace1]))$brace1(?=\S)(?!$brace2)
        (.*?)
        $brace2(?=[^{$ALPHANUM}$brace2]|\z)
    /x;
}

sub re_list {
    my $bullet = shift;
    return qr/^(            # Block must start at beginning
                            # Capture everything in $1
        ^$bullet+\ .*\n     # Line starting with one or more bullet
        (?:[\*\-\+\#]+\ .*\n)*  # Lines starting with '*' or '#'
    )(?:\s*\n)?/x,          # Eat trailing lines
}

1;
