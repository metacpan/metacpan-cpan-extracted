# Revision history for Perl extension Net::Z3950::FOLIO.

## 4.0.0 (Thu  4 Jul 17:34:07 BST 2024)

* **Breaking change**: uses new-style FOLIO authentication with expiring-and-refreshing tokens instead of old-style authentication, which is deprecated. This version of the Z39.50 server is fine to use with any FOLIO back-end based on release Poppy or later; prior versions (v3.4.0 and earlier) **will no longer work** with FOLIO back-ends based on release Ramsons or later. Fixes ZF-91.

## 3.4.0 (Fri  9 Feb 2024 16:47:17 GMT)

* Make source of availableThru value in OPAC record configurable. Fixes ZF-90.
* Add support for stripping ligatures and modifier letters to stripDiacritics. Fixes ZF-92.
* Include holdings "holdings statement" data in OPAC and OPACXML records. Fixes ZF-84.

## [3.3.5](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.5)(Tue Oct 20 19:52:37 EDT 2023)

* `Dockerfile` specifies versions of Debian and Perl.

## [3.3.4](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.4) (Tue Sep 19 13:37:37 BST 2023)

* Make `Dockerfile` more resilient, due to problems building v3.3.3.

## [3.3.3](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.3) (Tue Sep 19 12:42:27 BST 2023)

* Post-processing is applied to all circulations within an OPAC XML holdings record, not just the first. Fixes ZF-86.
* When substituting into a MARC subfield from other subfields of the same field, use the values from the same instance of that field. Values from other fields and subfields are still included from the first available instance, which is what you expect. Fixes ZF-87.

## [3.3.2](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.2) (Tue Feb 28 11:28:31 GMT 2023)

* Add `1.0` to the list of options for required version of `search` interface, since it's apparently had a major release for some reason. Fixes ZF-85.

## [3.3.1](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.1) (Fri Feb 24 19:26:47 GMT 2023)

* Bump required version of graphql interface to v1.3. Fixes ZF-83.

## [3.3.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.3.0) (Fri Feb 24 18:53:17 GMT 2023)

* MARC-holdings subfield values of "0" are now included in the record, unlike other falsy values. Allows `availableNow=0` and fixes ZF-80.
* Completely new GraphQL query for `mod-search`, including all and only those fields actually needed to make holdings information for OPAC XML records and MARC holdings. Fixes ZF-48.
* Analyze the impact of missing fields in Morning Glory: we do not use `instanceTypeId` or `source`, and by v3.3.0, `holdingsRecords2.temporaryLocation` and `bareHoldingsItems.materialType` are both once more available. Fixes ZF-66.

## [3.2.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.2.0) (Fri Jan 13 19:13:17 GMT 2023)

* Loosen requirements for `search` interface to allow v0.7. Fixes ZF-71.
* Restructure Dockerfile to be more efficient and reliable. Fixes ZF-72.
* New `fieldPerItem` configuration entry allows each item to be placed in its own MARC holdings field rather than each item in a holding sharing the field. Fixes ZF-74.
* Reinstate error-reporting for GraphQL errors (it seems that the way these are reported in the WSAPI response has changed). Fixes ZF-75.
* Switch base image from perl:5 to perl:5-slim. Use signed-by indexdata.asc for apt. Fixes ZF-73.
* Update definitions of access-points 7, 8 and 1211 (ISBN, ISSN and OCLC Number) for mod-search. Fixes ZF-77.
* Remove literal '\n' sequence from between consecutive `<holding>` entries in OPAC XML records. Fixes ZF-78.
* Complete rewrite of `mod-search.graphql-query` so it now requests all and only the fields used to generate information for OPAC XML records and MARC holdings. Fixes ZF-48.

## [3.1.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.1.0) (Sun Nov 27 08:36:08 GMT 2022)

* Generate ModuleDescriptor from template, avoiding the possibility of its version-number getting out of sync with that of `lib/Net/Z3950/FOLIO.pm`. Fixes ZF-64.
* Extend post-processing capabilities to OPACXML records. Fixes ZF-68.
* Use SSL for indexdata.asc to prevent supply-chain MitM attack. Fixes ZF-69.
* Upgrade from perl:5.30 (EOL) to perl:5 (=latest 5). Fixes FZ-70.

