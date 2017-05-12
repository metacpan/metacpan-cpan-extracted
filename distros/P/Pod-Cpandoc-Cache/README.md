# NAME

    Pod::Cpandoc::Cache - Caching cpandoc

# SYNOPSIS

    $ ccpandoc Acme::No
    $ ccpandoc -m Acme::No
    $ ccpandoc -c Acme::No

    # support Pod::Perldoc::Cache
    $ ccpandoc -MPod::Perldoc::Cache -w parser=Pod::Text::Color::Delight Acme::No



# DESCRIPTION

Pod::Cpandoc::Cache cache fetched document from CPAN.
__TTL is 1day__.

# CONFIGURATION

Pod::Cpandoc::Cache uses `$HOME/.pod\_cpandoc\_cache` directory for keeping cache files. By setting the environment variable __POD\_CPANDOC\_CACHE\_ROOT__, you can select cache directory anywhere you want.

# SEE ALSO

[Pod::Cpandoc](http://search.cpan.org/perldoc?Pod::Cpandoc)

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass <tokubass {at} cpan.org>
