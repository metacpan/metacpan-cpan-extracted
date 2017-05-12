package Search::Fulltext::Tokenizer::MeCab;
use strict;
use warnings;

use Carp;

our $VERSION = '1.05';
use Text::MeCab;
use Encode;

use File::Basename;
use Cwd;

use constant PREINSTALL_DICS => 'op.dic';  # '1.dic, 2.dic, 3.dic'

sub _mk_userdic_paths {
    my $libdir = Cwd::realpath(dirname(__FILE__));
    my $dicdir = "${libdir}/../../../../share/dic";

    # to pass tests even if this module file is put under blib/ directory.
    # FIXME: too ugly...
    unless (-d $dicdir) { $dicdir = "${libdir}/../../../../../share/dic" }

    my $p = "${dicdir}/" . PREINSTALL_DICS;
    if ($ENV{'MECABDIC_USERDIC'}) { $p .= ", $ENV{'MECABDIC_USERDIC'}" }
    $p;
}

sub _dbglog {
    my $str = shift;
    binmode(STDERR, ":utf8");
    if ($ENV{'MECABDIC_DEBUG'} && $ENV{'MECABDIC_DEBUG'} != '0') {
        print STDERR "$str";
    } 
}

sub tokenizer {
    my $mecab = Text::MeCab->new({
        userdic => _mk_userdic_paths,
    });

    return sub {
        my $string     = shift;
        my $term_index = 0;
        my $node       = $mecab->parse($string);
        _dbglog "string to be parsed: $string (" . length($string) . ")\n";

        return sub {
            my $term  = Encode::decode_utf8 $node->surface or return;
            my $len   = length $term;
            _dbglog "token: $term ($len)\n";
            my $start = index($string, $term);
            my $end   = $start + $len;
            $start >= 0 or croak '$term must be included in $string';
            $node = $node->next or return;
            return ($term, $len, $start, $end, $term_index++);
        }
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Search::Fulltext::Tokenizer::MeCab - Provides Japanese fulltext search for L<Search::Fulltext> module

=head1 SYNOPSIS

    use Search::Fulltext;
    use Search::Fulltext::Tokenizer::MeCab;
    
    my $query = '猫';
    my @docs = (
        '我輩は猫である',
        '犬も歩けば棒に当る',
        '実家でてんちゃんって猫を飼ってまして，ものすっごい可愛いんですよほんと',
    );
    
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => "perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'",
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 2]);        # 1st & 3rd include '猫'
    my $results = $fts->search('猫 AND 可愛い');
    is_deeply($results, [2]);

=head1 DESCRIPTION

L<Search::Fulltext::Tokenizer::MeCab> is a Japanse tokenizer working with fulltext search module L<Search::Fulltext>.
Only you have to do is specify C<perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'> as a C<tokenizer> of L<Search::Fulltext>.

    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => "perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'",
    });

You are supposed to use UTF-8 strings for C<docs>.

Although various queries are available like L<Search::Fulltext/QUERIES>,
I<wildcard query> (e.g. '我*') and I<phrase query> (e.g. '"我輩は猫である"') are not supported.

User dictionary can be used to change the tokenizing behavior of internally-used L<Text::MeCab>.
See L<ENVIRONMENTAL VARIABLES|/ENVIRONMENTAL_VARIABLES> section for detailes.

=head1 ENVIRONMENTAL VARIABLES

Some environmental variables are provided to customize the behavior of L<Search::Fulltext::Tokenizer::MeCab>.

Typical usage:

    $ ENV1=foobar ENV2=buz perl /path/to/your_script_using_this_module ARGS

=over 4

=item C<MECABDIC_USERDIC>

Specify path(s) to B<MeCab's user dictionary>.

See MeCab's manual to learn how to create user dictionary.

Examples:

    MECABDIC_USERDIC="/path/to/yourdic1.dic"
    MECABDIC_USERDIC="/path/to/yourdic1.dic, /path/to/yourdic2.dic"

=item C<MECABDIC_DEBUG>

When set to not 0, debug strings appear on STDERR.

Especially, outputs below would help check how your C<docs> are tokenized.

    string to be parsed: 我輩は猫である (7)
    token: 我輩 (2)
    token: は (1)
    token: 猫 (1)
    token: で (1)
    token: ある (2)
    ...
    string to be parsed: 猫 AND 可愛い (9)
    token: 猫 (1)
    string to be parsed:  可愛い (4)
    token: 可愛い (3)

Note that not only C<docs> but also queries are also tokenized.

=back

=head1 SUPPORTS

Bug reports and pull requests are welcome at L<https://github.com/laysakura/Search-Fulltext-Tokenizer-MeCab> !

To read this manual via C<perldoc>, use C<-t> option for correctly displaying UTF-8 caracters.

    $ perldoc -t Search::Fulltext::Tokenizer::MeCab

=head1 VERSION

Version 1.05

=head1 AUTHOR

Sho Nakatani <lay.sakura@gmail.com>, a.k.a. @laysakura
