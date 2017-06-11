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
**TTL is 1day**.

# CONFIGURATION

Pod::Cpandoc::Cache uses `$HOME/.pod_cpandoc_cache` directory for keeping cache files. By setting the environment variable **POD\_CPANDOC\_CACHE\_ROOT**, you can select cache directory anywhere you want.

# SEE ALSO

[Pod::Cpandoc](https://metacpan.org/pod/Pod::Cpandoc)

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass &lt;tokubass {at} cpan.org>
