# PML-TQ Suggest Server

[![Build Status](https://travis-ci.org/ufal/pmltq-suggest-server.svg?branch=master)](https://travis-ci.org/ufal/pmltq-suggest-server)

Simple http server that can be used as an part of [PMLTQ::Server](https://github.com/ufal/perl-pmltq-server). It is based on [PMLTQ Print Server](https://github.com/ufal/pmltq-print-server) and excludes TrEd dependency.

Suggest server returns a PML-TQ query for given nodes.

# Parameters

- `--port` port to run on, defaults to **8071**
- `--host` what to bind to, defaults to **localhost**
- `--data-dir` directory with PML files **required**

# Installation


