# How to release

Check perl version with:

    perlver lib

```
rm MANIFEST
perl Build.PL
./Build installdeps
./Build manifest
./Build test
./Build dist
```