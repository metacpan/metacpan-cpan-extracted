# perl-types
Perl::Types

The Perl data type system

## Developers Only
```
# install static dependencies
$ dzil authordeps | cpanm
$ dzil listdeps | cpanm

# document changes & insert copyrights before CPAN release
$ vi Changes       # include latest release info, used by [NextRelease] and [CheckChangesHasContent] plugins
$ vi dist.ini      # update version number
$ vi FOO.pm foo.t  # add "# COPYRIGHT" as first  line of file, used by [InsertCopyright] plugin
$ vi foo.pl        # add "# COPYRIGHT" as second line of file, used by [InsertCopyright] plugin

# build & install dynamic dependencies & test before CPAN release
$ dzil build
$ ls -ld Perl-Types*
$ cpanm --installdeps ./Perl-Types-FOO.tar.gz  # install dynamic dependencies if any exist
$ dzil test  # may need dependencies installed by above `cpanm` commands

# inspect build files before CPAN release
$ cd Perl-Types-FOO
$ ls -l
$ less Changes
$ less LICENSE
$ less COPYRIGHT
$ less CONTRIBUTING
$ less MANIFEST
$ less README.md
$ less README
$ less META.json
$ less META.yml

# make CPAN release
$ git add -A; git commit -av  # CPAN Release, vX.YYY; Codename FOO, BAR Edition
$ git push origin main
$ dzil release  # will build, test, prompt for CPAN upload, and create/tag/upload new git commit w/ only version number as commit message
```

## Original Creation
Perl::Types was originally created via the following commands:

```
# normal installation procedure for minting profile
$ cpanm Dist::Zilla::MintingProfile

# normal minting procedure
$ dzil new Perl::Types
```

## License & Copyright
Perl::Types is Free & Open Source Software (FOSS), please see the LICENSE and COPYRIGHT and CONTRIBUTING files for legal information.


