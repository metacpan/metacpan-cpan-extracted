# Revision history for Perl extension Net::Z3950::FOLIO.

## [1.3](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.3) (Thu Sep 24 20:16:12 BST 2020)

* Make robust when dealing with MARC fields that have no subfields.
* Add dependency on `source-storage-source-records` interface.
* When substituting environment variables in the configuration file, recognise the bash-like fallback syntax `${NAME-VALUE}`, which uses the value of the environment variable `NAME` when defined, falling back to the constant value `VALUE` otherwise. This allows the configuration to include default values which can be overridden with environment variables.
* Use `default` configured index when no Z39.50 access-point is specified for a search.
* Support Z39.50 sorting. Fixes ZF-1.
* Make the set of available record-syntaxes and element-sets more coherent.
* Add configuration option to omit specified sort-index modifiers for specific access points. We should not need this, but in practice we will until CQLPG-102 is fixed.
* Provide [documentation of server capabilities](doc/capabilities.md). Fixes ZF-17.
* Modify how FOLIO location data is mapped to OPAC-record fields. Fixes ZF-19.
* The `itemId` field in the OPAC record now contains the item barcode instead of HRID. Fixes ZF-21.
* Support and document `relation` specification in index-map specification, allowing the use of `==` for HRID searches. Fixes ZF-20.

## [1.2](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.2) (Fri Sep 18 10:15:11 BST 2020)

* Fix a couple of archaic formations that recent Perls complain about: unescaped `{` in regular expressions, passing a scalar reference to `keys`. These were causing test failures on some platforms.

## [1.1](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.1) (Thu Sep 17 19:46:10 2020 +0100)

* Attempt to mark classes in the `Net::Z3950::RPN` namespace as non-indexed, so PAUSE doesn't trip up on them when trying to index the module and seeing that classes of the same name are defined the SimplerServer distribution. Note that this have **no functional effect** on the behaviour of the code: it is only matter of getting the release to appear on CPAN.

## [1.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.0) (Thu Sep 17 16:25:51 BST 2020)

* First released version. Includes:
  * ZF-3 (Support returning OPAC records)
  * ZF-4 (Support returning MARC records)
  * ZF-5 (Get MARC records directly from linked storage (SRS))
  * ZF-6 (Get the basic server working)
  * ZF-7 (Improve query-mapping)
  * ZF-12 (Generate OPAC record from holdings/items according to mapping)
  * ZF-15 (Dockerize the Z39.50 server)
  * ZF-16 (Make release v1.0)

## 0.01 (Thu Dec  6 13:03:26 2018)
* Original version; created by `h2xs -X --name=Net::Z3950::FOLIO --compat-version=5.8.0 --omit-constant --skip-exporter --skip-ppport`

## To do

* Determine FOLIO tenant from database name, and postpone initialisation and authentication until we know that (ZF-2).
* Automatic generation of MARC records (ZF-14). Thi will need a non-trivial version of `etc/folio2marcxml.xsl` (ZF-8).

