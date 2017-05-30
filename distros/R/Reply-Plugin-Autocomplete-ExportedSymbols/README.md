# NAME

Reply::Plugin::Autocomplete::ExportedSymbols - Tab completion for exported symbol names

# SYNOPSIS

In your .replyrc

    [Autocomplete::ExportedSymbols]

And use reply!

    % reply
    0> use List::Util qw/ <TAB>
    all         max         minstr      pairfirst   pairmap     product     sum         uniqnum
    any         maxstr      none        pairgrep    pairs       reduce      sum0        uniqstr
    first       min         notall      pairkeys    pairvalues  shuffle     uniq        unpairs
    0> use List::Util qw/ pair<TAB>
    pairfirst   pairgrep    pairkeys    pairmap     pairs       pairvalues

# DESCRIPTION

Reply::Plugin::Autocomplete::ExportedSymbols is a plugin for [Reply](https://metacpan.org/pod/Reply).
It provides a tab completion for exported symbols names from [Exporter](https://metacpan.org/pod/Exporter)'s `@EXPORT`, `@EXPORT_OK` and `%EXPORT_TAGS`.

Note that exported variables are not included in completion.

# SEE ALSO

[Reply](https://metacpan.org/pod/Reply)

[Exporter](https://metacpan.org/pod/Exporter)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama &lt;t.akiym@gmail.com>
