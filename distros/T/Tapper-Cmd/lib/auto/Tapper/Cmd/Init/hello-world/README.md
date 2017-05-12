# Overview

This is a "hello world"-style example for Tapper. This subdirectory
contains scripts and examples for a first start (a bit redundantly, as
they are also found in other Tapper libraries).

# Install Tapper

Install libraries from CPAN:

```bash
  $ cpan install Task::Tapper::Server
```

# Initialize Tapper

Create your personal ~/.tapper/ working directory:

```bash
  $ tapper init --defaults
```

# Start Tapper

You need several daemons running, e.g. in several terminals.

* Web interface to browse reports:

```bash
  $ tapper_reports_web_server.pl
```

* Reports receiver:

```bash
  $ tapper-reports-receiver
```

* Reports query API

```bash
  $ tapper-reports-api
```

# Execute tests

## Set your environment

Several env vars are used to specify where the central server is, here
it's about where to send test results. For this hello-world we point
them to our localhost:


```bash
  $ cd $HOME/.tapper/hello-world/00-set-environment
  $ source local-tapper-env.inc
```

## Run example tests and report results

```bash
  $ cd $HOME/.tapper/hello-world/01-executing-tests/
```

You can execute the scripts with ```prove``` (already available in
your Linux distro) which executes the tests but does **not** report
results to the server:

    $ prove     t/basic/example-01-basic.t
    $ prove -v  t/basic/example-01-basic.t
    $ prove -r  t/                           # recursive
    $ prove -rv t/                           # verbose
    $ prove -r  t/basic                      # subset only
    $ prove -r  t/complex                    # subset only

For running the tests inclusive reporting their results to the Tapper
server (defined by ```$TAPPER_REPORT_SERVER```) you execute them
directly:

    $ t/basic/
    $ for t in $(find t/ -name "*.t") ; do $t ; done

## More info

The utility libraries should be accessible, here we made
```tapper-autoreport``` directly available. See
http://github.com/tapper/Tapper-autoreport for more.


# Evaluate tests

The query API works by sending templates to the server which are
evaluated and sent back. Inside the templates you use a query language
to fetch values from the test results db.

## Simple results

```bash
  $ cd $HOME/.tapper/hello-world/02-query-api/
  $ cat hello.tt | netcat localhost 7358
    Planned tests:
       5
       5
       5
       5
```

## Benchmarks

The mechanism is the same, just the templates are more complex,
e.g. to select values that are deeper embedded in the test results:

```bash
  $ cat benchmarks.tt | netcat localhost 7358
    Benchmarks:
       1995.10
       1995.10
       1995.10
       1995.10
```

Now let's generate a gnuplot file with those data:

```bash
  $ cat benchmarks-gnuplot.tt | netcat localhost 7358
    #! /usr/bin/env gnuplot
    TITLE = "Example bogomips"
    set title TITLE offset char 0, char -1
    set style data linespoints
    set xtics rotate by 45
    set xtics out offset 0,-2.0
    set term png size 1200, 800
    set output "example-03-benchmarks.png"
    
    plot '-' using 1:2 with linespoints lt 3 lw 1 title "ratio"
    
           19 1995.10
           25 1995.10
           31 1995.10
           32 1995.10
```

You can also directly pipe such a result into gnuplot:

```bash
  $ cat benchmarks-gnuplot.tt | netcat localhost 7358 | gnuplot
  $ eog example-03-benchmarks.png
```

See http://template-toolkit.org for more information about the
template language.
