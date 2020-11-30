# Overview of the FOLIO Z39.50 server source-code

<!-- md2toc -l 2 source-code-overview.md -->
* [Introduction](#introduction)
* [Source files](#source-files)
    * [`bin/z2folio`](#binz2folio)
    * [`lib/Net/Z3950/FOLIO.pm`](#libnetz3950foliopm)
    * [`lib/Net/Z3950/FOLIO/Session.pm`](#libnetz3950foliosessionpm)
    * [`lib/Net/Z3950/FOLIO/Config.pm`](#libnetz3950folioconfigpm)
    * [`lib/Net/Z3950/FOLIO/ResultSet.pm`](#libnetz3950folioresultsetpm)
    * [`lib/Net/Z3950/FOLIO/OPACXMLRecord.pm`](#libnetz3950folioopacxmlrecordpm)
    * [`lib/Net/Z3950/FOLIO/RPN.pm`](#libnetz3950foliorpnpm)



## Introduction

The FOLIO Z39.50 server is written in Perl, due to that language's excellent support for the Z39.50 protocol and particularly [the `SimpleServer` module](https://metacpan.org/pod/Net::Z3950::SimpleServer).

The source code consists of three sets of files:

* `bin/z2folio` -- the command-line program that runs the server
* `lib/Net/Z3950/FOLIO.pm` -- the top-level server class that wires into the Z39.50 SimpleServer module
* `lib/Net/Z3950/FOLIO/*.pm` -- support modules (mostly classes) used by `FOLIO.pm`

We will consider each of these in turn.



## Source files


### `bin/z2folio`

This is an extremely simple script of only a dozen lines of code. All it does is gather command-line arguments, create an instance of the server class, and launch it as a server.


### `lib/Net/Z3950/FOLIO.pm`

The top-level server class. [The public API](from-pod/Net-Z3950-FOLIO.md) consists only of the constructor and the `launch_server` method that are used by `bin/z2folio`. The real work of the constructor is to set up the SimpleServer service and to provide the handlers for the various Z39.50 operations: init, search, fetch, delete and sort.

The SimpleServer API provides two handles which can be initialized by constructors and handler functions, and which are passed back as part of the argument block given to every handler function. These are the global handle, called GHANDLE, and the session handle, just called HANDLE. The former is set in the constructor, and used as a pointer to the `Net::Z3950::FOLIO` server object itself. The latter is set in the search handler (see below), and points to the session object on which the search is invoked.

Conceptually, sessions should be created by the init handler, but in the Z39.50 protocol the name of the database to be searched is not specified until a search is issued, so there is no name by which the session can be known at init-time. Since the database name is also used to determine which set of configuration files to load for the session, this too must be deferred until search time: the response to the Z39.50 init request, then, is fairly vacuous: all it says that the server is ready to receive searches -- but only when the first search comes in can the configuration be loaded.


### `lib/Net/Z3950/FOLIO/Session.pm`

A class representing an ongoing session against a specific back-end. This carries its own configuration, combining global config with tenant-specific config. This compound configuration is compiled when the first search request is received, and the authentication credentials specified therein are then used to authenticate onto the specified back-end.

This class contains the methods that do most of the actual work of talking to the FOLIO back-end service and translating the resulting JSON records into the various record formats. (At present, some of that code remains in `FOLIO.pm`, but it may get moved down in time.)


### `lib/Net/Z3950/FOLIO/Config.pm`

A class representing a compiled configuration, which may be assembled from several overlaid configuration files. Contains the code for compiling the combining the configuration files, and expanding environment variable references within them.

Also contains POD documentation of the configuration-file format.


### `lib/Net/Z3950/FOLIO/ResultSet.pm`

A very simple class used to store the results of searching: the result-set name, the query that was executed, the total count of matching records, and the records themselves so far as they have been loaded.

Has a straightforward API, not documented in detail, consisting of a constructor and five methods: `total_count(int)`, `insert_records(offset, records*)`, `record(offset)`, `insert_marcRecords(marcRecords*)` and `marcRecord(id)`.


### `lib/Net/Z3950/FOLIO/OPACXMLRecord.pm`

Not a class, but a package providing a single public function, `makeOPACXMLRecord(inventoryRecord, marcRecord)`. This analyses the record's data from FOLIO inventory (instance, associated holdings, and items associated with those holdings) together with the MARC record, and returns a Z39.50 OPAC record in the XML format defined by the YAZ toolkit.

The code in this package is extensively commented with observations on the meanings of the various OPAC-record fields and how they may be related to fields in the various FOLIO inventory records.


### `lib/Net/Z3950/FOLIO/RPN.pm`

This file does not contain a `Z3950::FOLIO::RPN` class, but a set of `toCQL` methods which are monkey-patched into the existing `Net::Z3950::RPN::*` classes defined by the SimpleServer library. The result is that an Z39.50 Type-1 query can be translated using `$node->toCQL($session)`.


