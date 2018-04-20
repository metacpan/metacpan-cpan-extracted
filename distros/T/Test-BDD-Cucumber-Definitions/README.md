[![Build Status](https://travis-ci.org/ivanych/Test-BDD-Cucumber-Definitions.svg?branch=master)](https://travis-ci.org/ivanych/Test-BDD-Cucumber-Definitions) [![MetaCPAN Release](https://badge.fury.io/pl/Test-BDD-Cucumber-Definitions.svg)](https://metacpan.org/release/Test-BDD-Cucumber-Definitions)
# NAME

Test::BDD::Cucumber::Definitions - a collection of step definitions for Test
Driven Development

# VERSION

Version 0.37

# SYNOPSIS

In file **features/step\_definitions/http\_steps.pl**:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::BDD::Cucumber::Definitions::HTTP::In;

In file **features/http.feature**:

    Feature: HTTP
        Site test by HTTP

    Scenario: Loading the page
        When http request "GET" send "http://metacpan.org"
        Then http response code eq "200"

... and, finally, in the terminal:

    $ pherkin

      HTTP
        Site test by HTTP

        Scenario: Loading the page
          When http request "GET" send "http://metacpan.org"
          Then http response code eq "200"

# EXPORT

The module exports functions `S`, `C`, `Given`, `When` and `Then`.
These functions are identical to the same functions from the module
[Test::BDD::Cucumber](https://metacpan.org/pod/Test::BDD::Cucumber).

By default, no functions are exported. All functions must be imported
explicitly.

# AUTHOR

Mikhail Ivanov `<m.ivanych@gmail.com>`

# LICENSE AND COPYRIGHT

Copyright 2018 Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
