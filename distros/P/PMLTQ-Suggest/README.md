# PML-TQ Suggest Server

[![Build Status](https://travis-ci.org/ufal/pmltq-suggest-server.svg?branch=master)](https://travis-ci.org/ufal/pmltq-suggest-server)

Simple http server that can be used as an part of [PMLTQ::Server](https://github.com/ufal/perl-pmltq-server). It is based on [PMLTQ Print Server](https://github.com/ufal/pmltq-print-server) and excludes TrEd dependency.

Suggest server returns a PML-TQ query for given nodes.

# Execution

Module provides two different access to suggest service.

## Suggest server

**Parameters**

- `--port` port to run on, defaults to **8071**
- `--host` what to bind to, defaults to **localhost**
- `--resources-path` path to recources - server finds and adds all 'resource' directories within this path
- `--resources-path-follow` flag specifies whether symlinks shoud be followed


## PMLTQ Command


# Installation

```
cpan PMLTQ::Suggest
```


