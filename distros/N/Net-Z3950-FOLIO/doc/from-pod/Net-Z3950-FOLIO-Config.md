# NAME

Net::Z3950::FOLIO::Config - configuration file for the FOLIO Z39.50 gateway

# SYNOPSIS

    {
      "okapi": {
        "url": "https://folio-snapshot-okapi.dev.folio.org",
        "tenant": "diku"
      },
      "login": {
        "username": "diku_admin",
        "password": "${OKAPI_PASSWORD}"
      },
      "indexMap": {
        "1": "author",
        "4": "title",
        "21": "subject"
      },
      "graphqlQuery": "instances.graphql-query", ###
      "queryFilter": "source=marc", ###
      "chunkSize": 5,
      "fieldMap": {
        "title": "245$a",
        "author": "100$a"
      }
    }

# DESCRIPTION

The FOLIO Z39.50 gateway `z2folio` is configured by a single file,
named on the command-line, and expressed in JSON.  This file specifies
how to connect to FOLIO, how to log in, and how to translate its
instance records into MARC.

The structure of the file is pretty simple. There are several
top-level section, each described in its own section below, and each
of them an object with several keys that can exist in it.

If any string value contains sequences of the form `${NAME}`, they
are each replaced by the values of the corresponding environment
variables `$NAME`, providing a mechanism for injecting values into
the condfiguration. This is useful if, for example, it is necessary to
avoid embedding authentication secrets in the configuration file.

## `okapi`

Contains three elements (two mandatory, one optional), all with string values:

- `url`

    The full URL to the Okapi server that provides the gateway to the
    FOLIO installation.

- `graphqlUrl` (optional)

    Usually, the main Okapi URL is used for all interaction with FOLIO:
    logging in, searching, retrieving records, etc. When the optional
    &#x3d;`graphqlUrl` configuration entry is provided, it is used for GraphQL
    queries only. This provides a way of "side-loading" mod-graphql, which
    is useful in at least two situations: when the FOLIO snapshot services
    are unavailable (since the production services do not presently
    &#x3d;included mod-graphql); and when you need to run against a development
    &#x3d;version of mod-graphql so you can make changes to its behaviour.

- `tenant`

    The name of the tenant within that FOLIO installation whose inventory
    model should be queried.

## `login`

Contains two elements, both with string values:

- `username`

    The name of the user to log in as, unless overridden by authentication information in the Z39.50 init request.

- `password`

    The corresponding password, unless overridden by authentication information in the Z39.50 init request.

## `chunkSize`

An integer specifying how many records to fetch from FOLIO with each
search. This can be tweaked to tune performance. Setting it too low
will result in many requests with small numbers of records returned
each time; setting it too high will result in fetching and decoding
more records than are actually wanted.

## `indexMap`

Contains any number of elements, all with string values. The keys are
the numbers of BIB-1 use attributes, and the corresponding values are
those of fields in the FOLIO instance revord to map those
access-points to.

## `graphqlQuery`

The name of a file, in the same directory as the main configuration
file, which contains the text of the GraphQL query to be used to
obtain the instance, holdings and item data pertaining to the records
identified by the CQL query.

## `queryFilter`

If specified, this is a CQL query which is automatically `and`ed with
every query submitted by the client, so it acts as a filter allowing
through only records that satisfy it. This might be used, for example,
to specify `source=marc` to limit search result to only to those
FOLIO instance records that were translated from MARC imports.

## `fieldMap`

Contains any number of elements, all with string values. The keys are
the names of fields in the FOLIO instance record, and the
corresponding values are those of MARC fields to map those fields to.

# SEE ALSO

- The `z2folio` script conveniently launches the server.
- `Net::Z3950::FOLIO` is the library that consumes this configuration.
- The `Net::Z3950::SimpleServer` handles the Z39.50 service.

# AUTHOR

Mike Taylor, <mike@indexdata.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.
