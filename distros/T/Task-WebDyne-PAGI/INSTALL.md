# INSTALLATION INSTRUCTIONS #

The latest version of this software is always available from GitHub

```
git clone https://github.com/aspeer/pm-Task-WebDyne-PAGI.git
cd pm-Task-WebDyne-PAGI
```

If on a modern system:

`cpan .`

Or (faster, if available):

`cpanm .`

Failing that manual install: 

```
perl Makefile.PL
make
make test
make install
```

If installing manually, dependencies will have to be installed individually.
