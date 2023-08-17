# How to Install `Term::ReadLine::Gnu`

## Using Prebuilt Packages

On Debian based Linux (Ubuntu, etc.);

```sh
% sudo apt-get install libterm-readline-gnu-perl
```

On RPM-based Linux (Red Hat Linux, etc);

```sh
% sudo yum install -y epel-release
% sudo yum install -y perl-Term-ReadLine-Gnu
```

## Build by Yourself

First [the GNU Readline library](https://tiswww.case.edu/php/chet/readline/rltop.html) must be installed.
See [How to Install the GNU Readline Library Section](#how-to-install-the-gnu-readline-library) for information on installing the library.

Except for this, you can install this module by the standard method, i.e.

```sh
% perl Makefile.PL [--prefix=...] [--includedir=...] [--libdir=...]
% make
% make test
% make install
```

Or simply;

```sh
% perl Makefile.PL [options...] && make install
```

If you have installed the GNU Readline Library
(`libreadline.{a,so}` and `readline/readline.h`, etc.) on
directories for which your perl is not configured to search
(refer the value of `ccflags` and `libpath` in the output of `perl
-V`), specify the paths as follows:

```sh
% perl Makefile.PL --includedir=/mydir/include --libdir=/mydir/lib
```

You may also use `--prefix` option.  The example above is equivalent to the following:

```sh
% perl Makefile.PL --prefix=/mydir
```

You can specify multiple directories by separating them with colons;

```sh
% perl Makefile.PL --prefix=/termcap/dir:/readline/dir
```

If you are not an administrator and cannot install Perl module
in your system directory, see the section: [How do I keep my own module/library
directory?](https://perldoc.perl.org/perlfaq8#How-do-I-keep-my-own-module/library-directory?) in [perlfaq8](https://perldoc.perl.org/perlfaq8).

## How to Install the GNU Readline Library

Using the latest GNU Readline Library is recommended.
However, this module also supports the GNU Readline Library 2.1 or later.
The GNU Readline 2.2 has a bug, so use 2.2.1 instead.
The GNU Readline Library 4.2 is also not supported. Use 4.2a instead.

Executing `perl Makefile.PL` detects which version of
the GNU Readline Library is installed and warns you if
you have the unsupported version.

### Install from source code of the GNU Readline Library

Download readline-XX.tar.gz from ftp://ftp.gnu.org/gnu/readline or other mirror sites. And type the following commands;

```sh
tar xzf readline-XX.tar.gz
cd readline-XX
./configure --prefix=/usr/local/gnu
make install
```

The example above assumes that the install prefix directory is
`/usr/local/gnu`.

Pass it `Makefile.PL` as follows;

```sh
% perl Makefile.PL --prefix=/usr/local/gnu
```

On old versions of macOS, some special configurations were required.
If you have problems with the above method, refer to
[`INSTALL.md` included in the Term::ReadLine::Gnu-1.45](https://github.com/hirooih/perl-trg/blob/perl-trg-1.45/INSTALL.md#install-on-macos).

### Install the GNU Readline Library Using Package

#### Debian based Linux

On Debian based Linux (Ubuntu, etc.) you need to install `libncurses-dev` package in
addition to `libreadline-dev` package.

```sh
% sudo apt install libncurses-dev libreadline-dev
```

#### RPM-based Linux

On RPM-based Linux (Red Hat Linux, etc) you need to install `ncurses-devel` package in
addition to `readline-devel` package.

```sh
% sudo yum install ncurses-devel
% sudo yum install readline-devel
```

#### [Homebrew](https://brew.sh/) on macOS

```sh
% brew install readline
```

Because the GNU Readline library conflicts with the the
similarly-named-but-different library installed in the base
OS, homebrew does not link readline into `/usr/local` (it is
"keg-only").

`Makefile.PL` uses `brew prefix readline` to find and use the
`keg` directory so things work seamlessly.

`brew cleanup` will not remove keg-only formula, to avoid
breaking things that have been linked against it.  However, if
you force it, `brew cleanup --force`, then it will remove the
keg-only formula and `Term::ReadLine::Gnu` will cease to work.
You'll need to rebuild `Term::ReadLine::GNU` so that it links
against whichever newer version you have installed.

#### MSYS2

1. Install MSYS2: See <https://www.msys2.org/> .

2. Install additional packages:

```sh
% pacman -S msys2-devel msys2-runtime-devel msys/libreadline-devel libcrypt-devel
```

#### MSWin32 (Strawberry Perl)

1. Download and run installer from <https://strawberryperl.com/>

    - prebuild GNU Readline Library (DLL) is included

2. Open `Perl (command line)` app

3. Build

```sh
% perl Makefile.PL
% gmake
% gmake test
% gmake install
```

Some tests of the history-file handling functions in `t/history.t` fail with the
GNU Readline Library 7.0 and 8.0 on MSYS2 and MSWin32.
See [the bug report](https://lists.gnu.org/archive/html/bug-readline/2019-04/msg00000.html) for
details of the bug.

If the bug is not important for you, ignore the fails on `gmake test` and run `gmake install`.

The current latest official release 5.32.1.1 (2021-01-24) contains
version 8.0. The 5.36.1 dev release and later include readline 8.2. Use one of [dev releases](https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases) if you don't wait for the next official release.

## Trouble Shooting

If you have any troubles when using or installing this module
or find a bug, please open a ticket on [the bug tracker on
GitHub](https://github.com/hirooih/perl-trg/issues).

It will help other people who have the same problem.

When you report your issue, be sure to include the following
information:

- output of

```sh
% perl -V
% perl Makefile.PL verbose
% make test TEST_VERBOSE=1
% perl -Mblib t/00checkver.t
% echo $TERM
```

- terminal emulator which you are using
- compiler which is used to compile the GNU Readline Library
  (`libreadline.a`) if you can know.

### Segmentation fault by the pager command in Perl debugger

If the pager command (`|` or `||`) in Perl debugger causes
segmentation fault, you need to fix `perl5db.pl`.  See
[this ticket](https://rt.perl.org/Public/Bug/Display.html?id=121456)
for details.  The patch was applied on perl 5.19.9.
