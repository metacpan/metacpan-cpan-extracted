# NAME

Sphinx::XMLpipe2 - Kit for SphinxSearch xmlpipe2 interface

# SYNOPSIS

    use Sphinx::XMLpipe2;

    my $sxml = new Sphinx::XMLpipe2(
        fields => [qw(author title content)],
        attrs  => {published => 'timestamp', section => 'int',}
    );

    or

    my $sxml = new Sphinx::XMLpipe2(
        fields => [qw(author title content)],
        attrs  => [
            {
                name => 'published',
                type => 'timestamp',
            },
            {
                name    => 'section',
                type    => 'int',
                bits    => 8, # optional
                default => 1  # optional
            },
        ]
    );

    $sxml->add_data({
        id         => 314159265,
        author     => 'Oscar Wilde',
        title      => 'Illusion is the first of all pleasures',
        content    => 'Man is least himself when he talks in his own person. Give him a mask, and he will tell you the truth.',
        published  => time(),
        section    => 100500,
    });

    $sxml->remove_data({id => 27182818});

    print $sxml->fetch(), "\n";

# METHODS

- new %options

    Constructor. Takes a hash with options as an argument (required).
    The hash contains two keys: fields (arrayref) and attrs (hashref or arrayref if you want to specify additional fields: "bits", "default").
    For details about "fields" and "attrs" see SphinxSearch manual.

- add\_data $hashref

    Adds a **single** document to xml. The argument contains key-value pairs with fields/attrs.
    You can do multiple calls this method with different params set.
    Кeys are not properly validated by package.

- remove\_data $hashref

    Request for a **single** document remove from index (adds killist record to xml).
    The argument contains document\_id: {id => $document\_id}.
    You can do multiple calls this method with different params.

- fetch

    Fetch the result (xml)

# SEE ALSO

[Sphinx reference manual: xmlpipe2 data source](http://sphinxsearch.com/docs/latest/xmlpipe2.html)

Yet another xmlpipe2 package [Sphinx::XML::Pipe2](http://search.cpan.org/~egor/Sphinx-XML-Pipe2-0.002/lib/Sphinx/XML/Pipe2.pm)

# LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

bbon <bbon@mail.ru>
