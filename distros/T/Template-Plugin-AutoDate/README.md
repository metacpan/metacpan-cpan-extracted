# Template::Plugin::AutoDate

This perl module enhances Template Toolkit to provide easy access to DateTime
and DateTime::Format::Flexible.  It coerces plain strings to DateTime objects,
giving you the full power of DateTime's date manipulation inside your templates.

You can install the latest stable release of [this module from CPAN][1]

    cpanm Template::Plugin::AutoDate

and see the full docuentation locally with

    perldoc ./lib/Template/Plugin/AutoDate.pm   # before installed
    perldoc Template::Plugin::AutoDate          # after installed

To build and install [this source code][2], use the [Dist::Zilla][3] tool:

    cpanm Dist::Zilla
    dzil authordeps --missing | cpanm
    dzil build
    cpanm ./Template-Plugin-AutoDate-$VERSION.tar.gz

[1]: https://metacpan.org/pod/Template::Plugin::AutoDate
[2]: https://github.com/IntelliTree/perl-Template-Plugin-AutoDate
[3]: https://metacpan.org/pod/Dist::Zilla
