# NAME

Spellunker - Pure perl spelling checker implementation

# DESCRIPTION

Spellunker is pure perl spelling checker implementation.
You can use this spelling checker as a library.

And this distribution provides [spellunker](http://search.cpan.org/perldoc?spellunker) and [spellunker-pod](http://search.cpan.org/perldoc?spellunker-pod) command.

If you want to use this spelling checker in test script, you can use [Test::Spellunker](http://search.cpan.org/perldoc?Test::Spellunker).

# METHODS

- my $spellunker = Spellunker->new();

    Create new instance.

- $spellunker->load\_dictionary($filename\_or\_fh)

    Loads stopwords from `$filename_or_fh` and adds them to the on-memory dictionary.

- $spellunker->add\_stopwords(@stopwords)

    Add some `@stopwords` to the on memory dictionary.

- $spellunker->clear\_stopwords();

    Crear the information of stop words.

- $spellunker->check\_word($word);

    Check the word looks good or not.

- @bad\_words = $spellunker->check\_line($line)

    Check the text and returns bad word list.

# HOW DO I USE CUSTOM DICTIONARY?

You can put your personal dictionary at `$HOME/.spellunker.en`.

# WHY DOES SPELLUNKER NOT IGNORE PERL CODE?

In some case, Spellunker does not ignore the perl code. You need to wrap it by C< >.

# CONTRIBUTION

You can send me pull-request on github

# LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
