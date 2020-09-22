# Revision history for Perl extension Net::Z3950::FOLIO.

## [1.2](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.2) (Fri Sep 18 10:15:11 BST 2020)

* Fix a couple of archaic formations that recent Perls complain about: unescaped `{` in regular expressions, passing a scalar reference to `keys`. These were causing test failures on some platforms.

## [1.1](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.1) (Thu Sep 17 19:46:10 2020 +0100)

* Attempt to mark classes in the `Net::Z3950::RPN` namespace as non-indexed, so PAUSE doesn't trip up on them when trying to index the module and seeing that classes of the same name are defined the SimplerServer distribution. Note that this have **no functional effect** on the behaviour of the code: it is only matter of getting the release to appear on CPAN.

## [1.0](https://github.com/folio-org/Net-Z3950-FOLIO/tree/v1.0) (Thu Sep 17 16:25:51 BST 2020)

* First released version.

## 0.01 (Thu Dec  6 13:03:26 2018)
* Original version; created by `h2xs -X --name=Net::Z3950::FOLIO --compat-version=5.8.0 --omit-constant --skip-exporter --skip-ppport`

## To do

* Determine FOLIO tenant from database name (and postpone initialisation and authentication until we know that).
* automatic generation of MARC records (will need a non-trivial version of `etc/folio2marcxml.xsl`).

