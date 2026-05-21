# INSTALLATION INSTRUCTIONS #

The latest version of this software is available from GitHub:

```bash
git clone https://github.com/aspeer/pm-Task-WebDyne-Apache.git
cd pm-Task-WebDyne-Apache
```

If you have a CPAN client available, install with:

`cpan .`

Or, with cpanminus:

`cpanm .`

Otherwise install manually:

```bash
perl Makefile.PL
make
make test
make install
```

When installing manually, dependencies may need to be installed
separately if your CPAN tooling does not resolve them automatically.
