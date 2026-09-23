# Repository Instructions

`README` is generated from the POD in `lib/Module/Build/SysPath.pm`. Do not
edit `README` directly. Update the main module, then regenerate `README` with:

```sh
perl Build.PL && ./Build distmeta
```
