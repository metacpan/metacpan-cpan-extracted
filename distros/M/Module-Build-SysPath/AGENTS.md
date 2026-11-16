# Repository Instructions

`README` is generated from the POD in `lib/Module/Build/SysPath.pm`. Do not
edit `README` directly. Update the main module, then regenerate `README` with:

```sh
perl Build.PL && ./Build distmeta
```

The agent skill in `docs/skills/perl-module-build-syspath/` restates install
behavior of `lib/Module/Build/SysPath.pm` (file selection, conffile handling,
`SPc.pm` rewriting, file modes). When that behavior changes, update the
skill's `SKILL.md` and `references/example.md` in the same change. Check
claims against the code, because several of them are not in the POD.

## Integration tests

Tests in `t/` fork real `perl Build.PL` and `./Build install` runs against a
temporary distribution and system root. A harness bug can exhaust memory and
take down the editor, so follow these rules:

- A forked child must end with `exec` or `POSIX::_exit`. If it `die`s, a
  surrounding `subtest` catches the error and the child goes on to run the
  rest of the test script, forking again.
- To wrap a Module::Build action, take the original with
  `Module::Build->can('ACTION_install')`. `Module::Build` inherits its actions
  from `Module::Build::Base`, so `\&Module::Build::ACTION_install` is a stub
  that resolves to your wrapper and recurses without bound.
- When changing a test harness, run it under limits first, for example:

  ```sh
  (ulimit -v 1000000; timeout -s KILL 300 prove -l t/06-file-modes.t)
  ```
