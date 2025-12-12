# distribution Object-Realize-Later

  * My extended documentation: <http://perl.overmeer.net/CPAN/>
  * Development via GitHub: <https://github.com/markov2/perl5-Object-Realize-Later>
  * Sponsor me: <https://markov.solutions/sponsor/index-en.html>
  * Download from CPAN: <ftp://ftp.cpan.org/pub/CPAN/authors/id/M/MA/MARKOV/>
  * Indexed from CPAN: <https://metacpan.org/release/Object-Realize-Later>

The "Object::Realize::Later" class helps with implementing transparent
on demand realization of object data.  This is related to the tricks
on autoloading of data, the lesser known cousin of autoloading of
functionality.

On demand realization is all about performance gain.  Why should you
spent costly time on realizing an object, when the data on the object is
never (or not yet) used?  In interactive programs, postponed realization
may boost start-up: the realization of objects is triggered by the
use, so spread over time.

It is part of the MailBox collection of modules, and nowhere else, as
far as I know.

## Installing

On github, you can find the processed version for each release.  But the
better source is CPAN; to get it installed simply run:

```sh
   cpan -i Object::Realize::Later
```

**Be aware that version 4 is not fully compatible with releases pre-4**
See <https://github.com/markov2/perl5-Mail-Box/wiki/>

## Development &rarr; Release

Important to know, is that I use an extension on POD to write the manuals.
The "raw" unprocessed version is visible on GitHub.  It will run without
problems, but does not contain manual-pages.

Releases to CPAN are different: "raw" documentation gets removed from
the code and translated into real POD and clean HTML.  This reformatting
is implemented with the OODoc distribution (A name I chose before OpenOffice
existed, sorry for the confusion)

Clone from github for the "raw" version.  For instance, when you want
to contribute a new feature.

## Contributing

When you want to contribute to this module, you do not need to provide
a perfect patch... actually: it is nearly impossible to create a patch
which I will merge without modification.  Usually, I need to adapt the
style of code and documentation to my own strict rules.

When you submit an extension, please contribute a set with

1. code

2. code documentation

3. regression tests in t/

**Please note:**
When you contribute in any way, you agree to transfer the copyrights to
Mark Overmeer (you will get the honors in the code and/or ChangeLog).
You also automatically agree that your contribution is released under
the same license as this project: licensed as perl itself.

## Copyright and License

This project is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See <http://dev.perl.org/licenses/>
