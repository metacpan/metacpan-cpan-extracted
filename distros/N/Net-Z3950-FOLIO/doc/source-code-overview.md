# Overview of the FOLIO Z39.50 server source-code

<!-- md2toc -l 2 source-code-overview.md -->
* [Introduction](#introduction)
* [Command-line program](#command-line-program)
    * [`bin/z2folio`](#binz2folio)
* [Top-level class](#top-level-class)
    * [`lib/Net/Z3950/FOLIO.pm`](#libnetz3950foliopm)
* [Support classes](#support-classes)
    * [`lib/Net/Z3950/FOLIO/Session.pm`](#libnetz3950foliosessionpm)
    * [`lib/Net/Z3950/FOLIO/Config.pm`](#libnetz3950folioconfigpm)
    * [`lib/Net/Z3950/FOLIO/ResultSet.pm`](#libnetz3950folioresultsetpm)
    * [`lib/Net/Z3950/FOLIO/Record.pm`](#libnetz3950foliorecordpm)
* [Support functions](#support-functions)
    * [`lib/Net/Z3950/FOLIO/HoldingsRecords.pm`](#libnetz3950folioholdingsrecordspm)
    * [`lib/Net/Z3950/FOLIO/OPACXMLRecord.pm`](#libnetz3950folioopacxmlrecordpm)
    * [`lib/Net/Z3950/FOLIO/MARCHoldings.pm`](#libnetz3950foliomarcholdingspm)
    * [`lib/Net/Z3950/FOLIO/PostProcess.pm`](#libnetz3950foliopostprocesspm)
    * [`lib/Net/Z3950/FOLIO/RPN.pm`](#libnetz3950foliorpnpm)



## Introduction

The FOLIO Z39.50 server is written in Perl, due to that language's excellent support for the Z39.50 protocol and particularly [the `SimpleServer` module](https://metacpan.org/pod/Net::Z3950::SimpleServer).

The source code consists of four sets of files:

* `bin/z2folio` -- the command-line program that runs the server
* `lib/Net/Z3950/FOLIO.pm` -- the top-level server class that wires into the Z39.50 SimpleServer module
* `lib/Net/Z3950/FOLIO/*.pm` -- support classes used by `FOLIO.pm`
* `lib/Net/Z3950/FOLIO/*.pm` -- support functions used by `FOLIO.pm` and the support classes

We will consider each of these in turn.



## Command-line program


### `bin/z2folio`

This is an extremely simple script of only a dozen lines of code. All it does is gather command-line arguments, create an instance of the server class, and launch it as a server.



## Top-level class


### `lib/Net/Z3950/FOLIO.pm`

The top-level server class. [The public API](from-pod/Net-Z3950-FOLIO.md) consists only of the constructor and the `launch_server` method that are used by `bin/z2folio`. The real work of the constructor is to set up the SimpleServer service and to provide the handlers for the various Z39.50 operations: init, search, fetch, delete and sort.

The SimpleServer API provides two handles which can be initialized by constructors and handler functions, and which are passed back as part of the argument block given to every handler function. These are the global handle, called GHANDLE, and the session handle, just called HANDLE. The former is set in the constructor, and used as a pointer to the `Net::Z3950::FOLIO` server object itself. The latter is set in the search handler (see below), and points to the session object on which the search is invoked.

Conceptually, sessions should be created by the init handler, but in the Z39.50 protocol the name of the database to be searched is not specified until a search is issued, so there is no name by which the session can be known at init-time. Since the database name is also used to determine which set of configuration files to load for the session, this too must be deferred until search time: the response to the Z39.50 init request, then, is fairly vacuous: all it says that the server is ready to receive searches -- but only when the first search comes in can the configuration be loaded.



## Support classes


### `lib/Net/Z3950/FOLIO/Session.pm`

A class representing an ongoing session against a specific back-end. This carries its own configuration, combining global config with tenant-specific config. This compound configuration is compiled when the first search request is received, and the authentication credentials specified therein are then used to authenticate onto the specified back-end.

This class contains the methods that do most of the actual work of talking to the FOLIO back-end service and translating the resulting JSON records into the various record formats. (At present, some of that code remains in `FOLIO.pm`, but it may get moved down in time.)


### `lib/Net/Z3950/FOLIO/Config.pm`

A class representing a compiled configuration, which may be assembled from several overlaid configuration files. Contains the code for compiling the combining the configuration files, and expanding environment variable references within them.

Also contains POD documentation of the configuration-file format.


### `lib/Net/Z3950/FOLIO/ResultSet.pm`

A very simple class used to store the results of searching: the result-set name, the query that was executed, the total count of matching records, and the records themselves so far as they have been loaded.

Has a straightforward API, not documented in detail, consisting of a constructor and five methods: `session()`, `totalCount(int)`, `barcode()`, `insertRecords(offset, records*)`, `record(offset)`.


### `lib/Net/Z3950/FOLIO/Record.pm`

A class representing a record that has been retrieved from FOLIO, which may also have associated with it a MARC record obtained from SRS.

Has a straightforward API, not documented in detail, consisting of a constructor and six methods: `id()`, `jsonStructure()` (returning the instance/holdings/item structure obtained via GraphQL), `prettyJSON()` and `prettyXML()` (formatters for that structure), `holdings(marc)` (see below), and `marcRecord()` (which returns the MARC record, having first fetched it if necessary).




## Support functions


### `lib/Net/Z3950/FOLIO/HoldingsRecords.pm`

Exports a single function, `makeHoldingsRecords(jsonStructure, marc)`, which analyses the instance, holdings and items, together with certain fields from the MARC record, to generate holdings information. This information is returned in an internal format suitable for encoding in Z39.50 OPAC records or as special fields in MARC records.

The code in this package is extensively commented with observations on the meanings of the various OPAC-record fields and how they may be related to fields in the various FOLIO inventory records.

The record method `$record->holdings()` returns the result of running this function; it is used only by the next two source files to be discussed.


### `lib/Net/Z3950/FOLIO/OPACXMLRecord.pm`

Exports a single public function, `makeOPACXMLRecord(record)`. This takes the holdings structure returned from `$record->holdings()` and resolves it to the XML format that the YAZ GFS knows how to transform into a Z39.50 OPAC record.


### `lib/Net/Z3950/FOLIO/MARCHoldings.pm`

Exports a single public function, `insertMARCHoldings(record, marc, cfg, barcode)`. This takes the holdings structure returned from `$record->holdings()` and uses it to generate and insert additional MARC fields that describe this information, in accordance with the `marcHoldings` configuration.


### `lib/Net/Z3950/FOLIO/PostProcess.pm`

Exports a single public function, `postProcessMARCRecord(cfg, marc)`, which post-processes values in the MARC record's fields and subfields in accordance with the `postProcessing` configuration.


### `lib/Net/Z3950/FOLIO/RPN.pm`

Contains a set of `toCQL` methods which are monkey-patched into the existing `Net::Z3950::RPN::*` classes defined by the SimpleServer library. The result is that an Z39.50 Type-1 query can be translated using `$node->toCQL($session)`.


