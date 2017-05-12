# NAME

Pod::Perldoc::Cache - Caching perldoc output for quick reference

# SYNOPSIS

    $ perldoc -MPod::Perldoc::Cache CGI
    $ perldoc -MPod::Perldoc::Cache -w parser=Pod::Text::Color::Delight CGI

# DESCRIPTION

Pod::Perldoc::Cache caches the formatted output from perldoc command and references it for the next time. Once the cache file is generated, perldoc command no more formats the pod file, but replies the cache contents instantly. This module keeps track of the pod file contents so that the old cache is invalidated when the pod is updated.

# CONFIGURATION

In default, Pod::Perldoc::Cache uses `$HOME/.pod_perldoc_cache directory` for keeping cache files. By setting the environment variable **POD\_PERLDOC\_CACHE\_DIR**, you can select cache directory anywhere you want.

# COMMAND LINE OPTIONS

- -w parser=Parser::Module

    With "-w parser" command line option, you can specify the parser (formatter) module for perldoc which is used when the cache file doesn't exist.

- -w ignore

    If "-w ignore" command line option is given, the cache file is ignored and the pod file is re-rendered.

# SEE ALSO

[Pod::Text](https://metacpan.org/pod/Pod::Text),
[Pod::Text::Color::Delight](https://metacpan.org/pod/Pod::Text::Color::Delight)

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
