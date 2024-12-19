# sbokeeper
**sbokeeper** is a utility for Slackware administrators to help manage installed
SlackBuid packages by maintaining a database of added packages and their
dependencies. It is not a package manager itself, it could more accurately be
described as a package manager helper.

## Building
**sbokeeper** should be able to run on most Unix-like systems, although it
probably won't have much use outside a Slackware system.

**sbokeeper** now has a
[slackbuild on SlackBuilds.org](https://slackbuilds.org/repository/15.0/system/sbokeeper/?search=sbokeeper).

**sbokeeper** depends on the following:
* Perl (>= 5.16)

To build and install **sbokeeper**:
```
perl Makefile.PL
make
make test
make install
```
Please read the documentation for `ExtUtils::MakeMaker` for more information
on configuring the build process for **sbokeeper**.

## Usage
For more in-depth information on the usage of **sbokeeper**, please consult the
**sbokeeper** manual (`perldoc ./bin/sbokeeper` or `man 1 sbokeeper` if
**sbokeeper** has been installed). The information in this section is meant to
be a rough overview of the usage of **sbokeeper**, not an exhaustive catalog of
**sbokeeper**'s capabilities.

**sbokeeper** keeps track of packages by maintaining a package database. The
database basically tracks which packages were manually added and what packages
they depend on. **sbokeeper** tries to give the user a large degree of freedom
when it comes to manipulating the database, to be compatible with the Slackware
philosophy of "the user probably knows what he's doing, let him do whatever he
wants." 

### Getting Started

First thing you are going to want to do is obtain a local copy of the
SlackBuilds.org repository. If you are using a SlackBuild package manager tool
like **sbopkg**, then it should clone a repo somewhere on your system. You're
going to have to refer to your tool's documentation on where it is. If you are
not using any sort of package manager, you will have to clone the repo yourself.
```
git clone git://git.slackbuilds.org/slackbuilds.git
```
You will now need to tell **sbokeeper** where the repo is on your system. You
can do that either through the `-s` option or the `SBoPath` configuration
field.
```
echo "SBoPath = /absolute/path/to/repo" >> ~/.config/sbokeeper.conf
```
If you are using one of the following SlackBuild package managers and are using
the default repo location then you do not have to do any sort of configuration,
**sbokeeeper** will find the repo itself.
* `sbopkg`
* `sbotools`/`sbotools2`
* `sbpkg`
* `slpkg`
* `sboui`

Now you should be ready to use **sbokeeper**.

To get started, you can use the `pull` command to automatically find installed
SlackBuild packages and add them to your package database.
```
sbokeeper pull
```

### Basic Usage

Let's say you have a SlackBuild whose dependency tree looks like this:
```
pkg1
L dep1
L dep2
  L dep2.1
    L dep2.1.1
```
and you've installed `pkg1` and all of its dependencies, but now you'd like to
track it with **sbokeeper**. To add `pkg1` and automatically track down its
dependencies, you can run this command:
```
sbokeeper add pkg1
```
**sbokeeper** will add `pkg1` to database and mark it as manually added, which
means you added the package yourself and it wasn't pulled in as a dependency.
**sbokeeper** also allows the user to do things old fashioned way of adding
everything manually:
```
sbokeeper tack pkg1
sbokeeper tackish dep1
sbokeeper depadd pkg1 dep1
...
```
`tack` adds packages to the database without trying to automatically add
dependencies. `tackish` (and its sibling `addish`) do the same thing as their
counterparts but the packages are not marked as manually added. `depadd` adds
dep1 as a dependency of `pkg1`.

Now let's say you're tired of `pkg1` and want to get rid of it and all its
friends from your system. You removed the `pkg1` package from your system, but
now need to know which dependencies are no longer needed. With **sbokeeper**,
you would first remove `pkg1` from the database.
```
sbokeeper rm pkg1
```
`pkg1` is now gone, but its dependencies remain. To find out which dependencies
are no longer necessary, you can run:
```
sbokeeper print unnecessary
```
The `print` command will print a list of all packages that are a part of a
certain category. `unnecessary` prints a list of packages that were neither
manually added to the system or a dependency of a manually added package.

Now let's say that you have removed all of those packages from your system, but
now you need to remove them all from your package database. **sbokeeper** provides
an easy way of doing that:
```
sbokeeper rm @unnecessary
```
This command removes all packages from your database that a part of the
unnecessary category. This `@unnecessary` is an alias, which is signified by the
`@` sign. Aliases are command arguments that are automatically expanded into
the list of packages it represents.

As stated previously, this was a rough overview of the usage of
**sbokeeper**. More documentation can be found in the manual or the `help`
command.
```
perldoc ./bin/sbokeeper
man 1 sbokeeper          # sbokeeper must be installed first
sbokeeper help
```

## Why?
Whenever I used Slackware in the past, I would keep track of all my SlackBuilds
in a text file that looked something like this:
```
mpv
-libass
-libplacebo
--python3-meson-opt
---python3-build
----python3-pyproject-hooks
... etc. ...
```
This was nice as when my systems would amass many SlackBuild packages I could
easily tell why a certain package was installed.

The issue with this was that, at some point, maintaining the text file would
become too tedious. I would eventually give up on maintaining the file because
either:
* The package tree would become so complicated that I'd rather employ the
install-and-forget strategy of package management rather than wrap my head
around tracking which packages go with what.
* I'd make a mistake in the file that would cause a bunch of confusing problems
in the future that I couldn't bothered to investigate and fix.

I eventually came to the realization that many of these problems could be solved
if I just automated the whole process with some sort of program. So I got to
hacking.

I personally use **sbokeeper** along with [sbopkg](https://sbopkg.org/). sbopkg
handles the actual package management (building, installation, updating) while
**sbokeeper** handles the documenting and tracking of the packages.

## Copyright

Copyright (C) 2024 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See *https://dev.perl.org/licenses/* for more information.
