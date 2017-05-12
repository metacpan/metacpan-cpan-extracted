# NAME

Search::Fulltext::Tokenizer::MeCab - Provides Japanese fulltext search for [Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext) module

# SYNOPSIS

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

# DESCRIPTION

[Search::Fulltext::Tokenizer::MeCab](http://search.cpan.org/perldoc?Search::Fulltext::Tokenizer::MeCab) is a Japanse tokenizer working with fulltext search module [Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext).
Only you have to do is specify `perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'` as a `tokenizer` of [Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext).

    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => "perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'",
    });

You are supposed to use UTF-8 strings for `docs`.

Although various queries are available like ["QUERIES" in Search::Fulltext](http://search.cpan.org/perldoc?Search::Fulltext#QUERIES),
_wildcard query_ (e.g. '我\*') and _phrase query_ (e.g. '"我輩は猫である"') are not supported.

User dictionary can be used to change the tokenizing behavior of internally-used [Text::MeCab](http://search.cpan.org/perldoc?Text::MeCab).
See [ENVIRONMENTAL VARIABLES](#ENVIRONMENTAL\_VARIABLES) section for detailes.

# ENVIRONMENTAL VARIABLES

Some environmental variables are provided to customize the behavior of [Search::Fulltext::Tokenizer::MeCab](http://search.cpan.org/perldoc?Search::Fulltext::Tokenizer::MeCab).

Typical usage:

    $ ENV1=foobar ENV2=buz perl /path/to/your_script_using_this_module ARGS

- `MECABDIC_USERDIC`

    Specify path(s) to __MeCab's user dictionary__.

    See MeCab's manual to learn how to create user dictionary.

    Examples:

        MECABDIC_USERDIC="/path/to/yourdic1.dic"
        MECABDIC_USERDIC="/path/to/yourdic1.dic, /path/to/yourdic2.dic"

- `MECABDIC_DEBUG`

    When set to not 0, debug strings appear on STDERR.

    Especially, outputs below would help check how your `docs` are tokenized.

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

    Note that not only `docs` but also queries are also tokenized.

# SUPPORTS

Bug reports and pull requests are welcome at [https://github.com/laysakura/Search-Fulltext-Tokenizer-MeCab](https://github.com/laysakura/Search-Fulltext-Tokenizer-MeCab) !

To read this manual via `perldoc`, use `-t` option for correctly displaying UTF-8 caracters.

    $ perldoc -t Search::Fulltext::Tokenizer::MeCab

# VERSION

Version 1.05

# AUTHOR

Sho Nakatani <lay.sakura@gmail.com>, a.k.a. @laysakura