## [3.0.1](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.0.1) (Mon 27 Jun 13:26:46 BST 2022)

* _sigh_ Remove spare comma from module-descriptor.

## [3.0.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v3.0.0) (Mon 27 Jun 12:42:48 BST 2022)

* Perform principal search in `mod-search` instead of `mod-inventory-storage`. This became possible in R1-2021 (Iris), when `mod-search` was added, and is mandatory as of R2-2022 (Morning Glory), when the necessary full-text indexes will be removed from `mod-inventory-storage` (see MODINVSTOR-925). Fixes ZF-62. **Note** that the records returned currently omit `instanceTypeId`, `source`, `holdingsRecords2.temporaryLocation` and `bareHoldingsItems.materialType`, as we are getting some records back where those fields are undefined.

## [2.5.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.5.0) (Fri  7 Jan 17:45:05 GMT 2022)

* If `restrictToItem` is set, do not return a MARC holdings field for holdings records with no items. Fixes ZF-55.
* Add support for additional item-level fields (including `_copyNumber`) to be reported in MARC holdings. Fixes ZF-56.
* Allow post-processing substitutions to interpolate field values using sequences of the form `%{245$a}`. Documentation is in the `replacement` section of [the configuration-file manual](doc/from-pod/Net-Z3950-FOLIO-Config.md). Fixes ZF-57.
* New MARC fields/subfields come into existence when named in post-processing rules, unless generated value is empty. Fixes ZF-59.
* OPAC circulation-record `temporaryLocation` now reflects FOLIO "effective location" logic, including item-level permanent location as first fallback if item-level temporary location is absent. Fixes ZF-58.
* In the OPAC record-format (and MARC holdings generated from holdings data), the `availableNow` field in item records is now 0 if the item's `discoverySuppress` field is true. Fixes ZF-60.
* Use a different Index Data-hosted FOLIO instance for test 08.
* Rename `MANIFEST.skip` file to the correctly cased `MANIFEST.SKIP`.

## [2.4.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.4.0) (Tue Aug 24 15:33:57 BST 2021)

* Upgrade `source-storage-source-records` interface dependency to v3.0. (This is what is used in Juniper, so the Z-server would not build against that release.) Fixes ZF-53.

## [2.3.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.3.0) (Mon Jul 19 17:15:33 BST 2021)

* Insert SRS MARC records are into the result set in the right order, corresponding with the appropriate FOLIO inventory record. This ensures that MARC records have the correct holdings associated with them. Fixes ZF-52.

## [2.2.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.2.0) (Fri Jul 16 12:21:00 BST 2021)

