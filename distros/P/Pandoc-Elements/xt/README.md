This directory contains tests to run with multiple versions of pandoc
executable. 

Script `get-pandoc-releases.pl` downloads all available binary releases of
pandoc (limited to Debian 64bit) and stores them in subdirectory `bin`:

    $ perl -Ilib xt/get-pandoc-releases.pl

Then run all or selected tests with all or selected pandoc releases:

    $ ./xt/prove
    $ ./xt/prove '>=1.17'
    $ ./xt/prove '>=1.17' t/stringify.t

