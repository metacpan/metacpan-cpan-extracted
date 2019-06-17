# TUWF - The Ultimate Website Framework

This package provides the following set of modules:

- [TUWF](https://dev.yorhel.nl/tuwf/man)
- [TUWF::DB](https://dev.yorhel.nl/tuwf/man/db)
- [TUWF::Misc](https://dev.yorhel.nl/tuwf/man/misc)
- [TUWF::Request](https://dev.yorhel.nl/tuwf/man/request)
- [TUWF::Response](https://dev.yorhel.nl/tuwf/man/response)
- [TUWF::Validate](https://dev.yorhel.nl/tuwf/man/validate)
- [TUWF::XML](https://dev.yorhel.nl/tuwf/man/xml)

Documentation for each of these modules is provided in a .pod file along their
.pm implementations. Check out
[TUWF::Intro](https://dev.yorhel.nl/tuwf/man/intro) for a general introduction.

More information is available on the homepage at
[https://dev.yorhel.nl/tuwf](https://dev.yorhel.nl/tuwf).


## Optional dependencies

(Perl core modules not listed)

- [DBI](https://metacpan.org/release/DBI) - for SQL functionality (TUWF::DB)
- [FCGI](https://metacpan.org/release/FCGI) - to run in a FastCGI environment
- [HTTP::Server::Simple](https://metacpan.org/release/HTTP-Server-Simple) - to run the standalone HTTP server
- [JSON::XS](https://metacpan.org/release/JSON-XS) - for JSON requests & responses
- [PerlIO::gzip](https://metacpan.org/release/PerlIO-gzip) - for output compression


## Installing

From CPAN:

```
  cpan TUWF
```

From the repo (using cpanminus):

```
  cpanm .
```

Manually:

```
  perl Build.PL
  ./Build
  ./Build install
```


## Contact

Homepage: [https://dev.yorhel.nl/tuwf](https://dev.yorhel.nl/tuwf)

Git: [https://code.blicky.net/yorhel/tuwf](https://code.blicky.net/yorhel/tuwf)

Email: projects@yorhel.nl