* Change default configuration so `queryFilter` omits instances that are suppressed from discovery. Add [documentation on using `queryFilter` to omit discovery-suppressed records](doc/from-pod/Net-Z3950-FOLIO-Config.md#configuring-filters). Fixes ZF-50.

## [2.1.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.1.0) (Thu May  6 16:17:03 BST 2021)

* Add missing virtual fields to the GraphQL query used to fetch instances with their holdings and items: holdings temporary location, and item permanent and temporary locations. When used with a suffiently recent mod-graphql, fixes ZF-43.
* The GraphQL query now specifies to fetch up to 100 holdings records, and up to 100 items per holdings record. Fixes ZF-42.
* The virtual item records in holdings, from which OPAC records and holdings-related MARC fields are generated, now contains not only `temporaryLocation` but also the private field `_permanentLocation`. MARC holdings mappings can refer to this field, and the examples now map it to subfield `L` of the 952 field. An attempt to be all things to all people in ZF-43.
* Updates to release-procedure documentation.

## [2.0.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v2.0.0) (Mon Apr 26 12:19:40 BST 2021)

* Change to three-facet version numbers, which it turns out Perl has supported for a long time. This is necessary (as well as desirable) because CPAN thinks version 1.10 is older than 1.9, which is why there is no version 1.10 there. Fixes ZF-46.
* Update [the release-procedure document](doc/release-procedure.md) to mention FOLIO-standard handling of version-number in [the module descriptor](ModuleDescriptor.json). Fixes ZF-45.
* Increase version number to 2.0.0, so CPAN will recognise this as newer. **NOTE.** No functional changes since v1.10.

## [1.10](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.10) (Fri Apr 23 16:30:29 BST 2021)

* Add and document boolean `nologin` configuration element, which prevents login. This is potentially useful for running against hypothetical unsecured FOLIO instances, but the real reason we need it is for testing.
* Add [new test-suite script](t/07-fetch.t) that exercises the Z39.50 server's Fetch operation to get a higher-level entry into all the underlying mechanisms. Fixes ZF-37.
* MARCXML output now includes the same generated holdings-and-items data as USMARC output. Fixes ZF-38.
* Refactor internals so each Record is responsible for its own MARC, etc. Fixes ZF-39.
* Rename all snake-case methods to consistent camel-case. Fixes ZF-40.
* Fetching a record more than once no longer repeatedly appends multiple sets of holdings/item information. Fixes ZF-36.
* Post-processing is be applied to generated holdings and item fields. Fixes ZF-35.
* Replicate holdings-level permanent location at the item level, whence it can be included in MARC records. Fixes ZF-34.
* Update [source-code overview documentation](doc/source-code-overview.md). Fixes ZF-41.

## [1.9](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.9) (Tue Mar  9 16:51:24 GMT 2021)

* Barcode Search in default connfiguration (use attribute 9998) now uses exact match (`==`) rather than the default string match operator (`=`). Fixes an issue raised in DEVOPS-558.

## [1.8](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.8) (Fri Feb 26 12:12:08 GMT 2021)

* Optionally, restrict item-level MARC holdings info to item mentioned in barcode search. Fixes ZF-32.
* Make `t/07-short-session.t` robust: skip this test if `zoomsh` is not available.

## [1.7](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.7) (Wed Feb 24 18:28:36 GMT 2021)

* The `stripDiacritics` post-processor handles additional special cases. Fixes ZF-31.
* [The sample `Dockerfile`](Dockerfile) now invokes the server with the `-v-session` command-line option. This disables logging of new and ended sessions, which is a practical neccesity when deployed using Kubernetes, AWS ECS or similar setups, as these frequently ping the server to check that it's alive, resulting in log-flooding.
* Clarifications to the documentation.
* We no longer need to use a configuration override for ISBN searching in the Chicago service. Completes ZF-24.
* Towards providing MARC holdings data. Part of ZF-30.

## [1.6](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.6) (Tue Jan 26 15:34:56 GMT 2021)

* Element-set names are treated case-insensitively, meaning that (among other things) "F" and "B" are recognized as well as "f" and "b". Fixes ZF-29.

## [1.5](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.5) (Mon Nov 30 15:07:08 GMT 2020)

* Bring version-number in [`ModuleDescriptor.json`](ModuleDescriptor.json) up to date. I forgot to do this in v1.4, with the result that it wouldn't build in Jenkins.
* Add a Jenkins build to [the release-procedure instructions](doc/release-procedure.md).

## [1.4](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.4) (Fri Nov 27 00:49:05 GMT 2020)

* Add support for searching by local barcode. Fixes ZF-23.
* Add developer documentation with [an overview of the source code](doc/source-code-overview.md). Fixes ZF-28.
* Use Z39.50 database name to indicate FOLIO tenant. Fixes ZF-2.
* Implement, test and document stacking configurations: base, tenant, filters. Fixes ZF-27.
* OPAC record now includes `availableThru` field, construed as the material-type of the item (provided that `mod-graphql` is running against a sufficiently new version of the mod-inventory-storage JSON schemas). Fixes ZF-26.
* `z2folio` writes to both standard output and standard error in UTF-8 mode. Yes, like you, I assumed this would be the default behaviour in 2020, but apparently Perl never got the memo.
* Support post-processing rules for MARC fields: diacritic removal and regular-expression substitution. Tests and documentation. Should give us all the flexibiliy we need for ZF-25.
* Support Chicago's currently non-standard ISBN searching. Fixes ZF-24.

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

* Automatic generation of MARC records (ZF-14). Thi will need a non-trivial version of `etc/folio2marcxml.xsl` (ZF-8).

