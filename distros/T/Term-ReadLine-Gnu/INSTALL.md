# How to Install `Term::ReadLine::Gnu`

You need [the GNU Readline library](#how-to-install-gnu-readline-library) installed.
Except for this, you can install this module by the standard method, i.e.

```sh
% perl Makefile.PL && make install
```

## Make and install

```sh
% perl Makefile.PL [--prefix=...] [--includedir=...] [--libdir=...]
% make
% make test
% make install
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

### Trouble Shooting

If you have any troubles when using or installing this module
or find a bug, please open a ticket on [the bug tracker on
GitHub](https://github.com/hirooih/perl-trg/issues).

It will help other people who have the same problem.

When you report your issue, be sure to send me the following
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

#### Segmentation fault by the pager command in Perl debugger

If the pager command (`|` or `||`) in Perl debugger causes
segmentation fault, you need to fix `perl5db.pl`.  See
[this ticket](https://rt.perl.org/Public/Bug/Display.html?id=121456)
for details.  The patch was applied on perl 5.19.9.

## How to Install the GNU Readline Library

Now this module supports only the GNU Readline Library 2.1 and
later.  But the GNU Readline 2.2 has some bugs, so Use 2.2.1
instead.  The GNU Readline Library 4.2 is not supported.  Use 4.2a
instead.

Executing `perl Makefile.PL` detects which version of
the GNU Readline Library is installed and warns you if
you have the unsupported version.

The following example assumes that the install prefix directory is
`/usr/local/gnu`.

If you have any reasons in which you must use one of the following old libraries,
see `INSTALL` file which is included in `Term-ReadLine-Gnu-1.11`.

- the GNU Readline Library 2.1
- `libreadline.a` in `bash-2.0.tar.gz`
- Cygwin b20.1

### Install from source code of the GNU Readline Library

1. get and extract readline-XX.tar.gz
2. configure

```sh
% ./configure --prefix=/usr/local/gnu
```

3. make and install

```sh
% make install
```

#### Install on macOS

`/usr/bin/perl` on macOS 10.5 (Leopard) and later supports
32bit/64bit universal binary.  Make `Makefile` as follows:

```sh
# tested only on Mavericks
ARCHFLAGS='-arch x86_64' perl Makefile.PL --prefix=/usr/local/gnu
```

Or build 32bit/64bit-universal GNU Readline Library as
follows.  (works on the GNU Readline 6.3 and later)

Enable the following lines in `support/shobj-conf` in the GNU
Readline 6.3 distribution;

```sh
# for 32 and 64bit universal library
#SHOBJ_ARCHFLAGS='-arch i386 -arch x86_64'
#SHOBJ_CFLAGS=${SHOBJ_CFLAGS}' -arch i386 -arch x86_64'
```

Run configure script and do `make install` and make `Makefile` simply:

```sh
# tested only on Mavericks
perl Makefile.PL --prefix=/usr/local/gnu
```

### Using Package

#### apt based Linux

On apt-based Linux you need to install `libncurses-dev` package in
addition to `ibreadline-dev` package.

```sh
% sudo apt install libncurses-dev libreadline-dev
```

#### RPM based Linux

On RPM-based Linux you need to install `ncurses-devel` package in
addition to `readline-devel` package.

```sh
% sudo yum install ncurses-devel
% sudo yum install readline-devel
```

#### Homebrew on macOS

1. Install Homebrew
See https://brew.sh/.

2. Use homebrew to install the GNU Readline Library:

```sh
% brew install readline
```

Because the GNU Readline library conflicts with the the
similarly-named-but-different library installed in the base
OS, homebrew does not link readline into `/usr/local` (it is
"keg-only").

`Makefile.PL` uses `brew prefix readline` to find and use the
"keg" directory so things work seamlessly.

3. Build `Term::ReadLine::Gnu` as described above:

```sh
% perl Makefile.PL
% make
% make test
% make install
```

`brew cleanup` will not remove keg-only formula, to avoid
breaking things that have been linked against it.  However, if
you force it, `brew cleanup --force`, then it will remove the
keg-only formula and `Term::ReadLine::Gnu` will cease to work.
You'll need to rebuild `Term::ReadLine::GNU` so that it links
against whichever newer version you have installed.

#### MSYS2

1. Install MSYS2: See https://www.msys2.org/ .

2. Install additional packages:

```sh
% pacman -S msys2-devel msys2-runtime-devel msys/libreadline-devel libcrypt-devel
```

3. Build: on MSYS2 environment:

```sh
% perl Makefile.PL
% make
% make test
% make install
```

#### MSWin32 (Strawberry Perl)

1. Download and run installer from https://strawberryperl.com/

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
GNU Readline Library 7.0 and 8.0 on MSYS2 and MSWin32.  Use an older or newer
versions.

See https://lists.gnu.org/archive/html/bug-readline/2019-04/msg00000.html for
more information.

Strawberry Perl from 5.30.0.1 (2019-05-23) to 5.32.1.1 (2021-01-24) contains
version 8.0.  Versions prior to 5.30.0.1 do not contain the GNU Readline
Library. Until the next version which includes the GNU Readline Library 8.2, you
have to build it by yourself. See
[spbuild](https://github.com/StrawberryPerl/spbuild) for more information.

Or if you don't need the history-file, ignore the fails on `gmake test` and run
`gmake install`.
