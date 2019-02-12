
# Development

The distribution is contained in a Git repository, so simply clone the
repository

```
$ git clone http://github.com/reneeb/Mojolicious-Plugin-MoreHTMLHelpers.git
```

and change into the newly-created directory.

```
$ cd Mojolicious-Plugin-MoreHTMLHelpers
```

The project uses [`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) to
build the distribution, hence this will need to be installed before
continuing:

```
$ cpanm Dist::Zilla
```

To install the required prequisite packages, run the following set of
commands:

```
$ dzil authordeps --missing | cpanm
$ dzil listdeps --author --missing | cpanm
```

The distribution can be tested like so:

```
$ dzil test
```

To run the full set of tests (including author and release-process tests),
add the `--author` and `--release` options:

```
$ dzil test --author --release
```
