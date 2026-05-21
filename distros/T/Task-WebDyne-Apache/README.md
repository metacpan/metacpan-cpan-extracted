# Task::WebDyne::Apache

`Task::WebDyne::Apache` is a task distribution that installs the Perl
prerequisites commonly needed to run `WebDyne` under Apache.

## Install

```bash
cpan Task::WebDyne::Apache
```

Or with cpanminus:

```bash
cpanm Task::WebDyne::Apache
```

To install from a checkout:

```bash
perl Makefile.PL
make
make test
make install
```

## Included prerequisites

- `WebDyne`
- `Apache2::Build`
- `Apache::Test`
- `Module::CoreList`
