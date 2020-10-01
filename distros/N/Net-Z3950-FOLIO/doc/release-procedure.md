# Maintaining and releasing the FOLIO Z39.50 server


## Perl conventions

Since this Z39.50 server is written as a Perl module, it adheres to Perl release conventions rather those of Node modules (used for front-end modules) or Java artifacts (as typically used for back-end modules). Note the following consequent differences from how most other FOLIO packages are managed:

* In the Perl world, version numbers are two-part (major.minor, for example `1.3`), not three-part (major.minor.patch, for example `1.3.0`) as in much of FOLIO and in [semantic versioning](https://semver.org/).

* Formal releases are made via [CPAN](https://www.cpan.org/), the Comprehensive Perl Archive Network rather than via NPM or a Maven repository.

* The master version number is held in the source-code itself -- specificially in [`Net/Z3950/FOLIO.pm`](../lib/Net/Z3950/FOLIO.pm) -- and is extracted by the package-building code invoked from [`Makefile.PL`](../Makefile.PL).

* The change-log is [`Changes.md`](../Changes.md) rather than `CHANGELOG.md` or `NEWS.md`.

* The master documentation is written in [POD](https://perldoc.perl.org/perlpod.html), embedded in Perl source files. Since it is useful to be able to read documentation directly from Markdown in [the GitHub source](https://github.com/folio-org/Net-Z3950-FOLIO/), Markdown versions can be automatically generated from the POD sources in [the `doc/from-pod` directory](from-pod).

* [The module descriptor](../ModuleDescriptor.json) is a static file which must be maintained by hand, rather than being automatically generated from a template. (We could build a system to do the latter, but have not yet done so.)


## Release procedure

The procedure therefore consists of the following steps:

* Make the actual changes to the software, including relevant documentation, change-log entries (within an "IN PROGRESS" release section), and tests if appropriate. Commit.
* Regenerate the Markdown versions of the POD documentation by running `make` in [`doc/from-pod`](from-pod).
* Check that the standard Perl build-test-and-clean procedure runs successfully and without warnings about unpackaged files, etc.:
```	
	perl Makefile.PL
	make
	make test
	make distclean
```
* Update the version number `our $VERSION` in [`Net/Z3950/FOLIO.pm`](../lib/Net/Z3950/FOLIO.pm) and in [the module descriptor](../ModuleDescriptor.json)
* Update the "IN PROGRESS" entry at the top of the change-log to include the present date-stamp the output of `date`.
* Commit `FOLIO.pm`, `ModuleDescriptor.json` and `Changes.md` all together with the commit comment "Release vX.Y", for appropriate _X_ and _Y_ matching the `$VERSION` in `FOLIO.pm`.
* Tag the source with `git tag vX.Y` and push the tag with `git push origin tag vX.Y`.
* Make the distribution tarball: `perl Makefile.PL; make dist`.
* Upload that tarball to [PAUSE](https://pause.perl.org/pause/authenquery?ACTION=add_uri)
* Wait several hours for the release processing to complete, in case something goes wrong. Your quest is complete when the new version appears at [the CPAN page](https://metacpan.org/release/Net-Z3950-FOLIO).

Why do we git tag the release, and even push the tag to GitHub, before knowing whether the release has been successfully accepted into CPAN? Because once you upload a given version of the module to CPAN, that version is nailed down forever and you can't replace it with a second attempt at the same version. So that version is part of history, and it's honest to tag it as such even if it was not able to make it out into the world.


