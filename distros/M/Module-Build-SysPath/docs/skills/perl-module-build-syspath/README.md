# perl-module-build-syspath

An agent skill for Perl distributions that use `Module::Build::SysPath` and
`Sys::Path` to install configuration, templates, state, logs and other files
in the directories that the Filesystem Hierarchy Standard (FHS) expects.

The distribution keeps those files in a source tree that looks like the
target system (`etc/`, `share/`, `var/lib/`, …) and gets its paths from a
small `<Dist>::SPc` module. In a checkout the module points into the source
tree. When the distribution is installed, `Module::Build::SysPath` copies
the files into the system directories and rewrites the installed `SPc`
module so that it points to them. The same code therefore runs from a
checkout and from an installed system without any configuration.

## When it helps

- deciding how a Perl application should install config files, templates
  or writable directories, and adding them to a Module::Build application
- maintaining a distribution that already has a `*::SPc` module
- finding out why a file was not installed, why the installed `SPc.pm` is
  wrong, or why the install prompted about a configuration file

It does not cover Dist::Zilla or ExtUtils::MakeMaker builds. It also does
not cover read-only data in reusable CPAN libraries, where `File::ShareDir`
is the usual tool.

## Contents

- [SKILL.md](SKILL.md): the agent procedure, the `SPc.pm` contract, the
  install rules and common pitfalls
- [references/example.md](references/example.md): a complete example
  distribution

## Sources

- `Module::Build::SysPath` 0.20 (`lib/Module/Build/SysPath.pm` in this
  repository): the install rules come from its `new` and `ACTION_install`
  code, not only from the POD.
- `Sys::Path` (`lib/Sys/Path.pm`, `lib/Sys/Path/SPc.pm`): the path types and
  their defaults.
- The `Build.PL` and `SPc.pm` files of the meon-Web application and of a
  private application: their real-world layouts, `conffiles` and custom
  `subclass` actions inspired the example.
