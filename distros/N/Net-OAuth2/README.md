# Perl distribution Net-OAuth2

This distribution implements an OAuth2 client, with knowledge about
various services.

## Development &rarr; Release

Important to know, is that I use an extension on POD to write the manuals.
The "raw" unprocessed version is visible on GitLab.  It will run without
problems, but does not contain manual-pages.

Releases to CPAN are different: "raw" documentation gets removed from
the code and translated into real POD and clean HTML.

Clone from GitLab for the "raw" version.  For instance, when you want
to contribute a new feature.

On CPAN, you can find the processed version for each release.  Simply run
the following command to get it installed:

```sh
   cpan -i Net::OAuth2
```

## Contributing

When you submit an extension, please contribute a set with

1. code

2. code documentation

3. regression tests in t/

**Please note:**
When you contribute in any way, you automatically agree that your
contribution is released under the same license as this project: licensed
as Perl itself.

## Copyright and License

This project is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See <http://dev.perl.org/licenses/>

