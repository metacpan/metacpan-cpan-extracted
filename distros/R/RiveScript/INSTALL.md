# INSTALLATION

To install this module type the following:

```bash
perl Makefile.PL
make
make test
make install
```

# RPM BUILD

To build a RedHat package file for installing RiveScript, use the rpmbuild Perl
script provided in the subversion repository.

	Usage: perl rpmbuild

This results in a slightly different RPM than what you'd get via cpan2rpm or
cpan2dist... along with installing the module in its proper place in your Perl
libs, it will also install the `rivescript` utility from the `bin/` folder into
your `/usr/bin` directory.

# BUILDING RIVESCRIPT.EXE

The `bin/rivescript` script can be compiled into a stand-alone executable file
for distribution and inclusion in other projects. The module `PAR::Packer` can
produce this executable. Here is an example on how to create it, from the root
folder of the project:

```bash
$ pp -o rivescript.exe -I lib -M MIME::Base64 -M utf8_heavy.pl \
  -M unicore/Heavy.pl bin/rivescript
$ rivescript.exe lib/RiveScript/demo
```

The inclusion of `MIME::Base64` is to support the example Perl object in
`demo/perl.rive` and would otherwise be optional. The `utf8_heavy.pl` and
`unicore/Heavy.pl` may be needed if you otherwise were getting errors in
`utf8.pm` after entering a question for the bot.

# DEPENDENCIES

Requires:

* [JSON](http://search.cpan.org/perldoc?JSON)

Recommends:

* [Clone](http://search.cpan.org/perldoc?Clone)
